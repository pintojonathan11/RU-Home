int sensorPin = A0;
int sensorValue = 0;

void setup() {
   Serial.begin(9600); 
}


void loop(){
 sensorValue = digitalRead(sensorPin);
 Serial.println(sensorValue);
 delay(1000);
}
