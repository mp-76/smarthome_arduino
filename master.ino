/* 
* MASTER
*/
#include <Wire.h>

boolean debug = false;

int scanner = 0;
int area = 0;
int line = 0;
int device = 0;

String device_str = "";
String device_name = "";
String device_type = "";

class Device {
private:
 String name;
 String type;
 int address;
 
public:
Device(String name, String type, int address );
String getName();
String getType();
int getAddress();
};

Device::Device(String name, String type, int address )
{
 this->name = name;
 this->type = type;
 this->address = address;
}

String Device::getName()
{
  return this->name;
}

String Device::getType()
{
  return this->type;
}  

int Device::getAddress()
{
  return this->address;
}


////////////////////////////////////////////////////////////////////////////////////
template<typename Data>
class Vector {
  size_t d_size; // Stores no. of actually stored objects
  size_t d_capacity; // Stores allocated capacity
  Data *d_data; // Stores data
  public:
    Vector() : d_size(0), d_capacity(0), d_data(0) {}; // Default constructor
    Vector(Vector const &other) : d_size(other.d_size), d_capacity(other.d_capacity), d_data(0) { d_data = (Data *)malloc(d_capacity*sizeof(Data)); memcpy(d_data, other.d_data, d_size*sizeof(Data)); }; // Copy constuctor
    ~Vector() { free(d_data); }; // Destructor
    Vector &operator=(Vector const &other) { free(d_data); d_size = other.d_size; d_capacity = other.d_capacity; d_data = (Data *)malloc(d_capacity*sizeof(Data)); memcpy(d_data, other.d_data, d_size*sizeof(Data)); return *this; }; // Needed for memory management
    void push_back(Data const &x) { if (d_capacity == d_size) resize(); d_data[d_size++] = x; }; // Adds new value. If needed, allocates more space
    size_t size() const { return d_size; }; // Size getter
    Data const &operator[](size_t idx) const { return d_data[idx]; }; // Const getter
    Data &operator[](size_t idx) { return d_data[idx]; }; // Changeable getter
  private:
    void resize() { d_capacity = d_capacity ? d_capacity*2 : 1; Data *newdata = (Data *)malloc(d_capacity*sizeof(Data)); memcpy(newdata, d_data, d_size * sizeof(Data)); free(d_data); d_data = newdata; };// Allocates double the old space
};



//////////////////////////////////////////////////////////////////////////////////////////////////

Vector<Device*> devices; //vector for devices

void printDeviceVector(Vector<Device*> devices)
{
 Serial.println("Devices vector:");
 for (int idx = 0; idx < devices.size(); ++idx)
 { 
   Device* ptr = devices[idx];
   Serial.println(ptr->getName()+" - "+ptr->getType()+" - "+ptr->getAddress());
 }

}

/*
* string splitter
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
* send a command to a slave
* @param int slave_address the address of the slave to send to
* @param String command the command to send
*/
void sendCommand(int slave_address, String command)
{
  char buffer[32];
  command+="\n";
  command.toCharArray(buffer,32);
  Wire.beginTransmission(slave_address); // transmit to device #    
  Wire.write(buffer);
  Wire.endTransmission();
  //wait
  delay(100);
}

/*
* read from slave
* @param int slave_address the address of the slave to send to
* @param int num_bytes the number of bytes to read (max is 32)
* @param String command the command to send
*/
String readFromSlave(int slave_address,int num_bytes)
{
  String str = "";
  if(num_bytes >0 && num_bytes <= 32)
  {
   Wire.requestFrom(slave_address,num_bytes); //requesting 32 bytes..
 
      while(Wire.available())    // slave may send less than requested
      { 
        char c = Wire.read();    // receive a byte as character
        if(c=='\n') break;
        str+=c;
      }
   }   
 return str;
}

/*
* read a sensor value from a slave
* @param int slave_address the address of the slave to send to
* @param String sensor_name the name of the sensor
* @param String sensor_type of the sensor
* @param String the returned string with value
*/
String readSensor(int slave_address,String sensor_name, String sensor_type)
{
  String str = "";
  String value = "";
  
  sendCommand(slave_address,"READ "+sensor_name);
  value=readFromSlave(slave_address,32);
  
  value += " "+sensor_type;
    
  if(debug) 
  {
   Serial.print("sensor value : ");
   Serial.print(value);
   Serial.print("\n");
  }
  
  return value;
}

/*
* set an actuator value
* @param int slave_address the address of the slave to send to
* @param String actuator_name the name of the actuator
* @param int value the value to set
*/
void setActuator(int slave_address, String actuator_name, int value)
{
  sendCommand(slave_address,"SET "+actuator_name+" "+value);
  if(debug) 
  {
   Serial.print("actuator value : ");
   Serial.print(value,DEC);
   Serial.print("\n");
  }
}

/*
* lists devices hosted by a slave
*/
void slaveListDevices(int slave_address)
{
    String device = "";
    int line_counter=0;
   
    
    Serial.print("List devices for SLAVE 0x");
    if(slave_address<16) Serial.print("0");
    Serial.print(slave_address,HEX);
    Serial.print('\n');
       
    //set output_selector on slave  to list devices
    sendCommand(slave_address, "CMD LIST_DEVICES");
      
    for(int device_c = 0; device_c < 10; device_c++)
    {

      device_str="";
      device_name="";
      device_type="";

      device_str = readFromSlave(slave_address, 32);
      if(device_str.equals("EMPTY")) break; //at first empty slot exit main loop    
      
      device_name = getValue(device_str,' ',0); //set device_name
      device_type = getValue(device_str,' ',1); //set device_type   
      
      /* removed cause of memory issues */
      //Device* dev = new Device(device_name,device_type,(slave_address*10)+device_c);
      //insert into devices vector
      //devices.push_back(dev);
          
     
      Serial.print("device #");
      Serial.print(device_c,DEC);
      Serial.println(" : "+device_str);
             
    }  
}

//TESTING ROUTINES, JUST TO TEST SETUP, ADDRESSES ARE WIRED IN THIS CASE
void test_S1()
{ 
 slaveListDevices(0x0A);
 
 readSensor( 0x0A, "SENSOR_1", "LSENS");
 
 //test actuators
 
 setActuator(0x0A,"LIVING_ROOM",200);
 
 delay(1000);
 
 setActuator(0x0A,"LIVING_ROOM",0);
 
 delay(1000);
 
 setActuator(0x0A,"LIVING_ROOM",200);
 
 delay(1000);
 
 setActuator(0x0A,"PATIO",200);
 
 delay(1000);
 
 setActuator(0x0A,"PATIO",0);
 
 delay(1000);
 
 setActuator(0x0A,"PATIO",200);
 
}

void test_S2()
{
 slaveListDevices(0x0B);
 //readSensor( 0x0B, "SENSOR_1", "TSENS");
 String value_tsens = readSensor( 0x0B, "SENSOR_1", "TSENS");
 
 double f_value = value_tsens.toFloat();
 
 f_value = (f_value/2)-273; //gives temperature in °C with 0.5 °C of resolution
 
 Serial.print("temperature is: ");
 printDouble(f_value,2);
 Serial.println(" °C");
 
 //test actuators
 
 setActuator(0x0B,"BEDROOM_1",200);
 
 delay(1000);
 
 setActuator(0x0B,"BEDROOM_1",0);
 
 delay(1000);
 
 setActuator(0x0B,"BEDROOM_1",200);
 
 delay(1000);
 
 setActuator(0x0B,"BATHROOM_1",200);
 
 delay(1000);
 
 setActuator(0x0B,"BATHROOM_1",0);
 
 delay(1000);
 
 setActuator(0x0B,"BATHROOM_1",200);
}

void test_S3()
{ 
 slaveListDevices(0x0C);
 
 //test actuators
 
 setActuator(0x0C,"BEDROOM_2",200);
 
 delay(1000);
 
 setActuator(0x0C,"BEDROOM_2",0);
 
 delay(1000);
 
 setActuator(0x0C,"BEDROOM_2",200); 
 
 delay(1000);
 
 setActuator(0x0C,"BATHROOM_2",1);
 
 delay(1000);
 
 setActuator(0x0C,"BATHROOM_2",0);
 
 delay(1000);
 
 setActuator(0x0C,"BATHROOM_2",1);
}

void test_S4()
{ 
 slaveListDevices(0x0D);
 
 //test actuators
 setActuator(0x0D,"LOBBY",200);
 
 delay(1000);
 
 setActuator(0x0D,"LOBBY",0); 
 
 delay(1000);
 
 setActuator(0x0D,"LOBBY",200);
 
 delay(1000);
 
 setActuator(0x0D,"KITCHEN",200);
 
 delay(1000);
 
 setActuator(0x0D,"KITCHEN",0);
 
 delay(1000);
 
 setActuator(0x0D,"KITCHEN",200);
 
 delay(1000);
 
 setActuator(0x0D,"MICROWAVE_OVEN",1);
 
 delay(1000);
 
 setActuator(0x0D,"MICROWAVE_OVEN",0);
 
 delay(1000);
 
 setActuator(0x0D,"MICROWAVE_OVEN",1); 
 
}

/*
* combined test routine
*/
void testControllers()
{
 test_S1();
 test_S2();
 test_S3();
 test_S4();
}


//////////////////////////TESTING//////////////////////////

//////////////////////////PROTOCOL HELPERS/////////////////

/* 
* wait for string
* returns the complete string read from serial or 'timeout'
* @param str the string expected
*/
String waitFor(String str)
{
  String read_str = Serial.readStringUntil('\n'); //return string read or goes in timeout
  read_str = read_str.substring(0, read_str.length() - 1); //trim \r
  if(read_str.equals(str))
  {
   return read_str;
  }
  else
     {
       return "error";
     } 
}

/* 
* wait for partial/initial string
* returns the complete string read from serial or 'timeout'
* @param str the partial string expected
*/
String waitForPartial(String str)
{
  String read_str = Serial.readStringUntil('\n'); //return string read or goes in timeout
  if(read_str.startsWith(str))
  {
   return read_str;
  }
  else
     {
       return "error";
     } 
}



/////////////////////////////////////////////////////////////////

/*
* a utility function to print a double, with configurable precision and sign. digits
*/
void printDouble( double val, byte precision)
{
  // prints val with number of decimal places determine by precision
  // precision is a number from 0 to 6 indicating the desired decimial places
  // example: printDouble( 3.1415, 2); // prints 3.14 (two decimal places)

  Serial.print (int(val));  //prints the int part
  if( precision > 0) 
  {
    Serial.print("."); // print the decimal point
    unsigned long frac;
    unsigned long mult = 1;
    byte padding = precision -1;
    while(precision--)
       mult *=10;
       
    if(val >= 0)
      frac = (val - int(val)) * mult;
    else
      frac = (int(val)- val ) * mult;
    unsigned long frac1 = frac;
    while( frac1 /= 10 )
      padding--;
    while(  padding--)
      Serial.print("0");
    Serial.print(frac,DEC) ;
  }
}

/*
* Returns int the number of controllers found and their addresses, then also devices hosted
* this is done by polling the bus at AREA.LINE valid addresses for controllers.. like in KNX
*
* NOTICE: AREA.LINE.DEVICE logical addresses are runtime recovered on need, using controller 
* addr. and devices order, so it's not needed to propagate up the logical address 
* IMPORTANT: PC app will use mnemonics to map devices (so avoid using explicit DEVICE subaddress, 
* this was forced by requirements..)
*/
int scanBus()
{
 int count = 0;  
 
 for (area = 1; area <= 10; area++)
 {
   for(line = 0; line < 10; line++)
   {
     scanner = area*10+line;
     /*
     if(debug) Serial.print ("scanner ");
     if(debug) Serial.print (scanner, DEC);
     if(debug) Serial.print ("\r\n");
     */
     Wire.beginTransmission (scanner);
     

     if (Wire.endTransmission () == 0)
       {
        Serial.print ("Found slave controller: ");
        Serial.print (scanner, DEC);
        Serial.print (" (0x");
        if(scanner<16) Serial.print ("0");
        Serial.print (scanner, HEX);
        Serial.println (")");
        count++;
       
       slaveListDevices(scanner); //then for each controller it requires the list of devices hosted
             
       } // end of good response 
      delay (5);  // give devices time to recover

   } 
 } // end of for loop
 
   
}


/*
* init function
*/

void setup() 
{ 
 Wire.begin();
 
 Serial.begin (9600);

 
 //testControllers();

}  // end of setup

/*
* This is the most important function: controlLoop;
* the scope of the function is receiving commands from the PC app using the pc-master protocol
* over serial and then route commands to the slaves using the I2C bus and the master-slave protocol.
* It's an infinite loop.
*/
void controlLoop()
{
 String str = "";
 
 //infinite control loop
 while(true) 
 {
  //1 WAIT FOR COMMANDS
  str = waitForPartial("CMD");
  if(str.equals("error")) continue; //timeout or other error detected  
 
  if(str.equals("CMD SCAN BUS"))  //PC wants list of controllers/devices 
  {
    //scan for controllers and devices, returns data on serial..
    scanBus(); 
    Serial.println ("-");
    delay(100);
  }  
  else //get sensor value or set actuator value
     {
       //tokenize the string..
       String subcommand = getValue(str,' ',1);
       
       if(subcommand.equals("SET")) //set actuator value..
       {
         String mixed = getValue(str,' ',2); // format is like addr_of_controller,name_of_actuator,value example 10,PATIO,1
         
         int addr = getValue(mixed,',',0).toInt();
         String name = getValue(mixed,',',1);
         int value = getValue(mixed,',',2).toInt();
         
         setActuator(addr,name,value);
         //Serial.println ("done set "+mixed+" -");
       }
       if(subcommand.equals("GET")) //get sensor value.. 
       {
         String mixed = getValue(str,' ',2); // format is like addr_of_controller,name_of_sensor,type_of_sensor example 10,SENSOR_1,LSENS
         
         int addr = getValue(mixed,',',0).toInt();
         String name = getValue(mixed,',',1);
         String type = getValue(mixed,',',2);
         
         Serial.print(readSensor(addr,name,type));
         Serial.println(" -");
       }
     }
 }
}

/*
* main loop, just executes controlLoop
*/
void loop() 
{  
 //nested 
 controlLoop();   
}




