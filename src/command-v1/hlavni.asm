;   HLAVNI SOUBOR 
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;  displej k MP3 PREPRCAVACi
; ================
; 
; prosinec 2005 Boga
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


;**********************************************************
;   VERZE 0.0000000
;**********************************************************
	LIST    	p=PIC16f877,C=132,n=60
	__CONFIG	_WDT_OFF & _HS_OSC & _PWRTE_OFF & _BODEN_OFF & _LVP_OFF 
			; LVP_OFF = RB3 jako digitalni I/O
	errorlevel -302		; vypnuti Message [302]: Register in operand not in bank 0.
						; ! zjednoduseni vypisu, ale riziko prehlednuti chyby
;**********************************************************
	include "P16F877A.inc" 	; definice blbosti kolem procesoru
	include "displej.inc"	; definice promennych, konstant a portu
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; PROGRAM
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;**********************************************************
 org 0x0010
	include "lcd.asm"	; podprogramy pro praci s LCD
	include "displej.asm"	; podprogramy na ovladani mp3 decoderu
	include "menu.asm"	; podprogramy na ovladani mp3 decoderu
	include "ovladani.asm" ;ovladani 	
;**********************************************************
 org 0x0000
  	goto START
 org 0x0004
	movwf TEMP_WORKING
	movfw STATUS
	movwf TEMP_STATUS
	movfw FSR
	movwf TEMP_FSR
	movfw PCLATH
	movwf TEMP_PCLATH
	clrf PCLATH
	BANK_0
	INDF_BANK_0
	goto INTERRUPT
;**********************************************************
	END
