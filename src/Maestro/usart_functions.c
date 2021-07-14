

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


