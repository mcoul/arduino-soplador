

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
