#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <time.h>
#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <DHT11.h>

const char* WIFI_SSID     = "PLDTHOMEFIBRrMQ32";
const char* WIFI_PASSWORD = "EDMA4ever2k@";

const char* PROJECT_ID = "pollutracker-bf276";
const char* TRACKER_ID = "tracker_002";

const char* NTP_SERVER      = "pool.ntp.org";
const long  GMT_OFFSET_SEC  = 28800;
const int   DAYLIGHT_OFFSET = 0;

HardwareSerial pmsSerial(1); // RX=16, TX=17

DHT11 dht11(4);

// ---------------- ADS1115 (replaces Arduino Uno) ----------------
// Wiring: ADS1115 SDA -> ESP32 GPIO21, SCL -> GPIO22 (default I2C pins)
//   A0 -> MQ2 analog out
//   A1 -> MQ9 analog out
//   A2 -> MQ135 analog out
//   A3 -> MQ131 analog out
Adafruit_ADS1115 ads;
const uint8_t ADS_ADDR = 0x48; // default address (ADDR pin to GND)

// GAIN_TWOTHIRDS -> +/-6.144V range, safe headroom for 5V MQ sensor outputs
const adsGain_t ADS_GAIN = GAIN_TWOTHIRDS;

// How often to sample sensors and push to Firebase (ms)
const unsigned long SEND_INTERVAL_MS = 5000;
unsigned long lastSendMillis = 0;

struct PMS5003Data {
  int  pm1_0 = -1;
  int  pm2_5 = -1;
  int  pm10  = -1;
  bool valid = false;
};

PMS5003Data pmsData;

bool readPMS5003(PMS5003Data &data) {
  while (pmsSerial.available() >= 32) {

    if (pmsSerial.peek() == 0x42) {
      pmsSerial.read();

      if (pmsSerial.peek() == 0x4D) {
        pmsSerial.read();

        byte buf[30];
        for (int i = 0; i < 30; i++) {
          buf[i] = pmsSerial.read();
        }

        int checksum = 0x42 + 0x4D;
        for (int i = 0; i < 28; i++) {
          checksum += buf[i];
        }

        int receivedChecksum = (buf[28] << 8) | buf[29];

        if (checksum == receivedChecksum) {
          data.pm1_0 = (buf[4] << 8) | buf[5];
          data.pm2_5 = (buf[6] << 8) | buf[7];
          data.pm10  = (buf[8] << 8) | buf[9];
          data.valid = true;
          return true;
        }
      }
    }

    pmsSerial.read();
  }

  return false;
}

String getTimestamp() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "unavailable";
  char buf[30];
  strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%S+08:00", &timeinfo);
  return String(buf);
}

String getDateOnly() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "unavailable";
  char buf[12];
  strftime(buf, sizeof(buf), "%Y-%m-%d", &timeinfo);
  return String(buf);
}

String getTimeOnly() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "unavailable";
  char buf[10];
  strftime(buf, sizeof(buf), "%H:%M:%S", &timeinfo);
  return String(buf);
}

void connectWiFi() {
  Serial.print("Connecting to WiFi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected!");
  Serial.println(WiFi.localIP());
}

void syncTime() {
  Serial.print("Syncing time with NTP...");
  configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET, NTP_SERVER);

  struct tm timeinfo;
  int retries = 0;

  while (!getLocalTime(&timeinfo) && retries < 10) {
    delay(1000);
    Serial.print(".");
    retries++;
  }

  if (retries < 10) {
    Serial.println("\nTime synced: " + getTimestamp());
  } else {
    Serial.println("\nNTP sync failed.");
  }
}

void sendToFirebase(int mq2,   float mq2_v,
                    int mq9,   float mq9_v,
                    int mq135, float mq135_v,
                    int mq131, float mq131_v,
                    int temp,  int hum,
                    int pm1_0, int pm2_5, int pm10) {

  HTTPClient http;
  String url = "https://firestore.googleapis.com/v1/projects/" + String(PROJECT_ID) +
               "/databases/(default)/documents/devices/" + String(TRACKER_ID) +
               "/readings/";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<896> doc;
  JsonObject fields = doc.createNestedObject("fields");

  fields["timestamp"]["stringValue"] = getTimestamp();
  fields["date"]["stringValue"]      = getDateOnly();
  fields["time"]["stringValue"]      = getTimeOnly();

  fields["mq2"]["integerValue"]    = String(mq2);
  fields["mq2_v"]["doubleValue"]   = mq2_v;
  fields["mq9"]["integerValue"]    = String(mq9);
  fields["mq9_v"]["doubleValue"]   = mq9_v;
  fields["mq135"]["integerValue"]  = String(mq135);
  fields["mq135_v"]["doubleValue"] = mq135_v;
  fields["mq131"]["integerValue"]  = String(mq131);
  fields["mq131_v"]["doubleValue"] = mq131_v;

  fields["temperature"]["integerValue"] = String(temp);
  fields["humidity"]["integerValue"]    = String(hum);

  if (pmsData.valid) {
    fields["pm1_0"]["integerValue"] = String(pm1_0);
    fields["pm2_5"]["integerValue"] = String(pm2_5);
    fields["pm10"]["integerValue"]  = String(pm10);
  } else {
    fields["pm1_0"]["nullValue"] = nullptr;
    fields["pm2_5"]["nullValue"] = nullptr;
    fields["pm10"]["nullValue"]  = nullptr;
  }

  String body;
  serializeJson(doc, body);

  Serial.println("\nSending to Firebase...");
  Serial.println(body);

  int httpCode = http.POST(body);
  Serial.print("HTTP Code: ");
  Serial.println(httpCode);

  if (httpCode > 0) {
    Serial.println("Response: " + http.getString());
  } else {
    Serial.println("Error sending data.");
  }

  http.end();
}

void setup() {
  Serial.begin(115200);

  pmsSerial.begin(9600, SERIAL_8N1, 16, 17);

  // ---- ADS1115 init (replaces unoSerial.begin) ----
  Wire.begin(); // default ESP32 I2C pins: SDA=21, SCL=22
  if (!ads.begin(ADS_ADDR)) {
    Serial.println("Failed to initialize ADS1115. Check wiring/address.");
  }
  ads.setGain(ADS_GAIN);

  connectWiFi();
  syncTime();

  Serial.println("Warming up PMS5003...");
  delay(30000);
}

void loop() {
  if (readPMS5003(pmsData)) {
    Serial.print("PM1: ");
    Serial.println(pmsData.pm1_0);
  }

  if (readPMS5003(pmsData)) {
    Serial.print("PM2.5: ");
    Serial.println(pmsData.pm2_5);
  }

  if (readPMS5003(pmsData)) {
    Serial.print("PM10: ");
    Serial.println(pmsData.pm10);
  }

  // ---- Replaces the unoSerial.available() block ----
  // Instead of waiting on a CSV line from the Uno, sample the ADS1115 +
  // DHT sensor directly on a timer.
  unsigned long now = millis();
  if (now - lastSendMillis >= SEND_INTERVAL_MS) {
    lastSendMillis = now;

    int16_t raw_mq2   = ads.readADC_SingleEnded(0);
    int16_t raw_mq9   = ads.readADC_SingleEnded(1);
    int16_t raw_mq135 = ads.readADC_SingleEnded(2);
    int16_t raw_mq131 = ads.readADC_SingleEnded(3);

    float mq2_v   = ads.computeVolts(raw_mq2);
    float mq9_v   = ads.computeVolts(raw_mq9);
    float mq135_v = ads.computeVolts(raw_mq135);
    float mq131_v = ads.computeVolts(raw_mq131);

    int temp = 0;
    int hum  = 0;
    int dhtResult = dht11.readTemperatureHumidity(temp, hum);

    if (dhtResult != 0) {
      Serial.print("Failed to read from DHT11: ");
      Serial.println(DHT11::getErrorString(dhtResult));
      return;
    }

    Serial.println("Timestamp: " + getTimestamp());

    if (pmsData.valid) {
      Serial.println("PMS5003 VALID");
    } else {
      Serial.println("PMS5003 NOT READY");
    }

    sendToFirebase(raw_mq2,   mq2_v,
                   raw_mq9,   mq9_v,
                   raw_mq135, mq135_v,
                   raw_mq131, mq131_v,
                   temp, hum,
                   pmsData.pm1_0,
                   pmsData.pm2_5,
                   pmsData.pm10);
  }
}
