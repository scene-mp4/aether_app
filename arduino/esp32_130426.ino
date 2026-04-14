#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <time.h>

const char* WIFI_SSID = "T.I.P.ian Student";
const char* WIFI_PASSWORD = "";

const char* PROJECT_ID = "pollutracker-bf276";
const char* TRACKER_ID = "tracker_002";

const char* NTP_SERVER      = "pool.ntp.org";
const long  GMT_OFFSET_SEC  = 28800;
const int   DAYLIGHT_OFFSET = 0;

HardwareSerial pmsSerial(1); // RX=16, TX=17
HardwareSerial unoSerial(2); // RX=18, TX=19

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
                    int temp,  int hum,
                    int pm1_0, int pm2_5, int pm10) {

  HTTPClient http;
  String url = "https://firestore.googleapis.com/v1/projects/" + String(PROJECT_ID) +
               "/databases/(default)/documents/devices/" + String(TRACKER_ID) +
               "/readings/";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<768> doc;
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
  unoSerial.begin(9600, SERIAL_8N1, 18, 19);

  connectWiFi();
  syncTime();

  Serial.println("Warming up PMS5003...");
  delay(30000);
}

void loop() {
  if (readPMS5003(pmsData)) {
    Serial.print("PM2.5: ");
    Serial.println(pmsData.pm2_5);
  }

  if (unoSerial.available()) {
    String line = unoSerial.readStringUntil('\n');
    line.trim();

    int mq2, mq9, mq135, temp, hum;
    float mq2_v, mq9_v, mq135_v;

    int matched = sscanf(line.c_str(), "%d,%f,%d,%f,%d,%f,%d,%d",
                         &mq2, &mq2_v,
                         &mq9, &mq9_v,
                         &mq135, &mq135_v,
                         &temp, &hum);

    if (matched == 8) {
      Serial.println("Timestamp: " + getTimestamp());

      if (pmsData.valid) {
        Serial.println("PMS5003 VALID");
      } else {
        Serial.println("PMS5003 NOT READY");
      }

      sendToFirebase(mq2, mq2_v,
                     mq9, mq9_v,
                     mq135, mq135_v,
                     temp, hum,
                     pmsData.pm1_0,
                     pmsData.pm2_5,
                     pmsData.pm10);
    } else {
      Serial.println("Bad data from Uno: " + line);
    }
  }
}
