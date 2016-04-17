///////////////////////////////////////////////////////////////////////////////////
//
// PC APPLICATION
//
///////////////////////////////////////////////////////////////////////////////////

//java imports
import java.lang.*;
import java.io.*;
import java.net.*;
import java.util.*;

//processing imports
import processing.serial.*;
import grafica.*;
import controlP5.*;    // import controlP5 library

ControlP5 cp5;   // controlP5 object
PFont pfont = createFont("Arial",20,true); // use true/false for smooth/no-smooth
color signaling_color;
Textarea commTextarea; 
//////////////////HOUSE MODEL///////////////////////
House house = null;
House house_stored = null;

//////////////SIMULATION FLAG///////////////////////
boolean simulate_cmd_sending = false; //if true house status commands are not sent, if false commands are sent : used for debug

//////////////GUI CONTROLLERS VALUES////////////////
HashMap<String,Integer> cp5_controllers = null;

//////////////////SERIAL PORT CONFIG
Serial port;  // Create object from Serial class
String serial_port = "COM9";
int baudrate = 9600;
int serial_timeout = 30000; //in milliseconds

////// GENERAL
int loop_number = 1; //tracks num loops of main control
int start_time = 0; //used for timeouts

//////////////////DEBUG CONFIG
//boolean debug = false;    //if true debug with exceptions, stack trace etc.
boolean debug = true;


///////////////////////////MODELS///////////////////////////////////

abstract class Actuator  
{
  abstract public void setName(String name);  
  abstract public String getName();
  abstract public void setValue(int value);  
  abstract public int getValue();
}

class AnalogLightActuator extends Actuator  
{
  private String name;
  private int value;
  
  public AnalogLightActuator(String name)
  {
    this.name = name;
    this.value = 0;
  }
  
  public AnalogLightActuator(String name, int value)
  {
    this.name = name;
    this.value = value;
  }
  
  public void setValue(int value)
  {
    this.value = value;
  }
  
  public int getValue()
  {
    return this.value;
  }
  
  public void setName(String name)
  {
    this.name = name;
  }
  
  public String getName()
  {
    return this.name;
  }
}

class DigitalLightActuator extends Actuator  
{
  private String name;
  private int value;
  
  public DigitalLightActuator(String name)
  {
    this.name = name;
    this.value = 0;
  }
  
  public DigitalLightActuator(String name, int value)
  {
    if(value>0)
    {
     this.value = 1;
    }
    else 
       {
         this.value = 0;
       } 
       
    this.name = name;   
  }
  
  public void setValue(int value)
  {
    if(value>0)
    {
     this.value = 1;
    }
    else 
       {
         this.value = 0;
       } 
  }
  
  public int getValue()
  {
    return this.value;
  }
      
  public void setName(String name)
  {
    this.name = name;
  }
  
  public String getName()
  {
    return this.name;
  }
}

abstract class Sensor  
{
  abstract public void setName(String name);  
  abstract public String getName();
  abstract public int getValue();
  abstract public void setValue(int value);
}

class LightSensor extends Sensor  
{
  private String name;
  private int value;
  
  public LightSensor(String name)
  {
    this.name = name;
    this.value = 0;
  }
  
  public LightSensor(String name, int value)
  {
    this.name = name;
    this.value = value;
  }  
    
  
  public int getValue()
  {
    return this.value;
  }
  
  public void setValue(int value)
  {
    this.value = value;
  }
  
  public void setName(String name)
  {
    this.name = name;
  }
  
  public String getName()
  {
    return this.name;
  }
}

class TemperatureSensor extends Sensor  
{
  private String name;
  private int value;
  
  public TemperatureSensor(String name)
  {
    this.name = name;
    this.value = 0;
  }
  
  public TemperatureSensor(String name, int value)
  {
    this.name = name;
    this.value = value;
  }  
  
  public int getValue()
  {
    return this.value;
  }
  
  public void setValue(int value)
  {
    this.value = value;
  }
  
  public void setName(String name)
  {
    this.name = name;
  }
  
  public String getName()
  {
    return this.name;
  }
}

class Controller  
{
  private int addr;
  private ArrayList<Actuator> actuators;
  private ArrayList<Sensor> sensors;
  
  //constructor
  public Controller(int addr)
  {
    actuators = new ArrayList<Actuator>();
    sensors = new ArrayList<Sensor>();
    this.addr = addr;
  }
  
  public Controller(int addr, ArrayList actuators, ArrayList sensors)
  { 
    actuators = new ArrayList<Actuator>();
    sensors = new ArrayList<Sensor>();
    this.addr = addr;
    this.actuators = actuators;
    this.sensors = sensors;
  }
  
  public void addActuator(Actuator actuator_)
  {
    this.actuators.add(actuator_);
  }
  
  public void addSensor(Sensor sensor_)
  {
    this.sensors.add(sensor_);
  }
  
  public ArrayList<Actuator> getActuators()
  {
    return this.actuators;
  }
  
  public ArrayList<Sensor> getSensors()
  {
    return this.sensors;
  }
  
  public void setActuators(ArrayList<Actuator> actuators)
  {
    this.actuators = actuators;
  }
  
  public void setSensors(ArrayList<Sensor> sensors)
  {
    this.sensors = sensors;
  }
    
  public void setAddr(int value)
  {
    this.addr = addr;
  }
  
  public int getAddr()
  {
    return this.addr;
  }
}

class House  
{
  private ArrayList<Controller> controllers;
  
  House(ArrayList<Controller> controllers)
  {
    this.controllers = controllers;
  }
  
  public ArrayList<Controller> getControllers()
  {
    return this.controllers;
  }
  
  public House clone()
  {
   House house_clone = null;
    
   ArrayList<Controller> controllers_ = this.getControllers();
   ArrayList<Controller> controllers_clone = new ArrayList<Controller>();
   
   if(controllers_ != null)
   {
     Controller controller_ = null;
     Controller controller_clone = null; 
     
     for(int y = 0; y<controllers_.size(); y++)
     {
       controller_ = controllers_.get(y);
       controller_clone = new Controller(controller_.getAddr());
       

       ArrayList<Actuator> actuators_ = controller_.getActuators();     
       ArrayList<Sensor> sensors_ = controller_.getSensors();
       
       ArrayList<Actuator> actuators_clone = new ArrayList<Actuator>();     
       ArrayList<Sensor> sensors_clone = new ArrayList<Sensor>();
       
       for(int k = 0; k<actuators_.size(); k++)
       {
         Actuator act = actuators_.get(k);
         String kind = "";
         if(act instanceof AnalogLightActuator)// kind="LPWM"; 
         {
           AnalogLightActuator ala =  new AnalogLightActuator(act.getName(), act.getValue());
           actuators_clone.add(ala);
         }
         if(act instanceof DigitalLightActuator)// kind="LDIG";  
         {
           DigitalLightActuator dla = new DigitalLightActuator(act.getName(), act.getValue());
           actuators_clone.add(dla);
         }
       }
       
       for(int j = 0; j<sensors_.size(); j++)
       {
         Sensor sens = sensors_.get(j);
         String kind = "";
         if(sens instanceof LightSensor)// kind="LSENS";  
         {
           LightSensor ls = new LightSensor(sens.getName(), sens.getValue());
           sensors_clone.add(ls);
         }
         if(sens instanceof TemperatureSensor)// kind="TSENS"; 
         {
           TemperatureSensor ts = new TemperatureSensor(sens.getName(), sens.getValue());
           sensors_clone.add(ts);
         }
         
       }
       
       controller_clone.setActuators(actuators_clone);
       controller_clone.setSensors(sensors_clone);
       controllers_clone.add(controller_clone);
     }
   }
    return new House(controllers_clone);
  }


}

/*
* set actuator value
*/
void setActuatorValue(House house,String name,int value)
{
  if(house != null)
  {    
   ArrayList<Controller> controllers_ = house.getControllers();
   
   if(controllers_ != null)
   {
     Controller controller_ = null;
     
     for(int y = 0; y<controllers_.size(); y++)
     {
       controller_ = controllers_.get(y);
       
       ArrayList<Actuator> actuators_ = controller_.getActuators();
         
       for(int k = 0; k<actuators_.size(); k++)
       {
         Actuator act = actuators_.get(k);
         
         if(act instanceof AnalogLightActuator && name.equals(act.getName())) 
         {
          act.setValue(value);
          //run command over serial.. using I2C
          sendSerialMsg(port, "CMD SET "+controller_.getAddr()+","+act.getName()+","+value);
         } 
         if(act instanceof DigitalLightActuator && name.equals(act.getName())) 
         {
          act.setValue(value);
          //run command over serial.. using I2C
          sendSerialMsg(port, "CMD SET "+controller_.getAddr()+","+act.getName()+","+value); 
         }
         delay(20);
       }
       
     }
   }
   else
      {
        if(debug) System.out.println("controllers_ is null!");
      } 
   
  }
  else 
  {
    if(debug) System.out.println("house reference is null!");
  } 
  
}

/*
* lookup actuator value
*/
int lookupActuatorValue(House house_stored,String name)
{
  if(house != null)
  {    
   ArrayList<Controller> controllers_ = house.getControllers();
   
   if(controllers_ != null)
   {
     Controller controller_ = null;
     
     for(int y = 0; y<controllers_.size(); y++)
     {
       controller_ = controllers_.get(y);
       
       ArrayList<Actuator> actuators_ = controller_.getActuators();
         
       for(int k = 0; k<actuators_.size(); k++)
       {
         Actuator act = actuators_.get(k);
         
         if(act instanceof AnalogLightActuator && name.equals(act.getName())) return act.getValue();
         if(act instanceof DigitalLightActuator && name.equals(act.getName())) return act.getValue(); 
       }
       
     }
   }
   else
      {
        if(debug) System.out.println("controllers_ is null!");
      } 
   
  }
  else 
  {
    if(debug) System.out.println("house reference is null!");
  } 
  return 0;
}
 
 

/*
* print the house to console
*/
public void printHouse(House house)
{
  if(house != null)
  {
   System.out.println("house model"); 
    
   ArrayList<Controller> controllers_ = house.getControllers();
   
   if(controllers_ != null)
   {
     Controller controller_ = null;
     
     for(int y = 0; y<controllers_.size(); y++)
     {
       controller_ = controllers_.get(y);
       
       System.out.println("  controller addr: "+controller_.getAddr());
       
       ArrayList<Actuator> actuators_ = controller_.getActuators();
       ArrayList<Sensor> sensors_ = controller_.getSensors();
       
       for(int k = 0; k<actuators_.size(); k++)
       {
         Actuator act = actuators_.get(k);
         String kind = "";
         if(act instanceof AnalogLightActuator) kind="LPWM"; 
         if(act instanceof DigitalLightActuator) kind="LDIG";  
         System.out.println("    actuator: "+act.getName()+"  kind: "+kind+"  value: "+act.getValue());
       }
       
       for(int j = 0; j<sensors_.size(); j++)
       {
         Sensor sens = sensors_.get(j);
         String kind = "";
         if(sens instanceof LightSensor) kind="LSENS";  
         if(sens instanceof TemperatureSensor) kind="TSENS"; 
         System.out.println("    actuator: "+sens.getName()+"  kind: "+kind+"  value: "+sens.getValue());
       }
     }
   }
   else
      {
        System.out.println("controllers_ is null!");
      } 
   
  }
  else 
  {
    System.out.println("house reference is null!");
  } 
}

/*
* update house state
*/
void updateHouseState(House house_)
{
  if(house_ !=null)
  {
  
   for(Map.Entry me : cp5_controllers.entrySet()) 
   {
     //println(me.getKey()+" : "+me.getValue());
     if(!simulate_cmd_sending) setActuatorValue(house_,me.getKey().toString(),(new Integer(me.getValue().toString()).intValue()));
   }
  }
}

/*
* reset house state
*/
void resetHouseState(House house_)
{
  if(house_ !=null)
  {
  
   for(Map.Entry me : cp5_controllers.entrySet()) 
   {
     //println(me.getKey()+" : "+me.getValue());
     setActuatorValue(house_,me.getKey().toString(),0);
     cp5.getController(me.getKey().toString()).setValue(0);
   }
  }
}

/*
* build the object model of the house, with controllers, actuators and sensors..
* returns the house reference
*/
House loadHouseModel(String str)
{
  //System.out.println(str);

/*  
Found slave controller: 10 (0x0A)
List devices for SLAVE 0x0A
device #0 : LIVING_ROOM LPWM
device #1 : PATIO LDIG
device #2 : SENSOR_1 LSENS
Found slave controller: 11 (0x0B)
List devices for SLAVE 0x0B
device #0 : BEDROOM_1 LPWM
device #1 : BATHROOM_1 LPWM
device #2 : SENSOR_1 TSENS
Found slave controller: 12 (0x0C)
List devices for SLAVE 0x0C
device #0 : BEDROOM_2 LPWM
device #1 : BATHROOM_2 LDIG
Found slave controller: 13 (0x0D)
List devices for SLAVE 0x0D
device #0 : LOBBY LPWM
device #1 : KITCHEN LPWM
device #2 : MICROWAVE_OVEN LDIG
*/

  House house = null;
  ArrayList<Controller> controllers = new ArrayList<Controller>(); 
  
  ///build the house..
  
  String[] list = split(str, '\n');
  String strx = "";
  
  int found_controller = -1;
  int addr = 0;
  Controller controller_ = null;
  
  for(int y=0; y<list.length; y++)
  {
    if(list[y]!="") 
    {
      strx = list[y];   
      
      if(strx.startsWith("Found slave controller: ")) //check if starts with "Found slave controller: "
      {
       

        found_controller++;
        //get the address of device
        String[] q = splitTokens(strx); //split on spaces.. #3 is the address
        addr = int(q[3]);
        
        controller_ = new Controller(addr);
        controllers.add(controller_); //save controller reference into array
                
        //System.out.println("addr: "+addr); //debug only
      }
      else if(strx.startsWith("List devices for SLAVE")) //skip this line
      {
        //do nothing
      }
      else if(strx.startsWith("device #")) //it's a device: actuator or sensor
      {
        String[] b = splitTokens(strx); // #3 is the name (unique) and #4 is the kind
        String name = b[3];
        String kind = b[4];
        
        //System.out.println("device name: "+name+" kind: "+kind); //debug only
        
        if(kind.equals("LPWM")) //it's an analog actuator..
        {
          if(house_stored == null)
          {
           controller_.addActuator(new AnalogLightActuator(name,0));
          }
          else 
             {
               controller_.addActuator(new AnalogLightActuator(name,lookupActuatorValue(house_stored,name)));
             }
        }
        if(kind.equals("LDIG")) //it's a digital actuator
        {
          if(house_stored == null)
          {
           controller_.addActuator(new DigitalLightActuator(name,0));
          }
          else 
             {
               controller_.addActuator(new DigitalLightActuator(name,lookupActuatorValue(house_stored,name)));
             } 
        }
        if(kind.equals("LSENS")) //it's a light sensor
        {
         //read sensor value.. 
         sendSerialMsg(port, "CMD GET "+controller_.getAddr()+","+name+",LSENS");

         strx = trim(awaitSerialMsgUntil(port, '-'));           
         String[] list_strx = split(strx," ");
        
         int value_s = parseInt(list_strx[0]);

         controller_.addSensor(new LightSensor(name,value_s));
        }
        if(kind.equals("TSENS")) //it's a temperature sensor
        {         
         //read sensor value.. 
         sendSerialMsg(port, "CMD GET "+controller_.getAddr()+","+name+",TSENS");

         strx = trim(awaitSerialMsgUntil(port, '-'));           
         String[] list_strx = split(strx," ");
        
         int value_s = parseInt(list_strx[0]);
          
          controller_.addSensor(new TemperatureSensor(name,value_s));
        }
      }
    }
    
    //System.out.println(": "+list[y]);
  }
  
  //create the house model..
  house = new House(controllers); 
  
  //check if all ok
  if(debug) printHouse(house);
 
  //ret it
  return house;
}

///////////////////////////CONSOLE//////////////////////////////////

/*
* to print messages on virtual console in the frame..
*/
void console_println(String str)
{     
       System.out.println(str); 
}  

//////////////////////////////LOGGING///////////////////////////////

void log(String filePath, String data)
{
  PrintWriter pw = null;
  try
  {
    pw = new PrintWriter(new BufferedWriter(new FileWriter(filePath, true))); // true means: "append"
   
    pw.println(data);
   
  }
  catch (IOException e)
  {
    // Report problem or handle it
    if(debug) e.printStackTrace();
  }
  finally
  {
    if (pw != null)
    {
      pw.close();
    }
  }
}


//////////////////////////////SERIAL////////////////////////////////

String awaitSerialMsgUntil(Serial port, char until)
{
  delay(100); //avoids out of sync on serial exchanges
  String serial_incoming_msg;
  start_time = millis();
  boolean arrived = false;
  while(!arrived && ((millis()-start_time)<serial_timeout))
  {
  if ( port.available() > 0) // if serial data are available,
     {  
       /* read from serial */
       serial_incoming_msg = port.readStringUntil(until); // read it and store in variable
       if(serial_incoming_msg!=null) return serial_incoming_msg.substring(0, serial_incoming_msg.length()-1); //remove trailing char and returns it
     }  
  }   
  console_println("WAIT TILL '"+until+"' : timed out.. restarting");
  return "timeout";
}

String awaitSerialMsg(Serial port, String expected)
{
  String serial_incoming_msg;
  start_time = millis();
  boolean arrived = false;
  while(!arrived && ((millis()-start_time)<serial_timeout))
  {
  if ( port.available() > 0) // if serial data are available,
     {  
       /* read from serial */
       serial_incoming_msg = port.readStringUntil('\n'); // read it and store in variable
      
       if(serial_incoming_msg!=null)
       {
         serial_incoming_msg =  serial_incoming_msg.substring( 0, serial_incoming_msg.length()-2 ); //trim cr/lf
         
         if(serial_incoming_msg.equals(expected)) 
         {
             console_println("PS app received : "+serial_incoming_msg);
             arrived = true;
             return serial_incoming_msg;
         }
       }  
     }  
  }   
  console_println("WAIT FOR '"+expected+"' : timed out.. restarting");
  return "timeout";
}

String awaitSerialMsgAlt(Serial port, String expected1, String expected2, String expected3)
{
  String serial_incoming_msg;
  start_time = millis();
  boolean arrived = false;
  while(!arrived && ((millis()-start_time)<serial_timeout))
  {
  if ( port.available() > 0) // if serial data are available,
     {  
       /* read from serial */
       serial_incoming_msg = port.readStringUntil('\n'); // read it and store in variable
       
       if(serial_incoming_msg!=null)
       {
         serial_incoming_msg =  serial_incoming_msg.substring( 0, serial_incoming_msg.length()-2 ); //trim cr/lf
         
       
         if(serial_incoming_msg.equals(expected1) || serial_incoming_msg.equals(expected2) || serial_incoming_msg.equals(expected3) ) 
         {
             console_println("PS app received : "+serial_incoming_msg);
             arrived = true;
             return serial_incoming_msg;
         }
       }
     }
  }   
  console_println("WAIT FOR '"+expected1+"/"+expected2+"/"+expected3+"' : timed out.. restarting");
  return "timeout";
}

void sendSerialMsg(Serial port, String serial_outgoing_msg)
{
  if(debug && serial_outgoing_msg.indexOf("GET")<0) 
  console_println("PS app sending  : "+serial_outgoing_msg);
  
  port.write(serial_outgoing_msg+"\n"); //append newline char at the end
}


/////////////////////////////////////////////////////////////////////////////

public ArrayList<Group> createControlGroups(String controller_1, String controller_2, String controller_3, String controller_4)
{
  //clean up
  if(cp5.getGroup(controller_1)!=null) cp5.getGroup(controller_1).remove();
  if(cp5.getGroup(controller_2)!=null) cp5.getGroup(controller_2).remove();
  if(cp5.getGroup(controller_3)!=null) cp5.getGroup(controller_3).remove();
  if(cp5.getGroup(controller_4)!=null) cp5.getGroup(controller_4).remove();

  
  ArrayList<Group> group = new ArrayList<Group>(); 
  
  if(!controller_1.equals("") && cp5.getGroup(controller_1)==null)
  {
   Group g1 = cp5.addGroup(controller_1)
                .setPosition(4,14)
                .setWidth(480)
                .setBackgroundHeight(280)
                .setBackgroundColor(color(255,50))
                ;
   group.add(g1);
  } 
                
  if(!controller_2.equals("") && cp5.getGroup(controller_2)==null)
  {
   Group g2 = cp5.addGroup(controller_2)             
                .setPosition(490,14)
                .setWidth(480)
                .setBackgroundHeight(280)
                .setBackgroundColor(color(255,50))
                ;
   group.add(g2);
  } 
                
  if(!controller_3.equals("") && cp5.getGroup(controller_3)==null)
  {
   Group g3 = cp5.addGroup(controller_3)             
                .setPosition(4,308)
                .setWidth(480)
                .setBackgroundHeight(280)
                .setBackgroundColor(color(255,50))
                ;
   group.add(g3);
  }  
                
  if(!controller_4.equals("") && cp5.getGroup(controller_4)==null)
  {
   Group g4 = cp5.addGroup(controller_4)             
                .setPosition(490,308)
                .setWidth(480)
                .setBackgroundHeight(280)
                .setBackgroundColor(color(255,50))
                ;
   group.add(g4);
  }  
 
 return group;                
}

void storeControllersValues()
{
  Iterator iterator = cp5_controllers.entrySet().iterator();
  while (iterator.hasNext()) 
  {
    Map.Entry mapEntry = (Map.Entry) iterator.next();
    
      
     cp5_controllers.put(mapEntry.getKey().toString(), (int)(cp5.getController(mapEntry.getKey().toString()).getValue())); 
  }
  /*
  for (Map.Entry me : cp5_controllers.entrySet()) 
  {
   cp5_controllers.put(me.getKey().toString(), new Integer(cp5.getController(me.getKey().toString()).getValue())); 
  }
  */
}

void printControllersValues()
{
  println("\ncontrollers values");
  for (Map.Entry me : cp5_controllers.entrySet()) 
  {
    println(me.getKey()+" : "+me.getValue());
  }
}

void controlEvent(ControlEvent theEvent) {
  if(theEvent.isGroup()) {
    /*
    println("got an event from group "
            +theEvent.getGroup().getName()
            +", isOpen? "+theEvent.getGroup().isOpen()
            );*/
            
  } else if (theEvent.isController()){
    /*
    println("got something from a controller "
            +theEvent.getController().getName()
            );*/
            
   if(theEvent.controller().name()=="SYNC") 
   {
     sync();             
   }         
    
    if(theEvent.controller().name()=="RESET") 
    {
     reset();              
    }      
 
 
  }
}

void sync()
{
  println("event: SYNC");
                 
  storeControllersValues();
  
  //printControllersValues();
  //send commands
  updateHouseState(house);
  
  //store the house model
  house_stored = house.clone(); 
  
  println("\n\n");  
  //read from bus, the sensors etc  
  house = scanBusForModel();
  
  //display stuff and values in controllers 
  //2. create the controllers and groups into the interface.. using the house model
  createInterfaceControls(cp5, house);

}

void reset()
{
  println("event: RESET");
                     
  storeControllersValues();
  
  //printControllersValues();
  //send commands
  resetHouseState(house);
  
  //store the house model
  house_stored = house.clone(); 
  
  println("\n\n");  
  //read from bus, the sensors etc  
  house = scanBusForModel();
      
  //display stuff and values in controllers 
  //2. create the controllers and groups into the interface.. using the house model
  createInterfaceControls(cp5, house);

}

/*
* remove controllers and groups from the frame
*/
void cleanWindow(ControlP5 cp5)
{
  if(cp5 != null)
  {
   if(cp5_controllers != null)
   {
     for(Map.Entry me : cp5_controllers.entrySet()) 
     {
       //println(me.getKey()+" : "+me.getValue());
       cp5.remove(cp5.getController(me.getKey().toString()));
     }
   }
   
   if(house_stored!=null)
   {
   ArrayList<Controller> controllers_ = house_stored.getControllers();  
   
     if(controllers_ != null)
     {
      Iterator<Controller> itr = controllers_.iterator();
      while (itr.hasNext()) 
      { 
        Controller element = itr.next(); 
        cp5.remove("CONTROLLER_"+element.getAddr()); 
      }
     } 
   } 
  }
}

//testing controlP5
void keyPressed() {
  /*
  if(key=='r') {
    if(cp5.getGroup("CONTROLLER_12")!=null) {
      cp5.getGroup("CONTROLLER_12").remove();
    }
    if(cp5.getGroup("CONTROLLER_10")!=null) {
      cp5.getGroup("CONTROLLER_10").remove();
    }
  }
  if(key=='a') {
    
    createControlGroups("CONTROLLER_10", "CONTROLLER_11", "CONTROLLER_12", "CONTROLLER_13" );
    
  }
  */
  if(key=='s') 
  {
    sync();
  }
  if(key=='r') 
  {    
   reset();  
  }
}

/////////////////////////////////////////////////////////////////////////////

/*
* this method send the scan bus command to read the house model from I2C slave devices aka controllers
* @return house obj model
*/
public House scanBusForModel()
{
  sendSerialMsg(port, "CMD SCAN BUS");      
  String str = awaitSerialMsgUntil(port, '-');
          
  return loadHouseModel(str);
}  

/*
* this method creates the interface components (groups, controllers, sliders etc) using the house model informations
*/
public void createInterfaceControls(ControlP5 cp5, House house)
{ 
  if(house != null)
  {    
   cleanWindow(cp5); 
    
   cp5_controllers = new HashMap<String,Integer>(); //build a new map.. 
    
   ArrayList<Controller> controllers_ = house.getControllers();
   Controller _controller;   
   ArrayList<String> controllers_names = new ArrayList<String>(); 
   
    String controller_1 = "";
    String controller_2 = "";
    String controller_3 = "";
    String controller_4 = "";
   
   for(int y = 0; y<controllers_.size(); y++)
     {
       _controller = controllers_.get(y);
       controllers_names.add("CONTROLLER_"+controllers_.get(y).getAddr());
     } 
    
   if(controllers_.size()>0) controller_1 = controllers_names.get(0);
   if(controllers_.size()>1) controller_2 = controllers_names.get(1);
   if(controllers_.size()>2) controller_3 = controllers_names.get(2);
   if(controllers_.size()>3) controller_4 = controllers_names.get(3); 
   
   createControlGroups(controller_1,controller_2,controller_3,controller_4);
   
   
   if(controllers_ != null)
   {
     Controller controller_ = null;
     
     for(int y = 0; y<controllers_.size(); y++)
     {
       controller_ = controllers_.get(y);
       
       //System.out.println("  controller addr: "+controller_.getAddr());
       
       ArrayList<Actuator> actuators_ = controller_.getActuators();
       ArrayList<Sensor> sensors_ = controller_.getSensors();
       
       int k_at_exit = 0;
       
       for(int k = 0; k<actuators_.size(); k++)
       {
         k_at_exit = k+1;
         Actuator act = actuators_.get(k);
         String kind = "";
         if(act instanceof AnalogLightActuator) //kind="LPWM" 
         {          
           cp5.addSlider(act.getName())
           .setRange(0,255)
           .setDecimalPrecision(0)
           .setValue(act.getValue())
           .setPosition(20,20+50*k)
           .setSize(300,30)
           .setWidth(350)
           .setLabel(act.getName())
           .setGroup(cp5.getGroup(controllers_names.get(y)))
           .getCaptionLabel()
           .setFont(pfont)
           .toUpperCase(false)
           .setSize(13)
           ;
           
           cp5_controllers.put(act.getName(), act.getValue());
         }
         if(act instanceof DigitalLightActuator) //kind="LDIG"  
         {
           // parameters  : name, default value (boolean), x, y, width, height
           boolean value_ = false;
           if(int(act.getValue())!=0) value_= true;
           
           cp5.addToggle(act.getName(),value_,20,20+50*k,200,30)
           .setValue(act.getValue())
           .setGroup(cp5.getGroup(controllers_names.get(y)))
           .setLabel(act.getName())
           .getCaptionLabel()
           .setFont(pfont)
           .toUpperCase(false)
           .setSize(13)       
           ;
           
           cp5_controllers.put(act.getName(), act.getValue());
         }       
         
         //System.out.println("    actuator: "+act.getName()+"  kind: "+kind+"  value: "+act.getValue());
       }
       
       for(int j = 0; j<sensors_.size(); j++)
       {
         Sensor sens = sensors_.get(j);
         String kind = "";
         if(sens instanceof LightSensor) //kind="LSENS"
         {
           // parameters : name, default value (float), x, y,  width, height
           
           //lux calculation
           float lux = 100*(0.0048828125*sens.getValue());
           
           //cp5.addNumberbox(sens.getName(),sens.getValue(),20,20+100*(j+k_at_exit),50,30)
           cp5.addNumberbox(sens.getName()+" light[Lux]",lux,20,20+100*(j+k_at_exit),50,30)
           .setGroup(cp5.getGroup(controllers_names.get(y)))
           .setLabel(sens.getName()+" light[Lux]")
           .getCaptionLabel()
           .setFont(pfont)
           .toUpperCase(false)
           .setSize(13);
         }
         if(sens instanceof TemperatureSensor) //kind="TSENS"
         {
           //temperature calculation
           float temperature = ((sens.getValue()-277)-273); //277 is the offset due to components and voltage tolerance, 273 is the scale factor form °K to °C
           
           //cp5.addNumberbox(sens.getName(),sens.getValue(),20,20+100*(j+k_at_exit),50,30)
           cp5.addNumberbox(sens.getName()+" temp[celsius]",temperature,20,20+100*(j+k_at_exit),50,30)
           .setGroup(cp5.getGroup(controllers_names.get(y)))
           .setLabel(sens.getName()+" temp[celsius]")
           .getCaptionLabel()
           .setFont(pfont)
           .toUpperCase(false)
           .setSize(13);
         }
         //System.out.println("    actuator: "+sens.getName()+"  kind: "+kind+"  value: "+sens.getValue());
       }
     }
   }
   else
      {
        System.out.println("controllers_ is null!");
      } 

  }
  else 
  {
    System.out.println("house reference is null!");
  } 
 
}
 
////////////////////////////////MAIN CONTROL////////////////////////////////////// 

    void control()
    {         
 
        //simple header
        String timestamp = year() + nf(month(),2) + nf(day(),2) + "-"  + nf(hour(),2) + nf(minute(),2) + nf(second(),2);
        console_println("\n\nPS Application l: execution at "+timestamp); 
        console_println("_____________________________________________________\n"); 
        
        //update counter
        loop_number++;
         
        String str = ""; 
        //now start the protocol phase
        
        signaling_color = color(0,255,0);
        
        delay(5000);
        
        //1. SCAN BUS (so find controllers and devices..)
        //read data from teh bus and create the model of the house..
        house = scanBusForModel();
        
        //2. create the controllers and groups into the interface.. using the house model
        createInterfaceControls(cp5, house);
    }
    

void setup()
{
  size(976,665);
  smooth();
  
  background(0);
  
      
  cp5 = new ControlP5(this);
 
  ControlFont font = new ControlFont(pfont,30);
  
  cp5.addBang("SYNC")
     .setPosition(20,609)
     .setColorActive(color(255,0,0)) 
     .setColorForeground(color(0,255,0))
     .setSize(200,35)
     ;      

  cp5.getController("SYNC")
   .getCaptionLabel()
   .setFont(font)
   .toUpperCase(false)
   .setSize(13)
   ;    
  
  cp5.addBang("RESET")
     .setPosition(300,609)
     .setColorActive(color(255,0,0)) 
     .setColorForeground(color(0,255,0))
     .setSize(200,35)
     ;      

  cp5.getController("RESET")
   .getCaptionLabel()
   .setFont(font)
   .toUpperCase(false)
   .setSize(13)
   ;    
   

  //String portName = Serial.list()[0]; //change the 0 to a 1 or 2 etc. to match your port, port 0 is COM1 usually on windows
  //port = new Serial(this, portName, 9600); //set baud rate to 9600       
  port = new Serial(this, serial_port, baudrate); //set baud rate  
  
  control();
}

void draw() 
{
  background(0); 
}
