

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

