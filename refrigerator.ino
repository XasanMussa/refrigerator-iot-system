#include <SPI.h>
#include <MFRC522.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <DHT.h>
#include <WiFi.h>
#include <WiFiClient.h>
#include <FirebaseESP32.h>

// RFID setup
#define RST_PIN 5
#define SS_PIN 4
#define RELAY_PIN 2

MFRC522 rfid(SS_PIN, RST_PIN);

// LCD setup (I2C 16x2, SDA=21, SCL=22)
LiquidCrystal_I2C lcd(0x27, 16, 2);

// DHT22 setup
#define DHTPIN 13
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// Authorized RFID cards
byte authorizedUIDs[][4] = {
  { 0x62, 0x50, 0x2C, 0x3C },
  { 0x53, 0x24, 0x20, 0x14 }
};

// Fan control pins
const int fan1_pwm = 27;
const int fan2_pwm = 26;
const int fan1_in1 = 25;
const int fan1_in2 = 33;
const int fan2_in1 = 32;
const int fan2_in2 = 14;
const int pot_pin = 34;

bool fans_enabled = false;

// WiFi credentials
const char* ssid = "Setsom";
const char* password = "0614444243";

// Firebase credentials
#define FIREBASE_HOST "https://refrigerator-iot-system-default-rtdb.firebaseio.com/"
#define FIREBASE_AUTH "bezal1cM2Co5Nz6O9u7rCISnv5H66sWQ3yXHlX22"
#define API_KEY "AIzaSyAm4tES8riDvyKX5qCwj_JTYX3hDlhOuSo"


// Firebase Data object
FirebaseData firebaseData;
FirebaseAuth firebaseAuth;
FirebaseConfig firebaseConfig;

void setup() {
  Serial.begin(115200);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print("connecting to wifi.....");
  }
  Serial.println("WiFi connected successfully");

  // Initialize Firebase
  Serial.println("initializing firebase phase 1");
  firebaseConfig.host = FIREBASE_HOST;
  firebaseConfig.api_key = API_KEY;
  firebaseAuth.user.email = "yare4892@gmail.com";
  firebaseAuth.user.password = "test123";

  Serial.println("initializing firebase phase 2");
  Firebase.begin(&firebaseConfig, &firebaseAuth);
  Firebase.reconnectWiFi(true);
  Serial.println("firebase successfully signed in");

    SPI.begin(18, 19, 23, SS_PIN);  // SCK, MISO, MOSI, SS
  rfid.PCD_Init();
  dht.begin();

  // LCD init
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("RFID Fan System");
  lcd.setCursor(0, 1);
  lcd.print("System Ready");

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);  // Door locked initially

  // Fan motor pins
  pinMode(fan1_pwm, OUTPUT);
  pinMode(fan2_pwm, OUTPUT);
  pinMode(fan1_in1, OUTPUT);
  pinMode(fan1_in2, OUTPUT);
  pinMode(fan2_in1, OUTPUT);
  pinMode(fan2_in2, OUTPUT);

  // Set fan direction
  digitalWrite(fan1_in1, HIGH);
  digitalWrite(fan1_in2, LOW);
  digitalWrite(fan2_in1, HIGH);
  digitalWrite(fan2_in2, LOW);

  Serial.println("ESP32 RFID & Fan Control Ready");
}

void loop() {
  handleRFID();
  checkTemperature();
  handleFanSpeed();
}

void handleRFID() {
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) return;

  Serial.print("Card UID: ");
  for (byte i = 0; i < rfid.uid.size; i++) {
    Serial.print(rfid.uid.uidByte[i], HEX);
    Serial.print(" ");
  }
  Serial.println();

  if (checkUID(rfid.uid.uidByte)) {
    Serial.println("Access Granted");
    lcd.setCursor(0, 0);
    lcd.print("Access: Granted ");
    digitalWrite(RELAY_PIN, LOW);  // Unlock door
    delay(3000);
    digitalWrite(RELAY_PIN, HIGH);  // Lock again
  } else {
    Serial.println("Access Denied");
    lcd.setCursor(0, 0);
    lcd.print("Access: Denied  ");
  }

  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
}

bool checkUID(byte* uid) {
  for (int i = 0; i < sizeof(authorizedUIDs) / 4; i++) {
    bool match = true;
    for (int j = 0; j < 4; j++) {
      if (uid[j] != authorizedUIDs[i][j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}

void checkTemperature() {
  float temp = dht.readTemperature();

  if (isnan(temp)) {
    Serial.println("Failed to read from DHT22");
    return;
  }

  // Serial.print("Temperature: ");
  // Serial.println(temp);

  lcd.setCursor(0, 1);
  lcd.print("Temp: ");
  lcd.print(temp, 1);
  lcd.print("C  ");

   if (Firebase.setInt(firebaseData, "/tempData", temp)) {
    Serial.println("temperature value sent to Firebase");
  } else {
    Serial.println("Failed to send temperature value to firebase");
    Serial.println(firebaseData.errorReason());
  }
}
void handleFanSpeed() {
  // int pot_value = analogRead(pot_pin); // 0 to 4095
  // int pot_percent = map(pot_value, 0, 1023, 0, 100); // 0 to 100 scale (slider physical  wye ee ku badalo slider ka appka kana so akhriso RDB )
  // int fan_speed = map(pot_value, 0, 1023, 0, 255);   // PWM speed
  //   Serial.println(fan_speed);

  float temp = dht.readTemperature();

  if (isnan(temp)) {
    Serial.println("DHT22 read error.");
    return;
  }


  if (Firebase.getInt(firebaseData, "/fanSpeed")) {
    int fan_speed = firebaseData.intData();
    if (fan_speed >= 20) {

      analogWrite(fan1_pwm, fan_speed);
      analogWrite(fan2_pwm, fan_speed);
    } else {
      // Auto temperature mode
      if (temp > 35) {
        analogWrite(fan1_pwm, 255);  // Full speed
        analogWrite(fan2_pwm, 255);
        // Serial.println("Auto Fan ON (Temp > 34)");

      } else {
        analogWrite(fan1_pwm, 0);
        analogWrite(fan2_pwm, 0);
        // Serial.println("Auto Fan OFF (Temp <= 34)");
      }
    }
  }else {
      Serial.print("couldn't read firebaseData of the fanspeed");
    }

  // Serial.print("Manual Fan Speed: ");
  // Serial.println(fan_speed);
}