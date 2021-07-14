;***********************************************************************;
;				Codigo para el micro maestro
;Proyecto: Soplador
;************************************************************************;

.include "m328pdef.inc"


;Equivalencias
				.equ BRl = 103
				.equ BRh = 0
				.equ Soplo_1_vez = 1
				.equ Soplo_2_veces = 2
				.equ Soplo_3_veces=3
				.equ Succiono_1_vez = 4
				.equ bit_pedal_1 = 0
				.equ bit_pedal_2 = 1
				.equ bit_succion = 2
				.equ Max_soplidos= 3
				.equ Umbral_soplido_l = 255
				.equ Umbral_soplido_h = 1
				.equ Umbral_succion_l = 51 
				.equ Umbral_succion_h = 1 
				.equ LED_ERROR = 1
				.equ Timerl = 190
				.equ Timerh = 215

				.equ	NUM_LOOP1 = 100;	
				.equ	NUM_LOOP2 = 48

;Definiciones
				.def aux = r16
				.def cnt_soplidos = r17
				.def flag = r18
				.def Dato_ON_OFF = r19
				.def Dato_PEDAL = r20
				.def Dato_EXOR = r21
				.def ON_OFF_P1 = r28
				.def ON_OFF_P2 = r23
				.def ON_OFF_P3 = r24
				.def cnt = r25
				.def flag2 = r26
				.def aux1=r27
				

;Inicio del codigo
				.org 0x0000
				jmp Inicio
				
;Interrupciones
				.org INT0addr
				jmp Int_config
				.org ADCCaddr			; ADCCaddr tiene el valor de la posicion de la interrupciones del ADC
				jmp Int_ADC
				.org OVF1addr			; OVF1addr tiene el valor de la posicion de la interrupcion de overflow de Timer1
				jmp Int_TIMER1

;Inicio del main				
				.org INT_VECTORS_SIZE
Inicio:
;*************Inicializacion del stack pointer*************;
				ldi aux,low(RAMEND)
				out spl,aux
				ldi aux,high(RAMEND)
				out sph,aux
;***********************************************************;

;*****************Configuraciones generales*****************;
				rcall INIC_PORT
				rcall INIC_USART
				rcall INIC_ADC
				rcall INIC_TIMER1
				rcall INIC_CONFIG
;***********************************************************;
				ldi cnt_soplidos,0
				ldi flag,0
				ldi flag2,0
				ldi ON_OFF_P1,0
				ldi ON_OFF_P2,0
				ldi ON_OFF_P3,0
;**************************Cuerpo***************************;

				ldi aux,(0<<INT0)
				out EIMSK,aux
Busco_actividad:		
				sei
				ldi aux,(1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)			;Seteo el pin (ADEN) del reg: ADCSRA para habilitar el ADC
				sts ADCSRA,aux																	;Seteo el pin (ADSC) del reg: ADCSRA para empezar la conversion	
				
				cpi cnt_soplidos,0																;Si cnt_soplidos es 0 => no se llegaron a los umbrales de soplido o succion
				brne Hubo_actividad
				jmp Busco_actividad													

Hubo_actividad:
				cli
				cpi cnt_soplidos,Max_soplidos					;Comparo con Max_soplidos=3 ya que o se hizo 3 soplidos o succion=4
				brsh Salto_espera
				
				ldi flag2,0
				
				;Activo el timer 1 (Hay que ajustar TCNT1L y TCNT1H para que sean 300 ms)
				ldi aux,Timerl
				sts TCNT1L,aux
				ldi aux,Timerh
				sts TCNT1H,aux
				ldi aux,(0<<WGM11)|(0<<WGM10)						
				sts TCCR1A,aux
				ldi aux,(0<<WGM12)|(0<<WGM13)|(1<<CS12)|(0<<CS11)|(1<<CS10)	
				sts TCCR1B,aux
		
Espero_segunda_act:
				sei
				
				ldi aux,(1<<ADEN)|(1<<ADSC)|(1<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)	
				sts ADCSRA,aux

				sbrs flag2,0
				jmp Espero_segunda_act

				sbrs flag,0
				jmp Hubo_actividad

				
Salto_espera:				
				ldi aux,0									;detengo timer
				sts TCCR1A,aux
				sts TCCR1B,aux	 
				ldi aux,(1<<TOV1)
				sts TIFR1,aux
				ldi flag,0				
				
			
				cli
								
				ldi cnt,2											;Deshabilito las interrupciones para analizar los soplidos  que se sensaron
				rcall ANALIZAR
				
				sbrs flag,0										;Si hubo error; ejemplo 4 soplidos
				rcall ENVIAR_DATO
				
				ldi aux,0
				ldi flag,0	
				ldi flag2,0									;reseteo flag
				ldi cnt_soplidos,0								;reseteo cnt_soplidos
				jmp Busco_actividad

Enviar_dato:	
				sbi	PORTC,5				; Me avisa que empiza la transmicion
Esperar:		lds aux,UCSR0A
				sbrs aux,UDRE0			;UDRE es el bit del UCSR0A que indica si el buffer de Tx esta listo para recibir nueva data
				jmp Esperar
				sbrc cnt,1				;Si cnt=10--->envio OFF_ON,Si cnt=01--->envio PEDAL,Si cnt=00--->envio EXOR,
				jmp Enviar_ON_OFF
				sbrc cnt,0
				jmp Enviar_PEDAL
				sts UDR0,dato_EXOR		;UDR0 es el buffer de transmicion
				rcall Delay				; Delay para dar tiempo a switchear	
				cbi PORTC,5				;Apago el Led de transmicion	
				ldi cnt,2
				ret

Enviar_ON_OFF:					
				dec cnt
				sts UDR0,dato_ON_OFF
				jmp Esperar

Enviar_PEDAL:	
				dec cnt
				sts UDR0,dato_PEDAL
				jmp Esperar
		
;***********************************************************;									
;************************Subrrutinas************************;

INIC_PORT:
				ldi aux,(0<<PC0)|(1<<PC1)|(1<<PC2)|(1<<PC5)		;PC0 es la entrada del ADC y PC1 es la salida del led error,PC2 es led de prueba y PC5 esde emision de datos por BT
				out DDRC,aux
				cbi PORTC,LED_ERROR								;dejo apagado el LED de error
				ret
INIC_USART:
				ldi aux,BRl
				sts UBRR0l,aux
				ldi aux,BRh
				sts UBRR0h,aux

				ldi aux,(1<<RXEN0)|(1<<TXEN0)
				sts UCSR0B,aux

				ldi aux,(0<<USBS0)|(1<<UCSZ00)|(1<<UCSZ01)
				sts UCSR0C,aux
				
				ret

INIC_ADC:
				ldi aux,(0<<REFS1)|(1<<REFS0)|(0<<ADLAR)|(0<<MUX3)|(0<<MUX2)|(0<<MUX1)|(0<<MUX0) ;Con MUXx elijo ADC0 pin PC0, REFSx elijo el tipo de Vref elijo externa (5V)
				sts ADMUX,aux
				ldi aux,(0<<ADEN)|(0<<ADIE)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)				; habilito el ADC con ADEN, el ADPSx sete la frec del ADC y tiene que ser <200kHz, el arduino funciona a 16MHZ por eso lo divido por 128
				sts ADCSRA,aux
				ret
INIC_TIMER1:
				ldi aux,(1<<TOIE1)											;Para activar las interrupciones
				sts TIMSK1,aux
				ret
INIC_CONFIG:
				ldi aux,(0<<ISC01)|(0<<ISC00)
				sts EICRA,aux
				ldi aux,(1<<INT0)
				out EIMSK,aux
				ret
		
Analizar:		
				rcall Delay
				cbi PORTC,PC2
				
				cpi cnt_soplidos,Soplo_1_vez
				breq Pedal_1
				cpi cnt_soplidos,Soplo_2_veces
				breq Pedal_2
				cpi cnt_soplidos,Soplo_3_veces					;Comparo con 3
				breq Pedal_3
				cpi cnt_soplidos,Succiono_1_vez
				breq Apagar_todo
				
				jmp Error

Pedal_1:		
				ldi dato_PEDAL,1
				cpi ON_OFF_P1,0				;Comparo con 0 que es el estado inicial (apagado)
				breq Encender_P1
				ldi ON_OFF_P1,0				;Aca lo voy a apagar=> actualizo valor de ON_OFF_P1
				ldi dato_ON_OFF,0
				jmp Sigo
Encender_P1:	
				ldi ON_OFF_P1,1
				ldi dato_ON_OFF,1
				jmp Sigo

Pedal_2:		
				ldi dato_PEDAL,2
				cpi ON_OFF_P2,0				;Comparo con 0 que es el estado inicial (apagado)
				breq Encender_P2
				ldi ON_OFF_P2,0				;Aca lo voy a apagar=> actualizo valor de ON_OFF_P1
				ldi dato_ON_OFF,0
				jmp Sigo

Encender_P2:	ldi ON_OFF_P2,1
				ldi dato_ON_OFF,1
				jmp Sigo

Pedal_3:		
				ldi dato_PEDAL,4
				cpi ON_OFF_P3,0				;Comparo con 0 que es el estado inicial (apagado)
				breq Encender_P3
				ldi ON_OFF_P3,0				;Aca lo voy a apagar=> actualizo valor de ON_OFF_P1
				ldi dato_ON_OFF,0
				jmp Sigo

Encender_P3:	ldi ON_OFF_P3,1
				ldi dato_ON_OFF,1
				jmp Sigo		

Sigo:		
				mov dato_EXOR,dato_Pedal
				eor dato_EXOR,dato_ON_OFF
				ret

Apagar_todo:	
				ldi dato_Pedal,8
				ldi dato_ON_OFF,0
				mov aux,dato_PEDAL
				eor aux,dato_ON_OFF
				mov dato_EXOR,aux

				ldi ON_OFF_P1,0
				ldi ON_OFF_P2,0
				ldi ON_OFF_P3,0
				ret

Error:
				sbi PORTC,PC2								;LED_ERROR=1
				rcall Delay
				cbi PORTC,PC2
				ldi flag,1
				ret	

;***********************************************************;
;***********************Interrupciones**********************;
Int_ADC:
				
				in r1,SREG
				push r1		
				
						
				lds aux,ADCL							
				lds aux1,ADCH
				sbrc aux1,1								;si el bit 1 del ADCH no esta seteado,
				jmp Fue_soplido
				sbrs aux1,0
				jmp Fue_succion
				cpi aux1,Umbral_soplido_h
				breq Pregunto 
				jmp adc_ret
Pregunto:
				cpi aux,Umbral_succion_l
				brlo Fue_succion
				cpi aux,Umbral_soplido_l
				breq Fue_soplido
				jmp adc_ret
Fue_soplido:	
				sbi PORTC,PC2
				rcall Delay
				cbi PORTC,PC2
				inc cnt_soplidos
				sbrc cnt_soplidos,1
				ldi flag2,1
				rcall delay_30ms
				jmp adc_ret
Fue_succion:
				sbi PORTC,PC5
				rcall Delay
				cbi PORTC,PC5		
				ldi aux,4
				inc cnt_soplidos					;Para que funcione la liena de abajo y si hubo un soplido y una seccion no espere al timer
				sbrc cnt_soplidos,1
				ldi flag2,1
				dec cnt_soplidos
				add cnt_soplidos,aux				;Se supone que al succionar cnt_soplidos vale 0, si se sopla e inmediatamente se succiona es error!
				rcall delay_30ms
adc_ret:		
				pop r1
				out SREG,r1
				reti

Int_TIMER1:
				in r1,SREG
				push r1

				ldi flag,1
				mov flag2,flag

				pop r1
				out SREG,r1
				reti

Int_config:
				sbi PORTC,PC5
				rcall Delay
				cbi PORTC,PC5
				rcall Delay
				sbi PORTC,PC5
				rcall Delay
				cbi PORTC,PC5
				rcall Delay
				reti
;***********************************************************;

Delay: 
		push r16
		push r17
		push r18

		ldi r16,100
salto3: ldi r17,100
salto2: ldi r18,255

salto1: dec r18
		brne salto1
		dec r17
		brne salto2
		dec r16
		brne salto3

		pop r18
		pop r17
		pop r16
ret

delay_30ms:				;Realiza 6 operaciones de mas.
		push r16
		push r17

				ldi r16, NUM_LOOP2/2;
loop_delay_2:	
				ldi r17, NUM_LOOP1/2; Divido por 2 porque el loop_delay_1 hace 2 operaciones.
loop_delay_1:	
				dec r17;
		brne loop_delay_1;
		dec r16;
		brne loop_delay_2;

		pop r17
		pop r16
		ret;
