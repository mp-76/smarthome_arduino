/* 
* SLAVE CONTROLLER #1, ADDRESS 0x0A
*/
#include <Wire.h>

//defining slave address
#define SLAVE_ADDRESS 0x0A

//output selector  
String  output_selector = "LIST_DEVICES";

//counter
int counter = 0;

//the char buffer to store chars to be sent
char charBuf[32];

//boolean flag
boolean debug = false;


///////////////////// SLAVE CONFIGURATION ///////////////////////

//devices list
String devices[10] = {
  "LIVING_ROOM LPWM",    // D10, ATMEGA328P pin 16
  "PATIO LDIG",          // D8, ATMEGA328P pin 14 
  "SENSOR_1 LSENS",      // A0, ATMEGA328P pin 23
  "EMPTY",
  "EMPTY",
  "EMPTY",
  "EMPTY",
  "EMPTY",
  "EMPTY",
  "EMPTY"
  };
  
//pin mapping variables
//actuators
int living_room_pin;
int patio_pin;
//sensors
int sensor_1_pin;  
int sensor_1_value;

/*
* initializes actuators
*/
void initActuators()
{
  //"LIVING_ROOM LPWM",    // D10, ATMEGA328P pin 16
  //"PATIO LDIG",          // D8, ATMEGA328P pin 14 
  
  pinMode(10, OUTPUT);
  living_room_pin = 10;

  pinMode(8,OUTPUT);
  patio_pin = 8;
}

/*
* initializes sensors
*/
void initSensors()
{
 //"SENSOR_1 LSENS",      // A0, ATMEGA328P pin 23  
 sensor_1_pin = 0;
}

/////////////////////// END SLAVE CONFIG ///////////////////////////

/*
* String splitter function
* @param String data the string to be splitted
* @param char separator the separator char
* @param int index the split number
*/
String getValue(String data, char separator, int index)
{
 int found = 0;
  int strIndex[] = {0, -1  };
  int maxIndex = data.length()-1;
  for(int i=0; i<=maxIndex && found<=index; i++)
  {
  if(data.charAt(i)==separator || i==maxIndex)
  {
  found++;
  strIndex[0] = strIndex[1]+1;
  strIndex[1] = (i == maxIndex) ? i+1 : i;
  }
 }
  return found>index ? data.substring(strIndex[0], strIndex[1]) : "";
}

  
/*
* init function
*/
void setup()
{
  Wire.begin(SLAVE_ADDRESS);
  Wire.onReceive(receiveEvent);
  Wire.onRequest(requestEvent);
  
  //init Actuators and Sensors
  initActuators();
  initSensors();
  
  //standard delay
  delay(100);
  
  //init the serial port (for debugging and console messages..)
  Serial.begin(9600);
}

/* 
* main loop
*/
void loop()
{
  //do nothing, the SLAVES are event driven..
}

/*
* the requestEvent function is called where there is a data request to this slave on the I2C bus by the master
* just two requests are implemented: LIST_DEVICES, for obtaining the devices list, and the SENSORS requests
*/
void requestEvent() 
{
 String str = ""; 
  
 //handling of the LIST_DEVICES requests 
 if(output_selector.equals("LIST_DEVICES")) //return list of devices
 { 
  str = devices[counter]+"\n"; //creates the string \n terminated
  str.toCharArray(charBuf,32);
  Wire.write(charBuf);

  if(devices[counter].equals("EMPTY")) //check if the slot is empty 
  {
    counter=0; //reset counter
  }
  else counter++; //increments it
 } 
 
 //handling of the SENSOR requests
 if(output_selector.equals("SENSOR_1")) //handle for SENSOR_1
 {
  //do sensor reading
  str = String(sensor_1_value)+"\n";
  str.toCharArray(charBuf,32);
  Wire.write(charBuf); 
 }  
}

/*
* the receiveEvent is called whenever the master send commands over I2C to this slave
* the scope of the function is getting the incomingo command and performing the right actions required
*/
void receiveEvent(int bytes)
{
 String msg = "";
 String prefix = "";
 String object = "";

 //read from I2C
  while(Wire.available())    // slave may send less than requested
  { 
    char c = Wire.read();    // receive a byte as character
    if(c=='\n') break;
    msg+=c;
  }
  
  //prefix is the prefix of command ("CMD", "READ", "SET") 
  prefix = getValue(msg,' ',0);
  object = getValue(msg,' ',1);
 
  //if CMD or READ output_selector must be updated
  //then if it's a READ we need to read actual values for the SENSOR
  if(prefix.equals("CMD") || prefix.equals("READ"))
  {
   Serial.println("output_selector : "+msg);
  
   if(prefix.equals("READ")) //read sensor
   {
     if(object.equals("SENSOR_1")) //handle SENSOR_1
     {
      sensor_1_value = analogRead(sensor_1_pin);
      if(debug)
      { 
       Serial.print("sensor_1_value : ");
       Serial.print(sensor_1_value,DEC);
       Serial.print("\n");
      }
     } 
   }  
  
   //set output_selector
   output_selector = object;
  }
  else if(prefix.equals("SET")) //if it's a SET we need to set an actuator
  {
    String value_str = getValue(msg,' ',2);
    int value = value_str.toInt();
    
    //handle actuators
    if(object.equals("LIVING_ROOM")) 
    { 
     analogWrite(living_room_pin, value);
     if(debug)
     { 
      Serial.print("living_room_pin : ");
      Serial.print(value,DEC);
      Serial.print("\n");
     } 
    }
    if(object.equals("PATIO")) 
    {
     if(value==0) 
     { 
      digitalWrite(patio_pin, LOW);
      if(debug)
      { 
       Serial.print("living_room_pin : ");
       Serial.print("LOW");
       Serial.print("\n");
      }
     }
     else 
     {
       digitalWrite(patio_pin, HIGH);
       if(debug)
       { 
        Serial.print("living_room_pin : ");
        Serial.print("HIGH");
        Serial.print("\n");
       }
     } 
    } 
    
  }  
}
