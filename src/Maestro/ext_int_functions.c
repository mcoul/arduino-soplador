

void EI_Init(void)
{
	/* Enable Interrupt Pin INT0 */
	EIMSK=(1<<INT0);

	/* Set to trigger by low level of INT0*/
	EICRA=(0<<ISC01)|(0<<ISC00);

}
