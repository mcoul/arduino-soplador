;******************************************************************;
;		        		Codigo para el micro esclavo
;Proyecto: Soplador
;******************************************************************;

.include "m328pdef.inc"


;Equivalencias:
				.equ BIT_OPCIONES = PB4;
				
				.equ BRl = 119						;Registros para indicar la velocidad de transmicion/recepcion. (sigue abajo)
				.equ BRh = 0						;El atmega de la placa de intro usa cristal externo por eso es 119

				.equ Apagar_PEDAL = 18
				.equ Encender_PEDAL = 6
				
;Definiciones
				.def dato_ON_OFF = r19
				.def dato_PEDAL = r20
				.def dato_EXOR = r21
				.def aux = r22
				.def accionar_pedales = r23
				.def cnt = r24
				.def motores = r25
				.def salida_opciones=r26;
				.def flag = r16

;Inicio del codigo
				.org 0x0000
				jmp Inicio

;Interrupciones
				.org URXCaddr					;Posicion de memoria de la interrupcion de RX complete		
				jmp INT_BT
Inicio:
;Realizo la inicializacion del SP
	
				ldi r16,low(RAMEND)
				out spl,r16
				ldi r16,high(RAMEND)
				out sph,r16

				ldi dato_PEDAL,0
				ldi dato_ON_OFF,0
				ldi dato_EXOR,0
				ldi salida_opciones,0
				ldi accionar_pedales,0

				rcall INI_USART
				
														 
				rcall INI_PORTD
				rcall INI_PORTB
				rcall INI_PORTC
				rcall INI_OPCIONES
				rcall INI_TIMER1
				rcall INI_TIMER2
				
				ldi cnt,2									;Contador para leer los 3 bytes de datos
							
Volver:			
				sei
				sbrs accionar_pedales,0
				jmp Volver
				
				cli

				rcall EJECUTAR_DATO_EXOR
				sbrc flag,3				;Si hubo error en la recepcion de datos, prende led, aviso a traves de aux_2 para no ejecutar mas datos
				jmp Hubo_error
				
				rcall EJECUTAR_DATO
				ldi accionar_pedales,0
				jmp Volver
Hubo_error:
				cli
				sbi PORTD,PD4				;Prendo Led de aviso que hubo error en la transmicion
				rcall Delay
				cbi PORTD,PD4
				ldi flag,0
				ldi accionar_pedales,0
				jmp Volver

;A continuacion defino las subrutinas

INI_USART:	
			;Inicializacion del BAUD RATE
				ldi r16,BRl
				sts UBRR0l,r16			;El UBRR0 es el registro del BR, es de 12 bit por eso cargo parte baja
				ldi r16,BRh
				sts	UBRR0h,r16

			;Habilito la recepcion y emision de datos (reg UCSR0B)
				ldi r16,(1<<RXCIE0)|(1<<RXEN0)|(1<<TXEN0)				;RXCIE0 habilito la interrupcion de RX
				sts UCSR0B,r16

			;Seteo formato 8 bit data, 2 bit stop
				ldi r16,(0<<USBS0)|(1<<UCSZ00)|(1<<UCSZ01)	;UCSZ0X es para setear bit data y USBS los bit stop
				sts UCSR0C,r16
				ret
INI_TIMER1:
				ldi aux,0
				sts TCNT1L,aux
				sts TCNT1H,aux
				ldi aux,(1<<COM1A1)|(0<<COM1A0)|(1<<COM1B1)|(0<<COM1B0)|(0<<WGM11)|(1<<WGM10)
				sts TCCR1A,aux
				ldi aux,(0<<ICNC1)|(0<<ICES1)|(0<<WGM13)|(0<<WGM12)|(1<<CS12)|(0<<CS11)|(1<<CS10)
				sts TCCR1B,aux
				ldi aux,low(Apagar_PEDAL)
				sts OCR1AL,aux
				sts OCR1BL,aux
				ldi aux,high(Apagar_PEDAL)
				sts OCR1AH,aux
				sts OCR1BH,aux

				ret
INI_TIMER2:		
				ldi aux,0
				sts TCNT2,aux
				ldi aux,(0<<COM2A1)|(0<<COM2A0)|(1<<COM2B1)|(0<<COM2B0)|(0<<WGM21)|(1<<WGM20)
				sts TCCR2A,aux
				ldi aux,(0<<FOC2A)|(0<<FOC2B)|(0<<WGM22)|(1<<CS22)|(1<<CS21)|(1<<CS20)
				sts TCCR2B,aux
				ldi aux,Apagar_PEDAL
				sts OCR2B,aux
				
				ret
INI_PORTD:
				ldi aux,(1<<PD4)|(1<<PD3)				;seteo el pin  PD4 (Led de error) y PD3 (OC2B pedal 1) del PORTD como salida. 
				out DDRD,aux
				cbi PORTD,PD4
				ret
INI_PORTB:
				ldi aux,(1<<PB2)|(1<<PB1)				;Seteo el pin PB1 (OC1A pedal 1) y el pin PB2 (OC1B pedal 2) como salida, EL PB4 ES EL BOTON DE OPCIONES Y PB5 SALIDA PLUG
				out DDRB,aux							;seteo como salida el pin 3 del Puerto B		
				ret

INI_PORTC:
				ldi aux,(0<<PC0)|(1<<PC1)
				out DDRC, aux;
				cbi PORTC, PC1;
				ret

INI_OPCIONES:
				sbic PINC,PC0;			Si es 1, va por plug. Si es 0, va por servos.
				ldi salida_opciones,0xFF
				sbis PINC, PC0;
				ldi salida_opciones, 0;
				ret;

EJECUTAR_DATO_EXOR:
;				Chequeo si el dato se transmitio erroneamente
				mov aux,dato_PEDAL 
				eor aux,dato_ON_OFF
				cp aux,dato_EXOR
				brne Error				
				ret				
Error:
				ldi flag,8
				ret
EJECUTAR_DATO:	
				sbrc Dato_PEDAL,3
				jmp APAGAR_TODO
				
				sbrc Dato_PEDAL,0
				jmp Pedal_1
				
				sbrc Dato_PEDAL,1
				jmp Pedal_2
				sbrc Dato_PEDAL,2
				jmp Pedal_3
				ret


Pedal_1:	
				sbrc salida_opciones, BIT_OPCIONES;
				jmp Plug;
				sbrc Dato_ON_OFF,0
				jmp Encender
				ldi aux,Apagar_PEDAL
				sts OCR2B,aux
				ret

Plug:
				sbrc Dato_ON_OFF,0
				sbi PORTC, PC1;
				sbrs Dato_ON_OFF, 0
				cbi PORTC, PC1;
				ret;

Encender:	
				
				ldi aux,Encender_PEDAL
				sts OCR2B,aux
				ret
Pedal_2:
				sbrc salida_opciones, BIT_OPCIONES;
				ret;
				sbrc Dato_ON_OFF,0
				jmp Encender_2
				ldi aux,low(Apagar_PEDAL)
				sts OCR1AL,aux
				ldi aux,high(Apagar_PEDAL)
				sts OCR1AH,aux
				ret
Encender_2:		
				ldi aux,low(Encender_PEDAL)
				sts OCR1AL,aux
				ldi aux,high(Encender_PEDAL)
				sts OCR1AH,aux
				ret				

Pedal_3:
				sbrc salida_opciones, BIT_OPCIONES;
				ret;
				sbrc Dato_ON_OFF,0
				jmp Encender_3
				ldi aux,low(Apagar_PEDAL)
				sts OCR1BL,aux
				ldi aux,high(Apagar_PEDAL)
				sts OCR1BH,aux
				ret
Encender_3:		
				ldi aux,low(Encender_PEDAL)
				sts OCR1BL,aux
				ldi aux,high(Encender_PEDAL)
				sts OCR1BH,aux
				ret	
				
Apagar_TODO:
				cbi PORTC, PC1;				Pongo en bajo el plug
				ldi aux,Apagar_pedal
				sts OCR2B,aux
				ldi aux,low(Apagar_PEDAL)
				sts OCR1AL,aux
				sts	OCR1BL,aux
				ldi aux,high(Apagar_PEDAL)
				sts OCR1AH,aux
				sts	OCR1BH,aux
				ret

Delay:
				push r16
				push r17
				push r18
				ldi r16,10
salto3:			ldi r17,100
salto2:			ldi r18,255

salto1:			dec r18
				brne salto1
				dec r17
				brne salto2
				dec r16
				brne salto3
				pop r18
				pop r17
				pop r16

				ret

;Interrupciones

INT_BT:
				in r1,SREG
				push r1
				sbrc cnt,1				;Los valores en binario de cnt son 10 (dato_ON_OFF), 01 (dato_PEDAL), 00 (dato_EXOR)
				jmp Dato_del_ON_OFF
				sbrc cnt,0
				jmp Dato_del_PEDAL
				lds dato_EXOR,UDR0			;UDR0 es el buffer de Recepcion
				ldi cnt,2
				ldi accionar_pedales,1
				pop r1
				out SREG,r1
				reti
Dato_del_ON_OFF:
				lds dato_ON_OFF,UDR0
				dec cnt
				pop r1
				out SREG,r1
				reti
				

Dato_del_PEDAL:	lds dato_PEDAL,UDR0
				dec cnt
				pop r1
				out SREG,r1
				reti

