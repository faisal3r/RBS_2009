#include "printf.h"
#include <UserButton.h>
module SNDC{
	uses interface Boot;
	uses interface SplitControl as radioControl;
	uses interface AMSend;
	uses interface Leds;
	uses interface Packet;
	uses interface Notify<button_state_t>;
	uses interface Timer<TMilli> as timer;
	uses interface Timer<TMilli> as timer2;
}

implementation{
	error_t ee;
	uint32_t beacon = 0xFF000000;
	message_t msg;
	uint32_t timeInSec;
	uint32_t hrs;
	uint32_t min;
	uint32_t sec;

	task void printTime();
	
	event void Boot.booted(){
		call radioControl.start();  //Starting the radio controller
		call Notify.enable();
		call timer.startPeriodic(1000);
	}

	event void radioControl.startDone(error_t e){
		//Do Nothing
	}

	event void radioControl.stopDone (error_t e){
		//Do nothing
	}

	event void Notify.notify( button_state_t state ) {
		if ( state == BUTTON_PRESSED ) {
			nx_uint32_t * myData = call AMSend.getPayload(&msg,4); //get a 3-byte payload pointer in msg
			* myData = beacon;	//edit the payload of "msg"
			call AMSend.send(AM_BROADCAST_ADDR, &msg, sizeof(*myData)); //send "msg"		
			call Leds.led2On();
		}
		else if ( state == BUTTON_RELEASED ) {
			call Leds.led2Off();
		}
	}
  
	event void AMSend.sendDone(message_t * msg, error_t e){
		if (e == SUCCESS)
			call Leds.led1On();
		else
			call Leds.led0On();
		call timer2.startPeriodic(1000);	// count 1 sec then turn off LED
	}
	
	event void timer.fired(){
		printf("Beacon = %lx\n",beacon);
		timeInSec = beacon-0xFF000000;
		post printTime();
		printf("Beacon ");
		printfflush();
		if(beacon>=0xFF015180)// 0x15180 = 86400 sec/day
			beacon=0xFF000000;//reset
		else
			beacon++;
	}
	
	event void timer2.fired(){
		call Leds.led0Off();
		call Leds.led1Off();
	}
	
	task void printTime(){
		hrs = timeInSec/3600;
		min = (timeInSec/60) - (hrs*60);
		sec = timeInSec - ((hrs*3600) +(min*60));
		
		printf("Time = %dh ",hrs);
		printf("%dm ",min);
		printf("%ds\n",sec);
	}
}