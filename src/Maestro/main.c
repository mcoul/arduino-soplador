/********************************************************/
/*	Código fuente del microcontrolador maestro	*/
/*							*/
/*							*/
/*							*/
/********************************************************/

#include <avr/io.h>
#include <avr/interrupt.h>


/*
#include "types.h"
*/
typedef char * string;
typedef unsigned char uchar;

typedef enum {	NO_INPUT=0,
		SOPLIDOS_1=1,
		SOPLIDOS_2=2,
		SOPLIDOS_3=3,
		SUCCION_1=4} input_t;

typedef enum {	MESSAGE_IN_PROG,
		MESSAGE_ENDED,
		SUCCESS,
		FAILURE} status_t;
		


/* //////// DEFINES //////// */

#define MAIN_DELAY = 160;		/* Delay de 10 ms */
#define LED_ERROR_POS = 1;
#define LED_TEST = 2;
#define ADC_INPUT_PIN = 0;

#define FOSC 1843200	/* Clock Speed */
#define BAUD 9600 
#define MYUBRR FOSC/16/BAUD -1

/* ///////////////////////// */


/* //////// PROTOTYPES //////// */
void delay_100ms(void);

void ADC_Init(void);
void TIMER1_Init(void);
void EI_Init(void);
void USART_Init(unsigned int);

void TIMER1_Start(unsigned int);
void ISR_TIMER1(TIMER1_OVF_vect);

void USART_Transmit(unsigned char);
unsigned char USART_Receive(void);
/* //////////////////////////// */

#include "adc_functions.c"
#include "timer_functions.c"
#include "usart_functions.c"

/* //// GLOBAL ELEMENTS //// */
static input_t status_input;
/* ///////////////////////// */



int main (void)
{	
	unsigned char counter=0;	/* Un contador con uchar (de 0 a 255) */
	unsigned char array[]="1234";	/* Cómo hacer un arreglo/lista */
	unsigned int memory_loc=0xFFFF;	/* Para una posición de memoria */
	unsigned int time_counter=MAIN_DELAY;



/* ////// GENERAL CONFIG ////// */

	/* Setear puertos */
	DDRC=(0<<ADC_INPUT_PIN)|(1<<LED_ERROR_POS)|(1<<LED_TEST)|(1<<PC5);	/* Seteo como output a todo el puerto B */
	PORTC &= ~(1<<LED_ERROR_POS);	/* Apago el LED haciendo la máscara y un AND */

	ADC_Init();
	TIMER1_Init();
	
	/* Por ahora no se usa
 	EI_Init();
	*/

	/* No confio en la parametrización
	USART_Init(MYUBRR);
	*/
	USART_Init(103);

/* /////////////////////////// */

	delay_100ms();

	/* MAIN LOOP (Busco actividad)*/
	status_input=NO_INPUT;

	while(1)
	{
		sei();
		ADC_Start();

		if(status_input!=NO_INPUT)
		{
			cli();
			Actividad();
			Transmitir();
			status_input=NO_INPUT;
		}

	}

	return 0;

}


/* ////// FUNCTIONS ////// */

status_t Actividad(void)
{
	if(BUFFER_STATUS==MESSAGE_ENDED)
		return SUCCESS;




void delay_100ms(void)
{
	unsigned int i;

	for(i=0; i<(MAIN_DELAY*10); i++);

}

/* /////////////////////// */
