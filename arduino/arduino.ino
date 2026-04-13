#include <DHT11.h>

const int PIN_MQ2   = A0;
const int PIN_MQ9   = A1;
const int PIN_MQ135 = A2;
DHT11 dht11(7);


const unsigned long SEND_INTERVAL = 300000; //5 mins per send

unsigned long lastSend = 0;

void setup() {
  Serial.begin(9600);

  Serial.println("Sensor warmup...");
  delay(3000);

  Serial.println("READY");
}

void loop() {
  if (millis() - lastSend > SEND_INTERVAL) {
    lastSend = millis();

    int mq2       = analogRead(PIN_MQ2);
    float mq2_v   = mq2 * (5.0 / 1023.0);

    int mq9       = analogRead(PIN_MQ9);
    float mq9_v   = mq9 * (5.0 / 1023.0);

    int mq135     = analogRead(PIN_MQ135);
    float mq135_v = mq135 * (5.0 / 1023.0);

    int temp = 0, hum = 0;
    dht11.readTemperatureHumidity(temp, hum);

    Serial.print(mq2);     Serial.print(",");
    Serial.print(mq2_v);   Serial.print(",");
    Serial.print(mq9);     Serial.print(",");
    Serial.print(mq9_v);   Serial.print(",");
    Serial.print(mq135);   Serial.print(",");
    Serial.print(mq135_v); Serial.print(",");
    Serial.print(temp);    Serial.print(",");
    Serial.println(hum);
  }
}
