#include "printf.h"
module RCVC{
	uses interface SplitControl as radio;
	uses interface Receive;
	uses interface AMSend;
	uses interface Timer<TMilli> as timer;// for count incrementing every sec
	uses interface Timer<TMilli> as timer2;// for LEDs off only
	uses interface Leds;
	uses interface Boot;
}

implementation{
	uint32_t count=0; //86400 sec/day
	uint32_t timeInSec;
	uint32_t hrs;
	uint32_t min;
	uint32_t sec;
	uint32_t received;
	nx_uint32_t* receivedP;
	
	task void printTime();

	event void Boot.booted(){
		call radio.start();	//Starting the radio controller
		call timer.startPeriodic(1000);	// to increment count
	}
	
	event void timer.fired(){
		if(count>=86400) // seconds per day (24x60x60)
			count = 0;
		else
			count++;
		timeInSec = count;
		post printTime();
		printfflush();
	}
	
	event void timer2.fired(){
		call Leds.led0Off();
		call Leds.led1Off();
	}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){	
		message_t* dummyMsg;
		message_t* myMsg;	//new message to send
		nx_uint32_t * myTimer;
		receivedP = (nx_uint32_t*)payload;
		received = (uint32_t) *receivedP;
		
		if(received >= 0xFF000000) //message received is a broadcasted beacon ==> broadcast my timer
		{	
			printf("Broadcast beacon received from base station!\n");
			received = received - 0xFF000000;
			count = received;
			printf("Timer renewed!New local time:\n");
			timeInSec = count;
			post printTime();
			printfflush();
			
			myTimer = call AMSend.getPayload(myMsg,4); //create new msg and get a 4-byte payload pointer in it
			* myTimer = count;	//edit the payload of "newMsg"
			call AMSend.send(AM_BROADCAST_ADDR, myMsg, sizeof(*myTimer)); //broadcast "myMsg"
		}
		
		else	// message received is "timer" from another node ==> average all received times
		{
			printf("Timer received from other mote!\n");
			printfflush();			
			count = (count+(received))/2;
			printf("Timer renewed!New local time:\n");
			timeInSec = count;
			post printTime();
			printfflush();
			
		}
		return dummyMsg;
	}	
	task void printTime(){
		hrs = timeInSec/3600;
		min = (timeInSec/60) - (hrs*60);
		sec = timeInSec - ((hrs*3600) +(min*60));
		
		printf("Time = %dh ",hrs);
		printf("%dm ",min);
		printf("%ds\n",sec);
	}
	
	event void AMSend.sendDone(message_t * msg, error_t e){
		if (e == SUCCESS){
			call Leds.led1On();
			printf("LOCAL TIMER BROADCAST SUCCESS!\n");
		}
		else{
			call Leds.led0On();
			printf("LOCAL TIMER BROADCAST NOT SUCCESS!\n");
		}
		printfflush();
		call timer2.startPeriodic(1000);
	}
	
	event void radio.startDone(error_t e){
	//Do Nothing 
	}

	event void radio.stopDone (error_t e){	
	//Do nothing
	}
}