configuration SNDAppC{
}
implementation {
	components MainC, LedsC, SNDC;
	components ActiveMessageC;
	components new AMSenderC(20);
	components UserButtonC;
	components new TimerMilliC() as Timer;
	SNDC.Leds	->	LedsC;
	SNDC.Boot	->	MainC;
	SNDC.AMSend	->	AMSenderC;
	SNDC.radioControl-> ActiveMessageC;
	SNDC.Packet	->	AMSenderC;
	SNDC.Notify ->	UserButtonC;
	SNDC.timer	->	Timer;
	SNDC.timer2	->	Timer;
}