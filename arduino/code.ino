#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <time.h>
#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <DHT11.h>

HardwareSerial pmsSerial(1);

DHT11 dht11(4);

Adafruit_ADS1115 ads;
const uint8_t ADS_ADDR = 0x48;
const adsGain_t ADS_GAIN = GAIN_TWOTHIRDS;

const char* WIFI_SSID     = "";
const char* WIFI_PASSWORD = "";

const char* PROJECT_ID = "pollutracker-bf276";
const char* TRACKER_ID = "tracker_002";

const char* NTP_SERVER      = "pool.ntp.org";
const long  GMT_OFFSET_SEC  = 28800;
const int   DAYLIGHT_OFFSET = 0;

const unsigned long SEND_INTERVAL_MS = 5000;
unsigned long lastSendMillis = 0;

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

const int PMS_PM1_0 = 0;
const int PMS_PM2_5 = 1;
const int PMS_PM10  = 2;

int  pmsValues[3] = { -1, -1, -1 };
bool pmsValid     = false;

bool readPMS5003(int values[], bool &valid) {
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
          values[PMS_PM1_0] = (buf[4] << 8) | buf[5];
          values[PMS_PM2_5] = (buf[6] << 8) | buf[7];
          values[PMS_PM10]  = (buf[8] << 8) | buf[9];
          valid = true;
          return true;
        }
      }
    }
    pmsSerial.read();
  }
  return false;
}

void sendToFirebase(int mqRaw[], float mqVolt[],
                    int dhtValues[],
                    int pmsVals[], bool pmsOk) {

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

  // MQ sensors — index 0..3 maps to MQ2, MQ9, MQ135, MQ131
  const char* mqRawKeys[]   = { "mq2",   "mq9",   "mq135",   "mq131"   };
  const char* mqVoltKeys[]  = { "mq2_v", "mq9_v", "mq135_v", "mq131_v" };
  for (int i = 0; i < 4; i++) {
    fields[mqRawKeys[i]]["integerValue"]  = String(mqRaw[i]);
    fields[mqVoltKeys[i]]["doubleValue"]  = mqVolt[i];
  }

  fields["temperature"]["integerValue"] = String(dhtValues[0]);
  fields["humidity"]["integerValue"]    = String(dhtValues[1]);

  const char* pmsKeys[] = { "pm1_0", "pm2_5", "pm10" };
  for (int i = 0; i < 3; i++) {
    if (pmsOk) {
      fields[pmsKeys[i]]["integerValue"] = String(pmsVals[i]);
    } else {
      fields[pmsKeys[i]]["nullValue"] = nullptr;
    }
  }

  String body;
  serializeJson(doc, body);

  Serial.println("\nSending to Firebase.");
  Serial.println(body);

  int httpCode = http.POST(body);
  Serial.print("HTTP Code: ");
  Serial.println(httpCode);

  if (httpCode > 0) {
    Serial.println("Response: " + http.getString());
  } else {
    Serial.println("No Data Sent");
  }

  http.end();
}

void setup() {
  Serial.begin(115200);
  pmsSerial.begin(9600, SERIAL_8N1, 16, 17);
  Serial.println("Preparing PMS5003...");
  delay(30000);

  Wire.begin();
  if (!ads.begin(ADS_ADDR)) {
    Serial.println("ADS Unresponsive");
  }
  ads.setGain(ADS_GAIN);

  connectWiFi();
  syncTime();

}

void loop() {
  if (readPMS5003(pmsValues, pmsValid)) {
    Serial.print("PM1.0: "); Serial.println(pmsValues[PMS_PM1_0]);
    Serial.print("PM2.5: "); Serial.println(pmsValues[PMS_PM2_5]);
    Serial.print("PM10:  "); Serial.println(pmsValues[PMS_PM10]);
  }

  unsigned long now = millis();
  if (now - lastSendMillis >= SEND_INTERVAL_MS) {
    lastSendMillis = now;

    // MQ Raw Readings
    int16_t mqRaw[4];
    mqRaw[0] = ads.readADC_SingleEnded(0);
    mqRaw[1] = ads.readADC_SingleEnded(1);
    mqRaw[2] = ads.readADC_SingleEnded(2);
    mqRaw[3] = ads.readADC_SingleEnded(3);

    float mqVolt[4];
    for (int i = 0; i < 4; i++) {
      mqVolt[i] = ads.computeVolts(mqRaw[i]);
    }

    // DHT11 Readings
    int dhtValues[2] = { 0, 0 };
    int dhtResult = dht11.readTemperatureHumidity(dhtValues[0], dhtValues[1]);

    if (dhtResult != 0) {
      Serial.print("DHT11 Unresponsive: ");
      Serial.println(DHT11::getErrorString(dhtResult));
      return;
    }

    Serial.println("Timestamp: " + getTimestamp());
    Serial.println(pmsValid ? "PMS5003 VALID" : "PMS5003 NOT READY");

    sendToFirebase(mqRaw, mqVolt, dhtValues, pmsValues, pmsValid);
  }
}