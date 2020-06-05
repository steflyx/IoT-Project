#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "Project.h"

configuration ProjectAppC {}
implementation {
	components MainC, ProjectC as App;
	components new AMSenderC(AM_RADIO_COUNT_MSG);
	components new AMReceiverC(AM_RADIO_COUNT_MSG);
	components new TimerMilliC() as Timer;
	components ActiveMessageC;
	components PrintfC;
  	components SerialStartC;
	
	App.Boot -> MainC.Boot;
	
	App.Receive -> AMReceiverC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.MilliTimer -> Timer;
	App.Packet -> AMSenderC;
}