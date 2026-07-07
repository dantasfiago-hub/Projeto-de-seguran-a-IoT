#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

#define WIFI_SSID "Wokwi-GUEST"
#define WIFI_PASSWORD ""

#define MQTT_SERVER "broker.hivemq.com"
#define MQTT_PORT 1883

#define TOPIC_STATUS "home/security/status"
#define TOPIC_COMMAND "home/security/command"

#define SENSOR_PORTA_ENTRADA 14
#define SENSOR_PORTA_SALA    13
#define SENSOR_QUARTO        12
#define SENSOR_COZINHA       33
#define SENSOR_GARAGEM       32
#define SENSOR_JANELA        15
#define LED_ALARME_PIN 26
#define LED_ARMADO_PIN 25
#define BUZZER_PIN 27

WiFiClient espClient;
PubSubClient mqttClient(espClient);

const char* DEVICE_ID = "esp32-security-wokwi";

struct SecuritySensor {
  const char* id;
  const char* name;
  int pin;
  bool enabled;
  bool triggered;
  bool lastTriggered;
};

SecuritySensor sensors[] = {
  {
    "porta_entrada",
    "Porta de Entrada",
    SENSOR_PORTA_ENTRADA,
    true,
    false,
    false
  },

  {
    "porta_sala",
    "Porta da Sala",
    SENSOR_PORTA_SALA,
    true,
    false,
    false
  },

  {
    "quarto",
    "Quarto",
    SENSOR_QUARTO,
    true,
    false,
    false
  },

  {
    "cozinha",
    "Cozinha",
    SENSOR_COZINHA,
    true,
    false,
    false
  },

  {
    "garagem",
    "Garagem",
    SENSOR_GARAGEM,
    true,
    false,
    false
  },

  {
    "janela_suite",
    "Janela da Suíte",
    SENSOR_JANELA,
    true,
    false,
    false
  }
};

const int SENSOR_COUNT = sizeof(sensors) / sizeof(sensors[0]);

unsigned long lastStatusPublish = 0;
const unsigned long statusInterval = 5000;

bool isSystemArmed() {
  for (int i = 0; i < SENSOR_COUNT; i++) {
    if (sensors[i].enabled) {
      return true;
    }
  }

  return false;
}

bool hasViolation() {
  for (int i = 0; i < SENSOR_COUNT; i++) {
    if (sensors[i].enabled && sensors[i].triggered) {
      return true;
    }
  }

  return false;
}

void updateAlarmOutputs() {
  bool armed = isSystemArmed();
  bool violation = hasViolation();

  digitalWrite(LED_ARMADO_PIN, armed ? HIGH : LOW);
  digitalWrite(LED_ALARME_PIN, violation ? HIGH : LOW);

  if (violation) {
    tone(BUZZER_PIN, 1000);
  } else {
    noTone(BUZZER_PIN);
  }
}

void publishSensorStatus(SecuritySensor& sensor, const char* eventType) {
  StaticJsonDocument<256> doc;

  doc["type"] = "status";
  doc["deviceId"] = DEVICE_ID;
  doc["event"] = eventType;
  doc["armed"] = isSystemArmed();
  doc["violation"] = hasViolation();
  doc["timestamp"] = millis();

  JsonObject sensorObj = doc.createNestedObject("sensor");
  sensorObj["id"] = sensor.id;
  sensorObj["name"] = sensor.name;
  sensorObj["enabled"] = sensor.enabled;
  sensorObj["state"] = sensor.triggered ? "aberto" : "fechado";

  char buffer[256];
  serializeJson(doc, buffer);

  mqttClient.publish(TOPIC_STATUS, buffer);

  Serial.print("Publicado: ");
  Serial.println(buffer);
}

void handleCommand(char* topic, byte* payload, unsigned int length) {
  String message;

  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }

  Serial.print("Comando recebido em ");
  Serial.print(topic);
  Serial.print(": ");
  Serial.println(message);

  StaticJsonDocument<256> doc;
  DeserializationError error = deserializeJson(doc, message);

  if (error) {
    Serial.println("Erro ao ler JSON");
    return;
  }

  const char* type = doc["type"];
  const char* command = doc["command"];
  const char* sensorId = doc["sensorId"];
  bool enabled = doc["enabled"];

  if (strcmp(type, "command") != 0) {
    return;
  }

  if (strcmp(command, "set_sensor_enabled") == 0) {
    for (int i = 0; i < SENSOR_COUNT; i++) {
      if (strcmp(sensors[i].id, sensorId) == 0) {
        sensors[i].enabled = enabled;

        Serial.print("Sensor ");
        Serial.print(sensors[i].name);
        Serial.print(": ");
        Serial.println(enabled ? "ARMADO" : "DESARMADO");

        updateAlarmOutputs();
        publishSensorStatus(sensors[i], "normal");
      }
    }
  }
}

void connectWiFi() {
  Serial.print("Conectando ao Wi-Fi");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("Wi-Fi conectado");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
}

void connectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Conectando ao MQTT... ");

    String clientId = "ESP32-Security-";
    clientId += String(random(0xffff), HEX);

    if (mqttClient.connect(clientId.c_str())) {
      Serial.println("conectado");

      mqttClient.subscribe(TOPIC_COMMAND);

      Serial.print("Inscrito em: ");
      Serial.println(TOPIC_COMMAND);

      for (int i = 0; i < SENSOR_COUNT; i++) {
        publishSensorStatus(sensors[i], "normal");
      }

    } else {
      Serial.print("falhou, erro=");
      Serial.println(mqttClient.state());
      delay(3000);
    }
  }
}

void readSensors() {
  for (int i = 0; i < SENSOR_COUNT; i++) {
    SecuritySensor& sensor = sensors[i];

    int value = digitalRead(sensor.pin);

    sensor.triggered = value == LOW;

    if (sensor.enabled && sensor.triggered && !sensor.lastTriggered) {
      publishSensorStatus(sensor, "violacao");
    }

    if (sensor.triggered != sensor.lastTriggered) {
      publishSensorStatus(sensor, "normal");
    }

    sensor.lastTriggered = sensor.triggered;
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("Serial Monitor funcionando");
  Serial.println("Iniciando ESP32 Security System...");

  
  for (int i = 0; i < SENSOR_COUNT; i++) {
    pinMode(sensors[i].pin, INPUT_PULLUP);
  }

 
  pinMode(LED_ALARME_PIN, OUTPUT);
  pinMode(LED_ARMADO_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  digitalWrite(LED_ALARME_PIN, LOW);
  digitalWrite(LED_ARMADO_PIN, LOW);
  noTone(BUZZER_PIN);

  connectWiFi();

  mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
  mqttClient.setCallback(handleCommand);

  updateAlarmOutputs();
}

void loop() {
  if (!mqttClient.connected()) {
    connectMQTT();
  }

  mqttClient.loop();

  readSensors();

  updateAlarmOutputs();

  if (millis() - lastStatusPublish >= statusInterval) {
    lastStatusPublish = millis();

    for (int i = 0; i < SENSOR_COUNT; i++) {
      publishSensorStatus(sensors[i], "normal");
    }
  }

  delay(100);
}