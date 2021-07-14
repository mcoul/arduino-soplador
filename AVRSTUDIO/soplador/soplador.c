


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

/* En archivos */



void TIMER1_Init(void)
{
	/* Enable Timer interrupt */
	TIMSK1=(1<<TOIE1);

}


void TIMER1_Start(unsigned int mytime)
{
	/* Set Time */
	TCNT1L = (unsigned char) mytime;
	TNCT1H = (unsigned char) (mytime>>8);

	/* Set to normal mode */
	TCCR1A = (0<<WGM10)|(0<<WGM11);
	TCCR1B = (0<<WGM12)|(0<<WGM13);

	/* Select clock mode (clk_i/o / 1024) */
	TCCR1B = (5<<CS10);

}


void ISR_TIMER1(TIMER1_OVF_vect)
{
	extern status_t BUFFER_STATUS;

	BUFFER_STATUS=MESSAGE_ENDED;

}



void USART_Init(unsigned int ubrr)
{
	/* Set Baud Rate */
	UBRR0H = (unsigned char) (ubrr>>8);	/* Se castea a byte la parte alta del nibble */
	UBRR0L = (unsigned char) ubrr;		/* Idem parte baja */

	/* Enable receiver/trasmitter */
	UCSR0B = (1<<RXEN0)|(1<<TXEN0);
	/* Set frame format: 1 stop bit, 8-bit data */
	UCSR0C = (0<<USBS0)|(3<<UCSZ00);

}


void USART_Transmit(unsigned char data)
{
	/* Wait for empty transmit buffer */
	while(!(UCSR0A & (1<<UDRE)));

	/* Put data into buffer, sends the data */
	UDR0 = data;

}


unsigned char USART_Receive (void)
{
	/* Wait for data to be received */
	while(!(UCSR0A & (1<<RXC)));

	/* Get and return received data from buffer */
	return UDR0;

}



void EI_Init(void)
{
	/* Enable Interrupt Pin INT0 */
	EIMSK=(1<<INT0);

	/* Set to trigger by low level of INT0*/
	EICRA=(0<<ISC01)|(0<<ISC00);

}



void ADC_Init(void)
{
	/* Disable ADC, ADC Ext Int, set prescaler = 128 (Arduino's f=16MHz and need f<200kHz) */
	ADCSRA = (0<<ADEN)|(0<<ADIE)|(7<<ADPS0);

	/* Set extern ref, little indian and MUX=0 => ADC0 (PC0) */
	ADMUX = (0<<REFS1)|(1<<REFS0)|(0<<ADLAR)|(0<<MUX3)|(0<<MUX2)|(0<<MUX1)|(0<<MUX0);

}


void ADC_Start(void)
{
	/* Start ADC Convertion by setting ADSC */
	ADCSRA = (1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(7<<ADPS0);

}


/* /////////////////////// */
