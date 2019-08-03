configuration RCVAppC{
}
implementation{
	components MainC;
	components new AMReceiverC(20);
	components new AMSenderC(20);
	components new TimerMilliC() as Timer;
	components LedsC;
	components RCVC;
	components ActiveMessageC;
	RCVC.Leds	->	LedsC;
	RCVC.Boot	->	MainC;
	RCVC.Receive->	AMReceiverC;
	RCVC.AMSend	->	AMSenderC;
	RCVC.timer	->	Timer;
	RCVC.timer2	->	Timer;
	RCVC.radio	->	ActiveMessageC;
}