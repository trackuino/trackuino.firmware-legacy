/*
 *  debug.cpp
 *  trackuino
 *
 *  Created by javi on 19/03/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "debug.h"

#if 0
/* Snippet to read from serial buffer. Since gps.encode() may take
 * a while to process, we buffer enough data ahead to avoid serial
 * data loss */

const int GPS_SW_RX = 7;	// software-serial read from pin 7
const int GPS_SW_TX = 8;	// software-serial write to  pin 8
SoftwareSerial sw_serial(GPS_SW_RX, GPS_SW_TX);

// define pin modes for tx, rx
pinMode(GPS_SW_RX, INPUT);
pinMode(GPS_SW_TX, OUTPUT);

sw_serial.begin(9600);

int i;
unsigned char buffer[256];

valid_gps_data = 0;
while (! valid_gps_data) {
	for (i = 0; i < 256; i++) {
		buffer[i] = sw_serial.read();
	}
	for (i = 0; i < 256; i++) {
		if (gps.encode(buffer[i])) {
			valid_gps_data = 1;
			break;
		}
	}
}

#endif


#if 0
/* Another snippet to output the aprs frame to the serial port */
Serial.write("/");					// Report w/ timestamp, no APRS messaging. $ = NMEA raw data
Serial.write(gps.get_time());		// 170915h = 17h:09m:15s zulu (not allowed in Status Reports)
Serial.write(gps.get_lat());		// Lat: 38deg and 22.20 min (.20 are NOT seconds, but 1/100th of minutes)
Serial.write("/");					// Symbol table
Serial.write(gps.get_lon());		// Lon: 000deg and 25.80 min
Serial.write("O");					// Symbol: O=balloon, -=QTH
Serial.write(gps.get_course());
Serial.write("/");
Serial.write(gps.get_speed());		// Course and speed (degrees/knots)
Serial.write(						// Comment
			 "Prueba Trackuino 1200");
Serial.write("/A=");
Serial.write(gps.get_altitude());	// Altitude (feet). Goes anywhere in the comment area
Serial.println("");
#endif

#if 0
// Another snippet to test the modem
modem_test();
while (modem_busy()) { }
delay(200);
#endif
