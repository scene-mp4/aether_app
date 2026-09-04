/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


// functions/index.js
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp }     = require("firebase-admin/app");
const { getFirestore }      = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// ═══════════════════════════════════════════════════════════════════════════════
// CALIBRATION CONSTANTS
// Update these whenever you recalibrate your sensors.
// These values came from your debug console readings.
// ═══════════════════════════════════════════════════════════════════════════════
const CALIBRATION = {
  // FIX: Vc must match the actual supply voltage to your MQ sensors.
  // If MQ sensors are powered from ESP32 3.3V pin → set 3.3
  // If MQ sensors are powered from a separate 5V supply → set 5.0
  Vc: 3.3,

  // These Ro values need to be recalibrated after fixing Vc
  // Run the sensor for 24-48h then check Serial Monitor for suggested Ro values
  Ro_MQ2:   8.5,
  Ro_MQ9:   7.3,
  Ro_MQ135: 78.9,

  RL_MQ2:   5.0,
  RL_MQ9:   5.0,
  RL_MQ135: 10.0,
};

// Set to 1.5 if using a 10kΩ/20kΩ voltage divider between MQ AOUT and ADS1115.
// Set to 1.0 if MQ sensors are powered directly from 3.3V with no divider.
const DIVIDER_FACTOR = 1.0;

// ═══════════════════════════════════════════════════════════════════════════════
// SENSOR MATH HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

function getRsRatio(vout, rl, ro) {
  const v = vout * DIVIDER_FACTOR;
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
  const cf = -0.00035 * t * t
             + 0.0177  * t
             - 0.0000179 * h * h
             + 0.00699 * h
             - 0.1689;
  return Math.min(Math.max(cf, 0.1), 10.0);
}

function getAbsoluteHumidity(temp, hum) {
  const es = 6.112 * Math.exp((17.67 * temp) / (temp + 243.5));
  return (es * hum * 2.1674) / (273.15 + temp);
}

function getHeatIndex(t, rh) {
  if (t < 27 || rh < 40) return t;
  return -8.78469475556
    + 1.61139411      * t
    + 2.33854883889   * rh
    - 0.14611605      * t  * rh
    - 0.012308094     * t  * t
    - 0.0164248277778 * rh * rh
    + 0.002211732     * t  * t  * rh
    + 0.00072546      * t  * rh * rh
    - 0.000003582     * t  * t  * rh * rh;
}

// ═══════════════════════════════════════════════════════════════════════════════
// AQI HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

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
    if (pm25 >= cLo && pm25 <= cHi) {
      return Math.round(((iHi - iLo) / (cHi - cLo)) * (pm25 - cLo) + iLo);
    }
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

// ═══════════════════════════════════════════════════════════════════════════════
// FIRESTORE TRIGGER
//
// Listens for new documents under:
//   devices/{deviceId}/readings/{readingId}
//
// Writes computed metrics to a SEPARATE subcollection using the SAME document
// ID so raw and computed documents are always matched by ID:
//   devices/{deviceId}/readings_computed/{readingId}
//
// Also updates the top-level device document with the latest summary so the
// dashboard can read one document instead of querying the full subcollection.
// ═══════════════════════════════════════════════════════════════════════════════

exports.computeSensorMetrics = onDocumentCreated(
  "devices/{deviceId}/readings/{readingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const raw       = snap.data();
    const deviceId  = event.params.deviceId;
    const readingId = event.params.readingId;

    // ── Extract raw values from the ESP32 document ──────────────────────────
    const mq2_v   = raw.mq2_v   ?? 0;
    const mq9_v   = raw.mq9_v   ?? 0;
    const mq135_v = raw.mq135_v ?? 0;
    const mq131_v = raw.mq131_v ?? 0;

    const temp = raw.temperature ?? 25;
    const hum  = raw.humidity    ?? 60;
    const pm25 = raw.pm2_5  ?? 0;
    const pm10 = raw.pm10   ?? 0;
    const pm1  = raw.pm1_0  ?? 0;

    // ── Rs/Ro ratios ────────────────────────────────────────────────────────
    const ratio_mq2   = getRsRatio(mq2_v,   CALIBRATION.RL_MQ2,   CALIBRATION.Ro_MQ2);
    const ratio_mq9   = getRsRatio(mq9_v,   CALIBRATION.RL_MQ9,   CALIBRATION.Ro_MQ9);
    const ratio_mq135 = getRsRatio(mq135_v, CALIBRATION.RL_MQ135, CALIBRATION.Ro_MQ135);

    // ── MQ-2: LPG and Smoke ─────────────────────────────────────────────────
    const lpg_ppm   = getPPM(ratio_mq2, 574.25, -2.222);
    const smoke_ppm = getPPM(ratio_mq2, 3616.1, -2.675);

    // ── MQ-9: Carbon Monoxide ───────────────────────────────────────────────
    const co_ppm    = getPPM(ratio_mq9, 1000.5, -1.969);

    // ── MQ-135: CO₂ and NH₃ with temp/humidity correction ──────────────────
    const cf      = getCorrectionFactor(temp, hum);
    const rawCo2  = getPPM(ratio_mq135, 110.47, -2.862) * cf;
    const co2_ppm = rawCo2 < 420 ? 420.0 : rawCo2; // floor at outdoor baseline
    const nh3_ppm = getPPM(ratio_mq135, 102.2, -2.473);

    // ── MQ-131: Ozone ───────────────────────────────────────────────────────
    // Ro_MQ131 ≈ 15kΩ typical in clean air, RL = 10kΩ typical on module
    // Update Ro_MQ131 in CALIBRATION block above once you measure yours
    const ratio_mq131 = getRsRatio(mq131_v, 10.0, 15.0);
    const o3_ppm      = getPPM(ratio_mq131, 23.943, -1.1);

    // ── Climate metrics ─────────────────────────────────────────────────────
    const abs_humidity = getAbsoluteHumidity(temp, hum);
    const heat_index   = getHeatIndex(temp, hum);

    // ── AQI ─────────────────────────────────────────────────────────────────
    const pm25_aqi   = calculatePM25AQI(pm25);
    const iaqi       = calculateCompositeIAQI(co_ppm, co2_ppm, nh3_ppm, pm25_aqi);
    const iaqi_label = getAQILabel(iaqi);

    // ── Alert flags ──────────────────────────────────────────────────────────
    const co_alert   = co_ppm  > 35;
    const lpg_alert  = lpg_ppm > 200;
    const pm25_alert = pm25_aqi > 100;
    const co2_alert  = co2_ppm > 1500;

    // ── Assemble the computed document ───────────────────────────────────────
    // Includes a reference back to the raw document ID so they can always
    // be joined if needed, plus the original timestamp for time-series queries.
    const computedDoc = {
      // Reference to matching raw document
      raw_reading_id: readingId,
      device_id:      deviceId,

      // Copy timestamp and location from raw so this collection is
      // independently queryable without joining back to readings/
      timestamp:     raw.timestamp ?? new Date().toISOString(),
      date:          raw.date      ?? "",
      time:          raw.time      ?? "",
      location:      raw.location  ?? "",

      // ── Gas concentrations (ppm) ─────────────────────────────────────────
      lpg_ppm:   parseFloat(lpg_ppm.toFixed(2)),
      smoke_ppm: parseFloat(smoke_ppm.toFixed(2)),
      co_ppm:    parseFloat(co_ppm.toFixed(2)),
      co2_ppm:   parseFloat(co2_ppm.toFixed(1)),
      nh3_ppm:   parseFloat(nh3_ppm.toFixed(2)),
      o3_ppm:    parseFloat(o3_ppm.toFixed(3)),

      // ── Particulate matter (µg/m³, direct from PMS5003) ──────────────────
      pm1_ugm3:  pm1,
      pm25_ugm3: pm25,
      pm10_ugm3: pm10,

      // ── Climate ──────────────────────────────────────────────────────────
      temperature_c:     temp,
      humidity_pct:      hum,
      abs_humidity_gm3:  parseFloat(abs_humidity.toFixed(3)),
      heat_index_c:      parseFloat(heat_index.toFixed(1)),

      // ── AQI ──────────────────────────────────────────────────────────────
      pm25_aqi,
      iaqi,
      iaqi_label,

      // ── Alert flags ───────────────────────────────────────────────────────
      co_alert,
      lpg_alert,
      pm25_alert,
      co2_alert,

      // ── Function metadata ─────────────────────────────────────────────────
      computed_at: new Date().toISOString(),
    };

    // ── Write to readings_computed using the SAME document ID ────────────────
    // Same ID means: readings/{readingId} ↔ readings_computed/{readingId}
    await db
      .collection("devices")
      .doc(deviceId)
      .collection("readings_computed")
      .doc(readingId)          // same ID as the raw document
      .set(computedDoc);

    // ── Update top-level device summary ──────────────────────────────────────
    // Dashboard and summary tab read from devices/{deviceId}.latest
    // instead of querying the full subcollection every time.
    await db
      .collection("devices")
      .doc(deviceId)
      .set({ latest: computedDoc }, { merge: true });

    console.log(
      `[${deviceId}] computed → readings_computed/${readingId} | ` +
      `CO=${co_ppm.toFixed(1)}ppm CO2=${co2_ppm.toFixed(0)}ppm ` +
      `PM2.5=${pm25}µg/m³ IAQI=${iaqi}(${iaqi_label})`
    );

    // Temporary — add inside computeSensorMetrics, after computing ratios
    // This logs the Ro that would make ratio = 1.0 in current conditions
    // Run for 30+ minutes in clean outdoor air, then average the logged values
    console.log(`[Ro calibration] MQ2 Rs=${(getRsRatio(mq2_v, CALIBRATION.RL_MQ2, 1.0) * 1.0).toFixed(3)}`);
    console.log(`[Ro calibration] MQ9 Rs=${(getRsRatio(mq9_v, CALIBRATION.RL_MQ9, 1.0) * 1.0).toFixed(3)}`);
    console.log(`[Ro calibration] MQ135 Rs=${(getRsRatio(mq135_v, CALIBRATION.RL_MQ135, 1.0) * 1.0).toFixed(3)}`);

    // Notification Handler
    const { getMessaging } = require('firebase-admin/messaging');

    // After computing alerts, send FCM if critical condition detected
    async function sendAlertIfNeeded(deviceId, deviceName, computed) {
      // Only send for serious conditions
      if (!computed.co_alert && computed.iaqi < 150) return;

      // Find all users who own this tracker
      const devDoc = await db.collection('devices').doc(deviceId).get();
      const ownerId = devDoc.data()?.owner_id;
      if (!ownerId) return;

      // Get their FCM tokens
      const userDoc = await db.collection('users').doc(ownerId).get();
      const tokens  = userDoc.data()?.fcm_tokens ?? [];
      if (tokens.length === 0) return;

      // Build the notification
      let title = '⚠️ Air Quality Alert';
      let body  = `${deviceName}: IAQI ${computed.iaqi} — ${computed.iaqi_label}`;

      if (computed.co_alert) {
        title = '🚨 CO Emergency Alert';
        body  = `${deviceName}: CO at ${computed.co_ppm.toFixed(1)} ppm — ventilate immediately`;
      } else if (computed.pm25_alert) {
        title = '⚠️ PM2.5 Alert';
        body  = `${deviceName}: PM2.5 AQI ${computed.pm25_aqi} — air quality unhealthy`;
      }

      // Send to all registered devices for this user
      await getMessaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        android: {
          priority: computed.co_alert ? 'high' : 'normal',
          notification: { channelId: 'aether_alerts' },
        },
        apns: {
          payload: {
            aps: {
              sound:             'default',
              'content-available': 1,
            },
          },
        },
      });

      console.log(`[FCM] Alert sent to ${tokens.length} device(s) for ${deviceId}`);
    }

        const cooldownRef = db.collection('devices').doc(deviceId);
    const lastAlert   = devDoc.data()?.last_alert_sent?.toDate();
    const now         = new Date();
    const thirtyMins  = 30 * 60 * 1000;

    if (lastAlert && (now - lastAlert) < thirtyMins) {
      console.log(`[FCM] Cooldown active for ${deviceId} — skipping notification`);
      return;
    }

    await cooldownRef.update({ last_alert_sent: new Date() });
    
    // Call it at the end of computeSensorMetrics, after the Firestore writes:
    await sendAlertIfNeeded(deviceId, data?.device_name ?? deviceId, computedDoc);
  },
);