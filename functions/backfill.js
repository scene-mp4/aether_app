// backfill.js
// Run with: node backfill.js
// Requires: npm install firebase-admin

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ── Paste your CALIBRATION constants here ─────────────────────────────────────
const CALIBRATION = {
  Vc:       3.3,   // FIX: set to your actual sensor supply voltage
  Ro_MQ2:   8.5,
  Ro_MQ9:   7.3,
  Ro_MQ135: 78.9,
  RL_MQ2:   5.0,
  RL_MQ9:   5.0,
  RL_MQ135: 10.0,
};

// ── Paste the same helper functions from your index.js here ───────────────────
function getRsRatio(vout, rl, ro) {
  const v = vout;
  if (v <= 0 || v >= CALIBRATION.Vc) return 100.0;
  const rs = ((CALIBRATION.Vc - v) / v) * rl;
  return rs / ro;
}

function getPPM(ratio, a, b) {
  if (!isFinite(ratio) || ratio <= 0) return 0.0;
  const safeRatio = Math.min(Math.max(ratio, 0.01), 100.0);
  const val = a * Math.pow(safeRatio, b);
  if (!isFinite(val)) return 0.0;
  return Math.min(Math.max(val, 0.0), 10000.0);
}

function getCorrectionFactor(t, h) {
  const cf = -0.00035 * t * t + 0.0177 * t
           - 0.0000179 * h * h + 0.00699 * h - 0.1689;
  return Math.min(Math.max(cf, 0.1), 10.0);
}

function calculatePM25AQI(pm25) {
  if (pm25 <= 0) return 0;
  const bp = [
    [0.0,   12.0,    0,  50],
    [12.1,  35.4,   51, 100],
    [35.5,  55.4,  101, 150],
    [55.5, 150.4,  151, 200],
    [150.5, 250.4, 201, 300],
    [250.5, 350.4, 301, 400],
    [350.5, 500.4, 401, 500],
  ];
  for (const [cLo, cHi, iLo, iHi] of bp) {
    if (pm25 >= cLo && pm25 <= cHi)
      return Math.round(((iHi - iLo) / (cHi - cLo)) * (pm25 - cLo) + iLo);
  }
  return 500;
}

function getAQILabel(aqi) {
  if (aqi <= 50)  return "Good";
  if (aqi <= 100) return "Moderate";
  if (aqi <= 150) return "Unhealthy for Sensitive Groups";
  if (aqi <= 200) return "Unhealthy";
  if (aqi <= 300) return "Very Unhealthy";
  return "Hazardous";
}

function calculateCompositeIAQI(co, co2, nh3, pmAqi) {
  const iCo  = Math.min((co  / 200)  * 500, 500);
  const iCo2 = Math.min((co2 / 5000) * 500, 500);
  const iNh3 = Math.min((nh3 / 300)  * 500, 500);
  return Math.round(Math.max(iCo, iCo2, iNh3, pmAqi));
}

// ── Main backfill function ────────────────────────────────────────────────────
async function backfill() {
  // Get all tracker device IDs
  const devicesSnap = await db.collection('devices').get();
  const deviceIds   = devicesSnap.docs.map(d => d.id);

  console.log(`Found ${deviceIds.length} device(s): ${deviceIds.join(', ')}`);

  let totalProcessed = 0;
  let totalFailed    = 0;

  for (const deviceId of deviceIds) {
    console.log(`\nProcessing device: ${deviceId}`);

    const readingsSnap = await db
      .collection('devices')
      .doc(deviceId)
      .collection('readings')
      .orderBy('timestamp')
      .get();

    console.log(`  Found ${readingsSnap.docs.length} raw readings`);

    for (const rawDoc of readingsSnap.docs) {
      const readingId = rawDoc.id;
      const raw       = rawDoc.data();

      try {
        const mq2_v   = raw.mq2_v   ?? 0;
        const mq9_v   = raw.mq9_v   ?? 0;
        const mq135_v = raw.mq135_v ?? 0;
        const mq131_v = raw.mq131_v ?? 0;
        const temp    = raw.temperature ?? 25;
        const hum     = raw.humidity    ?? 60;
        const pm25    = raw.pm2_5  ?? 0;
        const pm10    = raw.pm10   ?? 0;
        const pm1     = raw.pm1_0  ?? 0;

        const ratio_mq2   = getRsRatio(mq2_v,   CALIBRATION.RL_MQ2,   CALIBRATION.Ro_MQ2);
        const ratio_mq9   = getRsRatio(mq9_v,   CALIBRATION.RL_MQ9,   CALIBRATION.Ro_MQ9);
        const ratio_mq135 = getRsRatio(mq135_v, CALIBRATION.RL_MQ135, CALIBRATION.Ro_MQ135);

        const lpg_ppm   = getPPM(ratio_mq2, 574.25, -2.222);
        const smoke_ppm = getPPM(ratio_mq2, 3616.1, -2.675);
        const co_ppm    = getPPM(ratio_mq9, 1000.5, -1.969);

        const cf      = getCorrectionFactor(temp, hum);
        const rawCo2  = getPPM(ratio_mq135, 110.47, -2.862) * cf;
        const co2_ppm = rawCo2 < 420 ? 420.0 : rawCo2;
        const nh3_ppm = getPPM(ratio_mq135, 102.2, -2.473);

        const pm25_aqi   = calculatePM25AQI(pm25);
        const iaqi       = calculateCompositeIAQI(co_ppm, co2_ppm, nh3_ppm, pm25_aqi);
        const iaqi_label = getAQILabel(iaqi);

        const co_alert   = co_ppm  > 35;
        const lpg_alert  = lpg_ppm > 200;
        const pm25_alert = pm25_aqi > 100;
        const co2_alert  = co2_ppm > 1500;

        const computedDoc = {
          raw_reading_id: readingId,
          device_id:      deviceId,
          timestamp:      raw.timestamp ?? '',
          date:           raw.date      ?? '',
          time:           raw.time      ?? '',
          location:       raw.location  ?? '',

          lpg_ppm:   parseFloat(lpg_ppm.toFixed(2)),
          smoke_ppm: parseFloat(smoke_ppm.toFixed(2)),
          co_ppm:    parseFloat(co_ppm.toFixed(2)),
          co2_ppm:   parseFloat(co2_ppm.toFixed(1)),
          nh3_ppm:   parseFloat(nh3_ppm.toFixed(2)),

          pm1_ugm3:  pm1,
          pm25_ugm3: pm25,
          pm10_ugm3: pm10,

          temperature_c:     temp,
          humidity_pct:      hum,

          pm25_aqi,
          iaqi,
          iaqi_label,

          co_alert,
          lpg_alert,
          pm25_alert,
          co2_alert,

          computed_at: new Date().toISOString(),
          backfilled:  true,  // flag so you know which docs were backfilled
        };

        // Overwrite the existing readings_computed document with corrected values
        await db
          .collection('devices')
          .doc(deviceId)
          .collection('readings_computed')
          .doc(readingId)
          .set(computedDoc);

        totalProcessed++;
        if (totalProcessed % 50 === 0) {
          console.log(`  Processed ${totalProcessed} readings so far...`);
        }

      } catch (err) {
        console.error(`  ERROR on ${readingId}: ${err.message}`);
        totalFailed++;
      }
    }

    console.log(`  Done with ${deviceId}`);
  }

  console.log(`\nBackfill complete.`);
  console.log(`  Processed: ${totalProcessed}`);
  console.log(`  Failed:    ${totalFailed}`);
  process.exit(0);
}

backfill().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});