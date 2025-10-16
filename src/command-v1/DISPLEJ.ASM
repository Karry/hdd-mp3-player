	; znak0 = 40h	á
	; znak1 = 48h	í
	; znak2 = 50h	e s hackem
	; znak3 = 58h	š
	; znak4 = 60h	c s hackem
	; znak5 = 68h	r s hackem
	; znak6 = 70h	z s hackem
	; znak7 = 78h	ý
START
	CALL INIT_CONFIG	; nakonfiguruje preruseni, USART, pull ups...
	call INIT_PORT		; konfigurace vstupu a vystupu (trisy)
	call INIT_LCD		; init LCD displeje (vcetne definovani 8 ceskych znaku)

	movfw RCREG			; 
	movfw RCREG			; vyprazdnime buffer usartu (po zapnuti obcas prijme nejakou blbost)

	call HLASKA_PREPRCAVAC
	call HLASKA_AUTORI
	call ZPOZ_1S
	call ZPOZ_1S
	call SMAZ_LCD
	call HLASKA_PREPRCAVAC
	call HLASKA_DISK
	call JMENODISKU
	call ZPOZ_1S

	call NACTIODDILY
	movfw TMP4
	sublw .1
	btfsc STATUS,Z
	goto $+4
	call VYBER_ODDILU
	bsf STAV,7
	goto ODDIL_JE_NACTEN
	CALL NASTAVODDIL			; pokud je na disku pouze jeden oddil, nastavime ten prvni
	BTFSC STAV,7
	goto ODDIL_JE_NACTEN
	CALL HLASKA_CHYBAODDILU
	nop
	goto $-1
ODDIL_JE_NACTEN
	call ZAKLADNI_NASTAVENI	 

	INDF_BANK_3
	movlw 0x91
	movwf FSR
	movlw 'R'
	movwf INDF
	incf FSR,f
	movlw 'O'
	movwf INDF
	incf FSR,f
	movlw 'O'
	movwf INDF
	incf FSR,f
	movlw 'T'
	movwf INDF
	incf FSR,f
	movlw h'FF'
	movwf INDF
	; nastaveni jmena zakladniho adresare
	clrf PREH_ADR_CL1
	clrf PREH_ADR_CL2
	clrf PREH_ADR_CL3
	clrf PREH_ADR_CL4

	goto PRUZKUMNIK

;	nop
;	goto $-1
;;;;;;;;;;;;;;;;;;;;;;;;;
;	movlw h'80'		; prikaz pro prime hrani mp3
;	CALL WR_USART
;	movlw h'02'
;	CALL WR_USART
;	movlw h'00'
;	CALL WR_USART
;	movlw h'00'
;	CALL WR_USART
;	movlw h'00'
;	CALL WR_USART
;	movlw h'48'
;	CALL WR_USART
;	movlw h'00'
;	CALL WR_USART
;	CALL RD_USART
;;;;;;;;;;;;;;;;;;;;;;;;;
;	goto PREHRAVANI
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
	MOVLW B'11001111'
	MOVWF TRISC
	MOVLW B'00000000'
	MOVWF TRISD
	MOVLW 0x03
	MOVWF TRISE
	BANK_0
	RETURN
;**********************************************************
INIT_CONFIG 	; nakonfiguruje preruseni, WDT, USART, pull ups....
	MOVLW b'00000001'	; 
	MOVWF T1CON			; 

	movlw h'FF'
	movwf TMR1H
	clrf TMR1L

	BANK_1
	BSF PIE1, TMR1IE	; Enable Timer1 interrupt
	BSF INTCON,GIE
	BSF INTCON,PEIE
	BANK_0


	BANK_1
	MOVLW b'11000111'	; ...pull up a podobny koniny
		; PORTB Pull-up Enable bit		1 = pull up enabled
		; Interrupt Edge Select bit		1 = interrupt on rising edge of RB0/INT pin
		; TMR0 Clock Source Select bit	0 = Internal instruction cycle clock (CLKO)
		; TMR0 Source Edge Select bit	0 = Increment on low-to-high transition on RA4/T0CKI pin
		; Prescaler Assignment bit		0 = Prescaler is assigned to the Timer0 module
		; PS2:PS0: Prescaler Rate Select bits	111 = TMR0 Rate 1 : 256; WDT Rate 1 : 128
	MOVWF OPTION_REG
	
;	MOVLW b'00100000'	; povolime preruseni od USARTu (kdyz neco dostanem)
;	MOVLW b'00000000'	; povolime preruseni od USARTu (kdyz neco dostanem)
;	MOVWF PIE1	
;	MOVLW b'00000000'	; ostatni vnejsi preruseni vymaskujeme
;	MOVWF PIE2			

;	MOVLW b'11000000' 	; povolime preruseni na vnejsi zarizeni (USART)				
;	MOVWF INTCON

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

	movlw h'BE'
	movwf AKTUAL_HLAS
	bsf STAV,4
	bcf STAV,5			; zapneme podsviceni
	clrf EKVALIZER		; vypneme ekvalizer
	RETURN
;**********************************************************
;**********************************************************
INTERRUPT					; sem se skace po zavolani preruseni (uz jsou vyreseny ulohy dulezitych registru)
;	movlw 0xC1
;	movwf TMR1L
;	MOVLW 0x3C
;	MOVWF TMR1H		; 10ms
	movlw 0x69
	movwf TMR1L
	MOVLW 0x9e
	MOVWF TMR1H		; 5ms
	BCF PIR1, TMR1IF 	; Clear interrupt flag	
	; timto zapisem dosahnu preruseni presne kazdych 5ms (pri Fosc = 20MHz)

	movfw CASOVAC
	andlw h'FF'
	btfss STATUS,Z
	decf CASOVAC,f

	bsf STAV,6


;----------------------------------------------------------
; testy tlacitek
	btfss TL_PLAY
	goto $+4
	btfsc TLACITKA_PRED,7
	goto $+2
	bsf TLACITKA,7

	btfss TL_STOP
	goto $+4
	btfsc TLACITKA_PRED,6
	goto $+2
	bsf TLACITKA,6

	btfss TL_DOPREDU
	goto $+4
	btfsc TLACITKA_PRED,5
	goto $+2
	bsf TLACITKA,5

	btfss TL_DOZADU
	goto $+4
	btfsc TLACITKA_PRED,4
	goto $+2
	bsf TLACITKA,4

	btfss TL_MENU
	goto $+4
	btfsc TLACITKA_PRED,2
	goto $+2
	bsf TLACITKA,2

	btfss TL_MENU_UP
	goto $+4
	btfsc TLACITKA_PRED,1
	goto $+2
	bsf TLACITKA,1

	btfss TL_MENU_DOWN
	goto $+4
	btfsc TLACITKA_PRED,0
	goto $+2
	bsf TLACITKA,0

	clrf TLACITKA_PRED
	btfsc TL_PLAY
	bsf TLACITKA_PRED,7
	btfsc TL_STOP
	bsf TLACITKA_PRED,6
	btfsc TL_DOPREDU
	bsf TLACITKA_PRED,5
	btfsc TL_DOZADU
	bsf TLACITKA_PRED,4
	btfsc TL_MENU
	bsf TLACITKA_PRED,2
	btfsc TL_MENU_UP
	bsf TLACITKA_PRED,1
	btfsc TL_MENU_DOWN
	bsf TLACITKA_PRED,0
;----------------------------------------------------------

	btfss STAV,4
	goto INTERRUPT_PODSV_OFF
INTERRUPT_PODSV_ON
	btfsc STAV,5
	goto INTERRUPT_PODSV_BLIK
	bsf LCD_PODSVICENI
	goto END_OF_INTERRUPT
INTERRUPT_PODSV_OFF
	bcf LCD_PODSVICENI
	goto END_OF_INTERRUPT
INTERRUPT_PODSV_BLIK
	btfss LCD_PODSVICENI
	goto $+3
	bcf LCD_PODSVICENI
	goto $+2
	bsf LCD_PODSVICENI	
	
	goto END_OF_INTERRUPT	; koncime...
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
WR_USART			; odesle slovo ve workingu po USARTu
	BANK_1	
	btfss TXSTA,1 
	goto WR_USART	; cekame do chvile nez bude pripraven transmit buffer 
	BANK_0	
	movwf TXREG
	return
;**********************************************************
RD_USART				; pocka nez prijde dato po usartu a pote ho umisti do Workingu
	btfss PIR1,RCIF
	goto RD_USART		; Pokud nejde o preruseni od USARTU, tak koncime...
	movfw RCREG			; !!! vynulovat pøíznak !!!	
	return	
;**********************************************************¨
USART_PRESKOC			; precte tolik bytu z usartu, jaka je hodnota v TMP1
	CALL RD_USART
    decfsz TMP1,f
    GOTO $-2
	return	
;**********************************************************¨
NACTIODDILY
; nacte seznam oddilu do bufferu2
	PROG_PAGE_1
	call CLEAR_BUFFER2
	PROG_PAGE_0

	bcf STAV,7
	clrf TMP3			; kolikaty oddil ted prozkoumavame
	clrf TMP4			; kolik oddilu obsahuje disk
	INDF_BANK_2
	movlw 0x10
	movwf FSR

NACTIODDILY_JEDENODDIL
	movlw h'02'			; prikaz vrat oddil s FAT32
	call WR_USART
	movfw TMP3
	call WR_USART
	call RD_USART
	movwf INDF
	btfss INDF,0
	goto NACTIODDILY_NEPLATNY
	; prohlizeny zaznam obsahuje oddil s FATkou	
	incf FSR,f

	movlw .15
	movwf TMP2
	call RD_USART
	movwf INDF
	incf FSR,f
	decfsz TMP2,f
	goto $-4
	
	incf TMP4,f
	goto NACTIODDILY_DALSI
NACTIODDILY_NEPLATNY
	; prohlizeny zaznam NEobsahuje oddil s FATkou	
	movlw .15
	movwf TMP1
	call USART_PRESKOC
NACTIODDILY_DALSI
	incf TMP3,f
	movfw TMP3
	sublw .4
	btfss STATUS,Z
	goto NACTIODDILY_JEDENODDIL
	return
;**********************************************************¨
NASTAVODDIL
	;ODDIL 1
	movlw .3
	CALL WR_USART
	INDF_BANK_2
	movlw h'11'
	movwf FSR
	movfw INDF
	CALL WR_USART
	incf FSR,f
	movfw INDF
	CALL WR_USART
	incf FSR,f
	movfw INDF
	CALL WR_USART
	incf FSR,f
	movfw INDF
	CALL WR_USART

	CALL RD_USART
	movwf TMP5
	BcF	STAV,7
	BTFSC TMP5,4
	BSF	STAV,7
 	RETURN
;**********************************************************¨
PREVED_ZNAK
; prevede znaky pred vypsanim na LCD (snaky s diakritikou a pod.)
; prevodni tabulka je pro jednoduchost umistena v EEPROMe

	BANK_2
	MOVWF EEADR 		; Address to read
	BANK_3
	BCF EECON1,EEPGD	; Point to Data memory
	BSF EECON1,RD 		; EE Read
	BANK_2
	MOVFW EEDATA 		; W = EEDATA
	BANK_0

	return
;**********************************************************
