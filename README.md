# smarthome_arduino

this is the repository for smarthome/homeautomation & arduino demo 

the files included are:

1. the pc-app that is a processing sketch with java code embedded to control the house model (lamps) and interact with the Arduino Uno v. R3 master via USB/Serial (UART)

2. the Arduino Uno master code, that is an Arduino sketch, that contains all the code to interact with pc-app via USB and with controllers over I2C bus & protocol

3. four Arduino sketches for the 4 ATMEGA328P controllers, for controlling devices, means setting values of actuators and reading values from sensors; these programs interface via I2C protocol and messages the master code, execute commands and returns informations (e.g. values from sensors)

To run the examples you need an Arduino Uno connected to a PC with Processing + at least one ATMEGA328P programmed as controller + some hardware to connect at the controller(s)

This repository was created for Pervasive Systems 2016 course at University of Rome la Sapienza - DIAG

Homepage of the course:
http://ichatz.me/index.php/Site/PervasiveSystems2016
