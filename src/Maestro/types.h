
#ifndef TYPES_H
#define TYPES_H

#include <stdio.h>


typedef char * string;
typedef unsigned char uchar;

typedef enum {	OK=0,
		ERROR_NULL_POINTER=1,
		ERROR_MEMORY=2,
		STATUS_NO_DOC=3,
		STATUS_EOF=4,
		ERROR_INVALID_NUMBER_ARGS=5,
		ERROR_INVALID_FILE=6,
		ERROR_INVALID_SORT_TYPE=7,
		ERROR_INVALID_COMMAND=8} status_t;

typedef enum  {	TRUE,
		FALSE}bool_t;	



/*
typedef enum {	DIRECTIVE_NAME=0,
		DIRECTIVE_PARAM=1,
		DIRECTIVE_RETURN=2,
		DIRECTIVE_NOTE=3} directive_t;

typedef enum {	SORT_BY_NAME=0,
		SORT_BY_PARAMS=1,
		SORT_BY_NONE=2}sort_t;
typedef status_t (*destructor_t)(void **);
typedef status_t (*printer_t)(void*,FILE *);
typedef bool_t (*comparator_t)(void*,void*);	  
typedef status_t (*sorter_t)(void*);

typedef status_t (*setter_t)(void*,void*);

*/




#endif


		
