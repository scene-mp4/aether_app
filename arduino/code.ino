#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <time.h>
#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <DHT.h>
#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>           

#define BLE_SERVICE_UUID  "12345678-1234-1234-1234-123456789abc"
#define BLE_SSID_UUID     "12345678-1234-1234-1234-123456789001"
#define BLE_PASS_UUID     "12345678-1234-1234-1234-123456789002"
#define BLE_STATUS_UUID   "12345678-1234-1234-1234-123456789003"

Preferences prefs;

String  bleSSID     = "";
String  blePass     = "";
bool    bleCredsReady  = false;
bool    bleClientConn  = false;

BLECharacteristic* pStatusChar = nullptr;

class AetherServerCB : public BLEServerCallbacks {
  void onConnect(BLEServer*)    override { bleClientConn = true;  }
  void onDisconnect(BLEServer* s) override {
    bleClientConn = false;
    s->startAdvertising();
  }
};

class SSIDWriteCB : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    bleSSID = c->getValue().c_str();
    Serial.println("BLE SSID received: " + bleSSID);
  }
};

class PassWriteCB : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    blePass = c->getValue().c_str();
    Serial.println("BLE Password received.");
    bleCredsReady = true;
  }
};

void startBLEProvisioning() {
  BLEDevice::init("AETHER_SETUP");
  BLEServer*  server  = BLEDevice::createServer();
  BLEService* service = server->createService(BLE_SERVICE_UUID);
  server->setCallbacks(new AetherServerCB());

  BLECharacteristic* pSSID = service->createCharacteristic(
    BLE_SSID_UUID, BLECharacteristic::PROPERTY_WRITE);
  pSSID->setCallbacks(new SSIDWriteCB());

  BLECharacteristic* pPass = service->createCharacteristic(
    BLE_PASS_UUID, BLECharacteristic::PROPERTY_WRITE);
  pPass->setCallbacks(new PassWriteCB());

  pStatusChar = service->createCharacteristic(
    BLE_STATUS_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pStatusChar->addDescriptor(new BLE2902());
  pStatusChar->setValue("WAITING");

  service->start();
  BLEDevice::getAdvertising()->addServiceUUID(BLE_SERVICE_UUID);
  BLEDevice::getAdvertising()->setScanResponse(true);
  BLEDevice::startAdvertising();
  Serial.println("BLE advertising as AETHER_SETUP...");
}

bool attemptWiFiConnect(const String& ssid, const String& pass) {
  WiFi.begin(ssid.c_str(), pass.c_str());
  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 20) {
    delay(500); Serial.print("."); retries++;
  }
  return WiFi.status() == WL_CONNECTED;
}

// ── Replaces connectWiFi() ────────────────────────────────────────────────────
void connectWiFi() {
  String ssid, pass;

  // 1. Try NVS first
  prefs.begin("wifi", true);
  ssid = prefs.getString("ssid", "");
  pass = prefs.getString("pass", "");
  prefs.end();

  if (ssid.length() > 0) {
    Serial.println("Trying saved credentials...");
    if (attemptWiFiConnect(ssid, pass)) {
      Serial.println("\nWiFi Connected: " + WiFi.localIP().toString());
      WiFi.setSleep(true);
      return;
    }
    Serial.println("\nSaved credentials failed. Starting BLE provisioning.");
  }

  // 2. Start BLE and wait for app
  startBLEProvisioning();
  while (!bleCredsReady) { delay(100); }

  if (pStatusChar) { pStatusChar->setValue("CONNECTING"); pStatusChar->notify(); }

  bool ok = attemptWiFiConnect(bleSSID, blePass);

  if (ok) {
    // Save to NVS
    prefs.begin("wifi", false);
    prefs.putString("ssid", bleSSID);
    prefs.putString("pass", blePass);
    prefs.end();

    if (pStatusChar) { pStatusChar->setValue("SUCCESS"); pStatusChar->notify(); }
    delay(1000);
    BLEDevice::deinit(true); // free BLE memory before WiFi-heavy operations
    Serial.println("\nWiFi Connected: " + WiFi.localIP().toString());
    WiFi.setSleep(true);
  } else {
    if (pStatusChar) { pStatusChar->setValue("FAILED"); pStatusChar->notify(); }
    Serial.println("Connection failed. Restarting...");
    delay(2000);
    ESP.restart();
  }
}