/* 
* SLAVE CONTROLLER #3, ADDRESS 0x0C
*/
#include <Wire.h>

//defining slave address
#define SLAVE_ADDRESS 0x0C

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
  "BEDROOM_2 LPWM",    // D10, ATMEGA328P pin 16
  "BATHROOM_2 LDIG",   // D8, ATMEGA328P pin 14 
  "EMPTY",
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
int bedroom_2_pin;
int bathroom_2_pin;
//sensors
//--no sensors

/*
* initializes actuators
*/
void initActuators()
{
  //"BEDROOM_2 LPWM",    // D10, ATMEGA328P pin 16
  //"BATHROOM_2 LDIG",          // D8, ATMEGA328P pin 14 
  
  pinMode(10, OUTPUT);
  bedroom_2_pin = 10;

  pinMode(8,OUTPUT);
  bathroom_2_pin = 8;
}

/*
* initializes sensors
*/
void initSensors()
{
 //--no sensors 
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
 
 //--no sensors
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
     //--no sensors
   }  
  
   //set output_selector
   output_selector = object;
  }
  else if(prefix.equals("SET")) //if it's a SET we need to set an actuator
  {
    String value_str = getValue(msg,' ',2);
    int value = value_str.toInt();
    
    //handle actuators
    if(object.equals("BEDROOM_2")) 
    { 
     analogWrite(bedroom_2_pin, value);
     if(debug)
     { 
      Serial.print("bedroom_2_pin : ");
      Serial.print(value,DEC);
      Serial.print("\n");
     } 
    }
    if(object.equals("BATHROOM_2")) 
    {
     if(value==0) 
     { 
      digitalWrite(bathroom_2_pin, LOW);
      if(debug)
      { 
       Serial.print("bathroom_2_pin : ");
       Serial.print("LOW");
       Serial.print("\n");
      }
     }
     else 
     {
       digitalWrite(bathroom_2_pin, HIGH);
       if(debug)
       { 
        Serial.print("bathroom_2_pin : ");
        Serial.print("HIGH");
        Serial.print("\n");
       }
     } 
    } 
    
  }  
}
