;**********************************************************
; protoze vlastni program zabira temer celou nultou stranku programu, 
; umistil jsem nektere mene dulezite podprogramy do stranky prvni
;**********************************************************
CLEAR_BUFFER2		; BUFFER2 je 64bytu dat v bance 2 na adrese 0x110 - 0x14F
					; pouziva TEMP1
	movlw .64
	movwf TMP1
	INDF_BANK_2		; neprime adresovani na banku 2
	movlw 0x10
	movwf FSR
	movlw .0

CLEAR_BEFFER2__CLEAR
	movwf INDF
	incf FSR,F
	decfsz TMP1,F
	goto CLEAR_BEFFER2__CLEAR

	INDF_BANK_0		; neprime adresovani na banku 0
	return
;**********************************************************
CLEAR_BUFFER1		; BUFFER1 je 64bytu dat v bance 3 na adrese 0x190 - 0x1CF
					; pouziva TEMP1
	movlw .64
	movwf TMP1
	INDF_BANK_3		; neprime adresovani na banku 3
	movlw 0x90
	movwf FSR
	movlw .0

CLEAR_BEFFER1__CLEAR
	movwf INDF
	incf FSR,F
	decfsz TMP1,F
	goto CLEAR_BEFFER1__CLEAR

	INDF_BANK_0		; neprime adresovani na banku 0
	return
;**************************************************************************
COPY_BUFFER1_TO_2
	INDF_BANK_2		; neprime adresovani na banku 2
	movlw .67
	movwf TMP1
	movlw h'90'
	movwf FSR
COPY_BUFFER1_TO_2_BYTE
	movfw INDF
	bcf FSR,7
	movwf INDF
	bsf FSR,7
	incf FSR,f

	decfsz TMP1,f
	goto COPY_BUFFER1_TO_2_BYTE

	return
;**************************************************************************
COPY_BUFFER2_TO_1
	INDF_BANK_2		; neprime adresovani na banku 2
	movlw .67
	movwf TMP1
	movlw h'10'
	movwf FSR
COPY_BUFFER2_TO_1_BYTE
	movfw INDF
	bsf FSR,7
	movwf INDF
	bcf FSR,7
	incf FSR,f

	decfsz TMP1,f
	goto COPY_BUFFER2_TO_1_BYTE

	return
;**************************************************************************
NACTI_DLOUHY_NAZEV
; k souboru ADRESAR[1-4], ZAZNAM[1-2] vycte dlouhy nazev a umisti jej do BUFFERU2
	PROG_PAGE_0
	MOVLW h'0A'   		; zjisteni dlouheho nazvu souboru....
    CALL WR_USART
	MOVFW ADRESAR1
	CALL WR_USART
	MOVFW ADRESAR2
	CALL WR_USART
	MOVFW ADRESAR3
	CALL WR_USART
	MOVFW ADRESAR4
	CALL WR_USART
	MOVFW ZAZNAM1
	CALL WR_USART
	MOVFW ZAZNAM2
	CALL WR_USART

	INDF_BANK_2
	MOVLW h'10'
	MOVWF FSR
	MOVLW .66
	MOVWF TMP1

DLNAZEV_PRIJEM
	PROG_PAGE_0
	CALL RD_USART
	call PREVED_ZNAK
	PROG_PAGE_1
	MOVWF INDF
	INCF FSR,F
	DECFSZ TMP1,F
	GOTO DLNAZEV_PRIJEM

	movlw h'10'
	movwf FSR
	movfw INDF
	sublw .1
	btfss STATUS,Z
	goto DLNAZEV_NENIDLOUHYNAZEV		; pokud stavovy byte na prikaz 0Ah neni 01h nebyl precten dlouhy nazev
	incf FSR,f
	movfw INDF
	sublw h'FF'							; kdyz prvni znak nazvu je 0 (po prevodu FFh) neni take dlouhy nazev
	btfss STATUS,Z
	goto DLNAZEV_JEDLOUHYNAZEV
DLNAZEV_NENIDLOUHYNAZEV					; budeme si muset vystacit s kratkym nazvem
	PROG_PAGE_0
	movlw h'05'
	call WR_USART
	MOVFW ADRESAR1
	CALL WR_USART
	MOVFW ADRESAR2
	CALL WR_USART
	MOVFW ADRESAR3
	CALL WR_USART
	MOVFW ADRESAR4
	CALL WR_USART
	MOVFW ZAZNAM1
	CALL WR_USART
	MOVFW ZAZNAM2
	CALL WR_USART

	MOVLW h'10'
	MOVWF FSR
	MOVLW .9
	MOVWF TMP1

DLNAZEV_PRIJEM_2
	PROG_PAGE_0
	CALL RD_USART
	call PREVED_ZNAK
	PROG_PAGE_1
	MOVWF INDF
	INCF FSR,F
	DECFSZ TMP1,F
	GOTO DLNAZEV_PRIJEM_2				; prijem 8 znaku kratkeho jmena
	
	MOVLW h'10'
	MOVWF FSR
	movfw INDF
	sublw h'06'
	movlw '.'
	btfss STATUS,Z				
	movlw ' '							; jestli soubor nebyla mp3, nebudeme vkladat tecku
	movwf TMP1

	MOVLW h'19'
	MOVWF FSR
	movfw TMP1
	MOVWF INDF
	INCF FSR,F

	MOVLW .3
	MOVWF TMP1
DLNAZEV_PRIJEM_3
	PROG_PAGE_0
	CALL RD_USART
	call PREVED_ZNAK
	PROG_PAGE_1
	MOVWF INDF
	INCF FSR,F
	DECFSZ TMP1,F
	GOTO DLNAZEV_PRIJEM_3				; prijem 3 znaku pripony kratkeho jmena

	MOVLW .4
	MOVWF TMP1
	PROG_PAGE_0
	call USART_PRESKOC					; prvni sektor je nam ted k ...
	PROG_PAGE_1
DLNAZEV_JEDLOUHYNAZEV
	movlw h'52'
	movwf FSR	
	movlw h'FF'
	movwf INDF							; protoze pokud je nazev delsi jak 65 znaku, tak neobsahuje ukoncovaci byte, 
	return								; proto ho tam ted umistime (pro jistotu)
;**************************************************************************
ZJISTI_NAZEV_SLOZKY
; v ADRESAR prijme cislo prvniho clusteru slozky. do BUFFERU2 da jeji dlouhy nazev
	PROG_PAGE_0
	movlw h'0C'
	call WR_USART
	movfw ADRESAR1
	call WR_USART
	movfw ADRESAR2
	call WR_USART
	movfw ADRESAR3
	call WR_USART
	movfw ADRESAR4
	call WR_USART
		
	call RD_USART		; 1 byte – pøíznak úspìchu
						;	00h => povedlo se
						;	01h => tento pøíkaz nelze použít pro koøenový adresáø
						;	81h => zadaný cluster neobsahuje zaèátek adresáøe (následující data jsou neplatná)
	PROG_PAGE_1
	andlw h'FF'
	btfss STATUS,Z
	goto ZJISTI_NAZEV_SLOZKY_ROOT

	PROG_PAGE_0
	call RD_USART
	movwf ADRESAR1
	call RD_USART
	movwf ADRESAR2
	call RD_USART
	movwf ADRESAR3
	call RD_USART
	movwf ADRESAR4
	call RD_USART
	movwf ZAZNAM1
	call RD_USART
	movwf ZAZNAM2
	PROG_PAGE_1

	call NACTI_DLOUHY_NAZEV

	return
ZJISTI_NAZEV_SLOZKY_ROOT
	movlw .6
	movwf TMP1	
	PROG_PAGE_0
	call USART_PRESKOC
	PROG_PAGE_1

	INDF_BANK_2
	movlw 0x11
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

	return	
;**************************************************************************
INFO
	movlw h'83'    		; vraci informace o prehravanem souboru
	PROG_PAGE_0
	CALL WR_USART
	CALL RD_USART
	MOVWF AUDATA1
	CALL RD_USART
	MOVWF AUDATA2
	MOVLW .10
	MOVWF TMP1
	CALL USART_PRESKOC
	call LCD_4RADEK
	call LCD_SMAZ_RADEK
	call LCD_4RADEK
	PROG_PAGE_1
	
	MOVLW 'M'	  ;MONO
	BTFSC AUDATA2,7
	MOVLW 'S'	   ;STEREO
	call ZAPISD2
	MOVLW ' '	
	call ZAPISD2
	
	PROG_PAGE_0
	movfw AUDATA1
	movwf POMOCNA1
	movfw AUDATA2		; AUDATA obsahuje na bitech 0-9 aktualni vzorkovaci frekvenci
	andlw b'00000001'
	movwf POMOCNA2
	call DELENO10
	; preteceni := pomocna mod 10
	; pomocna := pomocna div 10
	movfw PRETECENI
	movwf TMP1			; zaloha jednotek
	call DELENO10

	PROG_PAGE_1
	movfw POMOCNA1
	andlw h'FF'
	btfsc STATUS,Z
	goto $+3
	addlw .48
	goto $+2
	movlw ' '			; pokud stovky = 0, tak zobrazime mezeru, ne nulu...
	PROG_PAGE_0	

	call ZAPISD			; stovky

	movfw PRETECENI
	addlw .48
	call ZAPISD			; desitky minut

	movfw TMP1
	addlw .48
	call ZAPISD			; jednotky minut
	
	PROG_PAGE_1
	MOVLW 'k'
	CALL ZAPISD2
	MOVLW 'b'
	CALL ZAPISD2
	MOVLW 'p'
	CALL ZAPISD2
	MOVLW 's'
	CALL ZAPISD2
	MOVLW '/'
	CALL ZAPISD2
	
	MOVFW AUDATA2
	ANDLW b'00011110'
	MOVWF TMP1
	SUBLW .2
	BTFSC STATUS,Z
	CALL FREK_44.1
	MOVFW AUDATA2
	ANDLW b'00011110'
	MOVWF TMP1
	SUBLW .4
	BTFSC STATUS,Z
	CALL FREK_48
	MOVFW AUDATA2
	ANDLW b'00011110'
	MOVWF TMP1
	SUBLW .6
	BTFSC STATUS,Z
	CALL FREK_32
	MOVFW AUDATA2
	ANDLW b'00011110'
	MOVWF TMP1
	SUBLW .8
	BTFSC STATUS,Z
	CALL FREK_22
	MOVFW AUDATA2
	ANDLW b'00011110'
	MOVWF TMP1
	SUBLW .10
	BTFSC STATUS,Z
	CALL FREK_24
	MOVFW AUDATA2
	ANDLW b'00011110'
	MOVWF TMP1
	SUBLW .12
	BTFSC STATUS,Z
	CALL FREK_16
	MOVFW AUDATA2
	ANDLW b'00011110'
	MOVWF TMP1
	SUBLW .14
	BTFSC STATUS,Z
	CALL FREK_11
	MOVFW AUDATA2
	ANDLW b'00011110'
	MOVWF TMP1
	SUBLW .16
	BTFSC STATUS,Z
	CALL FREK_12
	MOVFW AUDATA2
	ANDLW b'00011110'
	MOVWF TMP1
	SUBLW .18
	BTFSC STATUS,Z
	CALL FREK_8

	CALL FREK_KHZ
	
	BTFSS PREH_STAV0,4
	goto INFO_NR
	BTFSS PREH_STAV0,5
	goto INFO_RD
	goto INFO_R1
INFO_R1
	MOVLW 'R'
	CALL ZAPISD2
	MOVLW '1'
	CALL ZAPISD2
	return
INFO_NR
	MOVLW 'N'
	CALL ZAPISD2
	MOVLW 'R'
	CALL ZAPISD2
	return
INFO_RD
	MOVLW 'R'
	CALL ZAPISD2
	MOVLW 'D'
	CALL ZAPISD2
	return
;**************************************************************************
FREK_44.1
	MOVLW '4'
	CALL ZAPISD2
	MOVLW '4'
	CALL ZAPISD2
	MOVLW '.'
	CALL ZAPISD2
	MOVLW '1'
	CALL ZAPISD2
	return


FREK_48
	MOVLW '4'
	CALL ZAPISD2
	MOVLW '8'
	CALL ZAPISD2
	return

FREK_32
	MOVLW '3'
	CALL ZAPISD2
	MOVLW '2'
	CALL ZAPISD2
	return

FREK_22
	MOVLW '2'
	CALL ZAPISD2
	MOVLW '2'
	CALL ZAPISD2
	return

FREK_24
	MOVLW '2'
	CALL ZAPISD2
	MOVLW '4'
	CALL ZAPISD2
	return

FREK_16
	MOVLW '1'
	CALL ZAPISD2
	MOVLW '6'
	CALL ZAPISD2
	return

FREK_11
	MOVLW '1'
	CALL ZAPISD2
	MOVLW '1'
	CALL ZAPISD2
	return

FREK_12
	MOVLW '1'
	CALL ZAPISD2
	MOVLW '2'
	CALL ZAPISD2
	return

FREK_8
	MOVLW '8'
	CALL ZAPISD2
	return

FREK_KHZ
	MOVLW 'k'
	CALL ZAPISD2
	MOVLW 'H'
	CALL ZAPISD2
	MOVLW 'z'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	return
;**************************************************************************
