#include "Timer.h"
#include "Project.h"
#include "printf.h"

#define MAX_ENCOUNTERED_NODES 10

module ProjectC @safe() {

	uses {
		interface Boot;
		interface Receive;
		interface AMSend;
		interface Timer<TMilli> as MilliTimer;
		interface SplitControl as AMControl;
		interface Packet;
	}

}

implementation{

	message_t packet;

	uint16_t node_id = 0;	
	
	//To store the ids already met
	uint16_t encountered_nodes[MAX_ENCOUNTERED_NODES];
	uint16_t num_encountered_nodes = 0;
	uint16_t index_encountered_nodes = 0;
	
	bool locked = FALSE;

	//Boot event
	event void Boot.booted(){
		call AMControl.start();
	}
	
	//Start event
	event void AMControl.startDone(error_t err){
		if (err == SUCCESS){
		
			//Node is initialized by Cooja
			node_id = TOS_NODE_ID;
			
			//We start a timer to broadcast the id
			call MilliTimer.startPeriodic(FREQUENCY);
			
		}
		else {
			call AMControl.start();
		}
	}
	
	//Stop event
	event void AMControl.stopDone(error_t err){
	
	}
	
	//Timer stops and mote sends a message with a random value between 0 and 100
	event void MilliTimer.fired(){
		if(locked) {
			return;
		}
		else{
		
			//Message preparation
			project_msg_t* pjm = (project_msg_t*)call Packet.getPayload(&packet, sizeof(project_msg_t));
			if (pjm == NULL){
				return;
			}
			
			//Broadcast its id
			pjm->sender_id = node_id;
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(project_msg_t)) == SUCCESS)
				locked = TRUE;
					
		}
	}
	
	//Message sent
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
   		if (&packet == bufPtr)
      		locked = FALSE;
  	}
	
	//A message is received
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len){
		if (len != sizeof(project_msg_t)) {return bufPtr;}
		else{	
		
			//Unpack message
			project_msg_t* pjm = (project_msg_t*)payload;
			
			//Check if the id was already stored
			bool new_node = TRUE;
			uint16_t i = 0;
			while (i<num_encountered_nodes){
				if(encountered_nodes[i] == pjm->sender_id){
					new_node = FALSE;
				}
				i++;
			}
			
			//If the sender id wasn't already stored, store it and print a message
			if (new_node == TRUE){
			
				//Store the id
				encountered_nodes[index_encountered_nodes] = pjm->sender_id;
				
				//Update the index and the number of encountered nodes (we collect
				//maximum 10 nodes, then we overwrite the oldest ones)
				index_encountered_nodes = (index_encountered_nodes + 1) % MAX_ENCOUNTERED_NODES;
				num_encountered_nodes += (num_encountered_nodes != MAX_ENCOUNTERED_NODES);
								
				//Print the received id (to avoid double messages, only print if node_id > sender_id
				if(node_id > pjm->sender_id){
					printf("{sender_id: %u, node_id:%u}\n",pjm->sender_id,node_id);
					printfflush();
				}
			
			}		
				
			return bufPtr;
		}
	}

}