#ifndef PROJECT_H
#define PROJECT_H

//Message structure
typedef nx_struct project_msg{
	nx_uint16_t sender_id;
} project_msg_t;

//Constants
enum {
  AM_RADIO_COUNT_MSG = 6, FREQUENCY = 500
};

#endif