; ceske znaky na LCD: áíešcrzý
START
	CALL INIT_CONFIG	; nakonfiguruje preruseni, WDT, USART, pull ups...
	call INIT_PORT
	call INIT_LCD

	MOVLW '1'
	CALL ZAPISD
	MOVLW '.'
	CALL ZAPISD
	MOVLW ' '
	CALL ZAPISD
	MOVLW .5
	CALL ZAPISD
	MOVLW .0
	CALL ZAPISD
	MOVLW 'd'
	CALL ZAPISD
	MOVLW 'e'
	CALL ZAPISD
	MOVLW 'k'
	CALL ZAPISD

	call LCD_2RADEK
	MOVLW '2'
	CALL ZAPISD
	MOVLW '.'
	CALL ZAPISD
	MOVLW ' '
	CALL ZAPISD
	MOVLW .5
	CALL ZAPISD
	MOVLW .0
	CALL ZAPISD
	MOVLW 'd'
	CALL ZAPISD
	MOVLW 'e'
	CALL ZAPISD
	MOVLW 'k'
	CALL ZAPISD

	call LCD_3RADEK
	MOVLW '3'
	CALL ZAPISD
	MOVLW '.'
	CALL ZAPISD
	MOVLW ' '
	CALL ZAPISD
	MOVLW .5
	CALL ZAPISD
	MOVLW .0
	CALL ZAPISD
	MOVLW 'd'
	CALL ZAPISD
	MOVLW 'e'
	CALL ZAPISD
	MOVLW 'k'
	CALL ZAPISD

	call LCD_4RADEK
	MOVLW '4'
	CALL ZAPISD
	MOVLW '.'
	CALL ZAPISD
	MOVLW ' '
	CALL ZAPISD
	MOVLW .5
	CALL ZAPISD
	MOVLW .0
	CALL ZAPISD
	MOVLW 'd'
	CALL ZAPISD
	MOVLW 'e'
	CALL ZAPISD
	MOVLW 'k'
	CALL ZAPISD

	call ZPOZ_1S
	call ZPOZ_1S
	call ZPOZ_1S
	call ZPOZ_1S
	call ZPOZ_1S
	
	call SMAZ_LCD
	call LCD_1RADEK
	; ted zobrazim na LCD ceske znaky....
; ceske znaky na LCD: áíešcrzý
	movlw	.4
	call	ZAPISD
	movlw	'e'
	call	ZAPISD
	movlw	's'
	call	ZAPISD
	movlw	'k'
	call	ZAPISD
	movlw	.2
	call	ZAPISD
	movlw	' '
	call	ZAPISD
	movlw	'z'
	call	ZAPISD
	movlw	'n'
	call	ZAPISD
	movlw	'a'
	call	ZAPISD
	movlw	'k'
	call	ZAPISD
	movlw	'y'
	call	ZAPISD
	movlw	':'
	call	ZAPISD

	call LCD_2RADEK
	movlw	00h
	call	ZAPISD
	movlw	01h
	call	ZAPISD
	movlw	02h
	call	ZAPISD
	movlw	03h
	call	ZAPISD
	movlw	04h
	call	ZAPISD
	movlw	05h
	call	ZAPISD
	movlw	06h
	call	ZAPISD
	movlw	07h
	call	ZAPISD

	call ZPOZ_1S
	call ZPOZ_1S
	call ZPOZ_1S
	call ZPOZ_1S
	call ZPOZ_1S
	
	call SMAZ_LCD
	call LCD_1RADEK
	clrf TMP5
	bsf LCD_PODSVICENI
SMYCKA
	movfw TMP5
	call ZAPISD
	call ZPOZ_300MS
	incf TMP5,f	
	GOTO SMYCKA
;********************************************************************************************************************
; CEKACI SMYCKY
;	call ZPOZ_1S
;	call ZPOZ_300MS
;	call ZPOZ_100US
;	call ZPOZ_10US
;********************************************************************************************************************
INIT_PORT
	BANK_1
	MOVLW 0xff
	MOVWF TRISA
	MOVLW B'11111000'
    MOVWF TRISB
	MOVLW B'11011111'
	MOVWF TRISC
	MOVLW B'00000000'
	MOVWF TRISD
	MOVLW 0x03
	MOVWF TRISE
	BANK_0
	RETURN
;**********************************************************
INIT_CONFIG 	; nakonfiguruje preruseni, WDT, USART, pull ups....
	BANK_1
	MOVLW b'11000111'	; ...pull up a podobny koniny
		; PORTB Pull-up Enable bit		1 = pull up enabled
		; Interrupt Edge Select bit		1 = interrupt on rising edge of RB0/INT pin
		; TMR0 Clock Source Select bit	0 = Internal instruction cycle clock (CLKO)
		; TMR0 Source Edge Select bit	0 = Increment on low-to-high transition on RA4/T0CKI pin
		; Prescaler Assignment bit		0 = Prescaler is assigned to the Timer0 module
		; PS2:PS0: Prescaler Rate Select bits	111 = TMR0 Rate 1 : 256; WDT Rate 1 : 128
	MOVWF OPTION_REG
	
	MOVLW b'00100000'	; povolime preruseni od USARTu (kdyz neco dostanem)
	MOVLW b'00000000'	; povolime preruseni od USARTu (kdyz neco dostanem)
	MOVWF PIE1	
	MOVLW b'00000000'	; ostatni vnejsi preruseni vymaskujeme
	MOVWF PIE2			

	MOVLW b'11000000' 	; povolime preruseni na vnejsi zarizeni (USART)				
	MOVWF INTCON

	MOVLW b'00100110'	;konfigurace USARTu (asynchronni, 8bit, bez parity, rychle - (BRGH = 1))
	MOVWF TXSTA
	BANK_0
	MOVLW b'10010000'	;zapnu USART
	MOVWF RCSTA
	BANK_1
	MOVLW .129 		; Fosc = 20 MHz, BRGH=1 => rychlost = 9615 bps
	;MOVLW .103 			; Fosc = 16 MHz, BRGH=1 => rychlost = 9615 bps
	MOVWF SPBRG	

	MOVLW b'00000111'
	MOVWF ADCON1		; vsechny vstupy (RA,RE) jako digitalni
	BANK_0	
	CLRF ADCON0			; pro jistotu (vypneme A/D prevodniky)

	RETURN
;**********************************************************
;**********************************************************
INTERRUPT					; sem se skace po zavolani preruseni (uz jsou vyreseny ulohy dulezitych registru)
	btfss PIR1,RCIF			; Meli bychom mit povoleno sice jen jedno preruseni (od USARTU), jeden ale nikdy nevi, proto ten test
	goto END_OF_INTERRUPT	; Pokud nejde o preruseni od USARTU, tak koncime...
END_OF_INTERRUPT			; sem skocime kdyz mame vsechny veci kolem preruseni vyrizeny
	movfw TEMP_PCLATH
	MOVWF PCLATH
	movfw TEMP_FSR
	MOVWF FSR
	movfw TEMP_STATUS
	MOVWF STATUS
	movfw TEMP_WORKING
	retfie
;**********************************************************
ZPOZ_1S ;Delay 4999999 cycles
        MOVLW 0x1A  ;26 DEC
        MOVWF TMP2
        MOVLW 0x5E  ;94 DEC
        MOVWF TMP1
        MOVLW 0x6E  ;110 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
        DECFSZ TMP1,F
        GOTO $-3
        DECFSZ TMP2,F
        GOTO $-5
		RETURN
;**********************************************************
ZPOZ_2MS
;Variables: TMP1, TMP0
;Delay 10001 cycles
        MOVLW 0x10  ;16 DEC
        MOVWF TMP1
        MOVLW 0x0CF  ;207 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
        DECFSZ TMP1,F
        GOTO $-5
;End of Delay
		RETURN
;**********************************************************
ZPOZ_300MS
;Variables: TMP2, TMP1, TMP0
;Delay 1 500 001 cycles
        MOVLW 0x08  ;8 DEC
        MOVWF TMP2
        MOVLW 0x9D  ;157 DEC
        MOVWF TMP1
        MOVLW 0x06  ;6 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
        DECFSZ TMP1,F
        GOTO $-3
        DECFSZ TMP2,F
        GOTO $-5
;End of Delay
		RETURN
;**********************************************************
ZPOZ_20MS
;Variables: TMP1, TMP0
;Delay 100001 cycles
        MOVLW 0x0A0  ;160 DEC
        MOVWF TMP1
        MOVLW 0x0CF  ;207 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
        DECFSZ TMP1,F
        GOTO $-5
;End of Delay
	return
;**********************************************************
ZPOZ_100US ;Delay 500 cycles
        MOVLW 0x01  ;1 DEC
        MOVWF TMP1
        MOVLW 0x0A5  ;165 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
        DECFSZ TMP1,F
        GOTO $-3
		RETURN
;**********************************************************
ZPOZ_50US
;Variable: TMP0
;Delay 250 cycles
        MOVLW 0x53  ;83 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
;End of Delay
		RETURN
;**********************************************************
