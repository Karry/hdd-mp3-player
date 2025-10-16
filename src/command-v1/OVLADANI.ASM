

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	;NAZEV SOUBORU KTERY PREHRAVAME(dlouhy nazev)
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PREHRAVANI
	movlw h'83'    ;vraci informace o prehravanem souboru
	CALL WR_USART
	MOVLW .6
	MOVWF TMP1
	CALL USART_PRESKOC
    CALL RD_USART
	MOVWF PREH_ADR_CL1 ;cl1,cl2,cl3,cl4....4bitove cislo,ktere urcuje 1 cluster adresare
	CALL RD_USART
    MOVWF PREH_ADR_CL2
	CALL RD_USART
    MOVWF PREH_ADR_CL3
	CALL RD_USART
	MOVWF PREH_ADR_CL4
	CALL RD_USART
	MOVWF PREH_SOUB_1   ;PREH_SOUB_1,PREH_SOUB_2.....cislo zaznamu
	CALL RD_USART
	MOVWF PREH_SOUB_2
	
	
	MOVLW h'0A'   ;zjisteni dlouheho nazvu souboru....pekna hovadina
    CALL WR_USART
	MOVFW PREH_ADR_CL1
	CALL WR_USART
	MOVFW PREH_ADR_CL2
	CALL WR_USART
	MOVFW PREH_ADR_CL3
	CALL WR_USART
	MOVFW PREH_ADR_CL4
	CALL WR_USART
	MOVFW PREH_SOUB_1
	CALL WR_USART
	MOVFW PREH_SOUB_2
	CALL WR_USART

	INDF_BANK_2
	MOVLW h'10'
	MOVWF FSR
	MOVLW .66
	MOVWF TMP1

	CALL RD_USART
	MOVWF INDF
	INCF FSR,F
	DECFSZ TMP1,F
	GOTO $-4
	 	
	movlw H'11'
	movwf ZAC_ZOB_SOUB

	call SMAZ_LCD


PREHRAVANI_SMYCKA
	call LCD_2RADEK
	call LCD_SMAZ_RADEK
	call LCD_2RADEK

	clrf TMP5

	movlw .19
	movwf TMP1
	INDF_BANK_2
	movfw ZAC_ZOB_SOUB
	movwf FSR

	movfw INDF
	andlw h'FF'
	btfsc STATUS,Z
	bsf TMP5,0	
	btfsc STATUS,Z
	goto PREHR_KONVYP
	CALL ZAPISD
	INCF FSR,F 
	
PREHR_ZACVYP
	movfw INDF
	andlw h'FF'
	btfsc STATUS,Z
	bsf TMP5,1
	btfsc STATUS,Z
	goto PREHR_KONVYP
		
	CALL ZAPISD
	INCF FSR,F 
	DECFSZ TMP1,F
	GOTO PREHR_ZACVYP
PREHR_KONVYP
	;movfw TMP5
	;andlw h'FF'
	;btfsc STATUS,Z
	btfss TMP5,0
	goto $+4
	movlw h'11'
	movwf ZAC_ZOB_SOUB
	goto $+2
	incf ZAC_ZOB_SOUB,f


	CALL CAS_MP3
	BTFSC PREH_STAV0,2
	GOTO  PREHRAVANI
	
	CALL ZPOZ_500MS
	CALL ZPOZ_300MS
	GOTO PREHRAVANI_SMYCKA	    	





;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                        ;CAS Mp3
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
CAS_MP3
 	movlw h'81'    ;vraci stav prehravani
	CALL WR_USART
    CALL RD_USART
	MOVWF PREH_STAV0
	CALL RD_USART
	MOVWF PREH_STAV1
	CALL RD_USART
	MOVWF VTERINY1
	CALL RD_USART
	MOVWF VTERINY2

	call LCD_3RADEK
						;vypocet  minut a sekund 			
	CALL PREVOD
	; MINUTY := VTERINY div 60
	; VTERINY := VTERINY mod 60
	movfw MINUTY1
	movwf POMOCNA1
	movfw MINUTY2
	movwf POMOCNA2
	call DELENO10
	; preteceni := pomocna mod 10
	; pomocna := pomocna div 10
	movfw PRETECENI
	movwf TMP1			; zaloha jednotek minut
	call DELENO10
	movfw POMOCNA1	
	andlw h'FF'

	btfsc STATUS,Z
	goto $+3
	addlw .48
	goto $+2
	movlw ' '
	call ZAPISD			; stovky minut

	movfw PRETECENI
	addlw .48
	call ZAPISD			; desitky minut

	movfw TMP1
	addlw .48
	call ZAPISD			; jednotky minut
	

	movlw ':'
	call ZAPISD

	movfw VTERINY1
	movwf POMOCNA1
	movfw VTERINY2
	movwf POMOCNA2
	call DELENO10
	; preteceni := pomocna mod 10
	; pomocna := pomocna div 10
	movfw POMOCNA1
	addlw .48
	call ZAPISD
	movfw PRETECENI
	addlw .48
	call ZAPISD	 

	RETURN

;**********************************************************
;----------------------------------------------------------------------------
DELENO10
	; preteceni := pomocna mod 10
	; pomocna := pomocna div 10
	CLRF  PRETECENI			; PRETECENI := 0
	MOVLW .16			; // pomocna ma 24bitu
	MOVWF COUNTER
DELENO10_LOOP				; for (COUNTER:=0 ; COUNTER<16 ; COUNTER++):
	RLF POMOCNA1,f
	RLF POMOCNA2,f			; 	PRETECENI := (PRETECENI * 2) + (VTERINY mod 2)
	RLF PRETECENI,f			; 	VTERINY := VTERINY div 2
	MOVLW .10
	SUBWF PRETECENI,W
	BTFSc STATUS,C			;	if (PRETECENI - 60 > 0):
	MOVWF PRETECENI			;		PRETECENI := PRETECENI - 60
					;		MINUTY := (MINUTY * 2) + 1
	RLF   VYSLEDEK1,f		;	else:
	RLF   VYSLEDEK2,f		;		MINUTY := (MINUTY * 2)
							;	endif;
	DECFSZ COUNTER,f		; endfor;
	GOTO  DELENO10_LOOP

	movfw VYSLEDEK1
	movwf POMOCNA1
	movfw VYSLEDEK2
	movwf POMOCNA2
	RETURN

;**************************************************************************
PREVOD
	; MINUTY := VTERINY div 60
	; VTERINY := VTERINY mod 60
	CLRF  PRETECENI			; PRETECENI := 0
	MOVLW .16
	MOVWF COUNTER				
PREVOD_LOOP					; for (COUNTER:=0 ; COUNTER<16 ; COUNTER++):
	RLF   VTERINY1,1
	RLF   VTERINY2,1		; 	PRETECENI := (PRETECENI * 2) + (VTERINY mod 2)
	RLF   PRETECENI,1		; 	VTERINY := VTERINY div 2
	MOVLW .60
	SUBWF PRETECENI,W
	BTFSc STATUS,C			;	if (PRETECENI - 60 > 0):
	MOVWF PRETECENI			;		PRETECENI := PRETECENI - 60
							;		MINUTY := (MINUTY * 2) + 1
	RLF   MINUTY1,1			;	else:
	RLF   MINUTY2,1		;		MINUTY := (MINUTY * 2)
							;	endif;
	DECFSZ COUNTER,1		; endfor;
	GOTO  PREVOD_LOOP

	movfw PRETECENI
	movwf VTERINY1
	clrf VTERINY2
	RETURN
;*********************************************************************





;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                  ;OVLADANI
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
TEST_TLAC
;	BTFSC TL_PLAY
;	CALL PLAY


;	BTFSC TL_STOP		
;	CALL STOP

;	BTFSC TL_DOPREDU	
;	CALL DOPREDU

;	BTFSC TL_DOZADU		
;	CALL  VOLUME_DOWN

;	BTFSC TL_STOP		
;	CALL PAUSE

	BTFSC TL_VOLUME_UP		
	CALL VOLUME_UP

	BTFSC TL_VOLUME_DOWN		
	CALL VOLUME_DOWN

;	BTFSC TL_MENU		
;	CALL VOLUME_DOWN

;	BTFSC TL_MENU_UP	
;	CALL VOLUME_DOWN

;	BTFSC TL_MENU_DOWN		
;	CALL VOLUME_DOWN
	RETURN





























PLAY
	MOVLW h'84'
	CALL WR_USART
	BSF PREH_STAV0,0
	MOVFW PREH_STAV0
	CALL WR_USART
	MOVFW PREH_STAV1
	CALL WR_USART	
	CALL RD_USART
PAUSE
    btfss PREH_STAV0,0
	goto  $+5
	bcf	  PREH_STAV0,0
	MOVFW PREH_STAV0
	CALL WR_USART
    return
	bsf	  PREH_STAV0,0
	MOVFW PREH_STAV0
	CALL WR_USART
    CALL RD_USART
	RETURN

STOP
  	MOVLW h'84'
	CALL WR_USART
	BSF PREH_STAV0,0
	MOVFW PREH_STAV0
	CALL WR_USART
	MOVFW PREH_STAV1
	CALL WR_USART	
	CALL RD_USART
	RETURN



DOPREDU
    MOVLW h'84'
	CALL WR_USART
	MOVFW PREH_STAV0
	CALL WR_USART
    BSF PREH_STAV1,0
	MOVFW PREH_STAV1
	CALL WR_USART	
	CALL RD_USART
	RETURN

VOLUME_UP
    MOVLW h'82'
	CALL WR_USART
	incf aktual_hlas,f
    MOVFW aktual_hlas
    CALL WR_USART
    MOVFW aktual_hlas
    CALL WR_USART
    CALL RD_USART
	RETURN


VOLUME_DOWN
    MOVLW h'82'
	CALL WR_USART
	decf aktual_hlas,f
    MOVFW aktual_hlas
    CALL WR_USART
    MOVFW aktual_hlas
    CALL WR_USART
    CALL RD_USART
	RETURN








