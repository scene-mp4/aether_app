#include <WiFi.h>
#include "WiFiProv.h"
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <time.h>
#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <DHT.h>

HardwareSerial pmsSerial(1);

DHT dht22(4, DHT22);

Adafruit_ADS1115 ads;
const uint8_t   ADS_ADDR = 0x48;
const adsGain_t ADS_GAIN = GAIN_TWOTHIRDS;

const char* PROJECT_ID = "pollutracker-bf276";
const char* TRACKER_ID = "tracker_002";

const char* POP               = "abcd1234";
const char* SERVICE_KEY       = NULL;
bool        RESET_PROVISIONED = false;
String      SERVICE_NAME;

const char* NTP_SERVER     = "pool.ntp.org";
const long  GMT_OFFSET_SEC = 28800;
const int   DAYLIGHT_OFFSET = 0;

const unsigned long SEND_INTERVAL_MS = 5000;
unsigned long lastSendMillis = 0;

//Timestamp Handler
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

//Provisioning Event Handler
void SysProvEvent(arduino_event_t *sys_event) {
  switch (sys_event->event_id) {
    case ARDUINO_EVENT_PROV_START:
      Serial.println("\nSearching for Application");
      Serial.print("Service name: ");
      Serial.println(SERVICE_NAME);
      break;

    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("\nWiFi Connected! IP address: ");
      Serial.println(IPAddress(sys_event->event_info.got_ip.ip_info.ip.addr));
      break;

    case ARDUINO_EVENT_PROV_CRED_RECV:
      Serial.println("\nReceived WiFi credentials from app:");
      Serial.print("  SSID: ");
      Serial.println((const char *)sys_event->event_info.prov_cred_recv.ssid);
      break;

    case ARDUINO_EVENT_PROV_CRED_FAIL:
      Serial.println("\nProvisioning failed!");
      if (sys_event->event_info.prov_fail_reason == WIFI_PROV_STA_AUTH_ERROR) {
        Serial.println("  Reason: Wi-Fi password incorrect.");
      } else {
        Serial.println("  Reason: Wi-Fi AP not found.");
      }
      break;

    case ARDUINO_EVENT_PROV_CRED_SUCCESS:
      Serial.println("\nProvisioning successful — credentials accepted.");
      break;

    case ARDUINO_EVENT_PROV_END:
      Serial.println("\nProvisioning session ended.");
      break;

    default:
      break;
  }
}

//PMS5003
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
        for (int i = 0; i < 30; i++) buf[i] = pmsSerial.read();

        int checksum = 0x42 + 0x4D;
        for (int i = 0; i < 28; i++) checksum += buf[i];
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

//Time Sync
void syncTime() {
  Serial.print("Syncing time with NTP...");
  configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET, NTP_SERVER);
  struct tm timeinfo;
  int retries = 0;
  while (!getLocalTime(&timeinfo) && retries < 10) {
    delay(1000); Serial.print("."); retries++;
  }
  Serial.println(retries < 10
    ? "\nTime synced: " + getTimestamp()
    : "\nNTP sync failed.");
}

//SendToFirebase
void sendToFirebase(int16_t mqRaw[], float mqVolt[],
                    int dhtValues[],
                    int pmsVals[], bool pmsOk) {
  HTTPClient http;
  String url = "https://firestore.googleapis.com/v1/projects/" +
               String(PROJECT_ID) +
               "/databases/(default)/documents/devices/" +
               String(TRACKER_ID) + "/readings/";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  StaticJsonDocument<896> doc;
  JsonObject fields = doc.createNestedObject("fields");

  fields["timestamp"]["stringValue"] = getTimestamp();
  fields["date"]["stringValue"]      = getDateOnly();
  fields["time"]["stringValue"]      = getTimeOnly();

  const char* mqRawKeys[]  = { "mq2",   "mq9",   "mq135",   "mq131"   };
  const char* mqVoltKeys[] = { "mq2_v", "mq9_v", "mq135_v", "mq131_v" };
  for (int i = 0; i < 4; i++) {
    fields[mqRawKeys[i]]["integerValue"]  = String(mqRaw[i]);
    fields[mqVoltKeys[i]]["doubleValue"]  = mqVolt[i];
  }

  fields["temperature"]["integerValue"] = String(dhtValues[0]);
  fields["humidity"]["integerValue"]    = String(dhtValues[1]);

  const char* pmsKeys[] = { "pm1_0", "pm2_5", "pm10" };
  for (int i = 0; i < 3; i++) {
    if (pmsOk) fields[pmsKeys[i]]["integerValue"] = String(pmsVals[i]);
    else       fields[pmsKeys[i]]["nullValue"]     = nullptr;
  }

  String body;
  serializeJson(doc, body);

  Serial.println("\nSending to Firebase.");
  Serial.println(body);

  int httpCode = http.POST(body);
  Serial.print("HTTP Code: ");
  Serial.println(httpCode);
  if (httpCode > 0) Serial.println("Response: " + http.getString());
  else              Serial.println("No Data Sent");

  http.end();
}

void setup() {
  Serial.begin(115200);
  pmsSerial.begin(9600, SERIAL_8N1, 16, 17);

  dht22.begin();                            // ✅ Replaces nothing — DHT11 had no begin()

  Serial.println("Preparing PMS5003...");
  delay(30000);

  Wire.begin();
  if (!ads.begin(ADS_ADDR)) Serial.println("ADS Unresponsive");
  ads.setGain(ADS_GAIN);

  SERVICE_NAME = "PROV_" + String(TRACKER_ID);

  WiFi.onEvent(SysProvEvent);
  WiFiProv.beginProvision(
    WIFI_PROV_SCHEME_BLE,
    WIFI_PROV_SCHEME_HANDLER_FREE_BTDM,
    WIFI_PROV_SECURITY_1,
    POP,
    SERVICE_NAME.c_str(),
    SERVICE_KEY,
    NULL,
    RESET_PROVISIONED
  );

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

    int16_t mqRaw[4];
    mqRaw[0] = ads.readADC_SingleEnded(0);
    mqRaw[1] = ads.readADC_SingleEnded(1);
    mqRaw[2] = ads.readADC_SingleEnded(2);
    mqRaw[3] = ads.readADC_SingleEnded(3);

    float mqVolt[4];
    for (int i = 0; i < 4; i++) mqVolt[i] = ads.computeVolts(mqRaw[i]);

    // ✅ DHT22 read — replaces dht11.readTemperatureHumidity()
    int dhtValues[2] = { 0, 0 };
    float temp = dht22.readTemperature();
    float hum  = dht22.readHumidity();

    if (isnan(temp) || isnan(hum)) {      // ✅ Replaces dhtResult != 0 check
      Serial.println("DHT22 Unresponsive: Failed to read temperature/humidity.");
      return;
    }

    dhtValues[0] = (int)temp;
    dhtValues[1] = (int)hum;

    Serial.println("Timestamp: " + getTimestamp());
    Serial.println(pmsValid ? "PMS5003 VALID" : "PMS5003 NOT READY");

    sendToFirebase(mqRaw, mqVolt, dhtValues, pmsValues, pmsValid);
  }
}