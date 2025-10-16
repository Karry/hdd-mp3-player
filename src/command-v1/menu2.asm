NAVRAT_Z_MENU
	clrf TLACITKA
	PROG_PAGE_0
	goto PREHRAVANI	
;---------------------------------------------------------------
MENU
	clrf TMP5			; na kterou polozku v menu ukazuje sipka

MENU_SIPKY				; podle toho, kde je sipka, tak zobrazi informace na lcd a sipku...
	movfw TMP5
	andlw h'FF'	
	btfsc STATUS,Z
	goto MENU_1POLOZKA	
	movfw TMP5
	sublw .1
	btfsc STATUS,Z
	goto MENU_2POLOZKA	
	movfw TMP5
	sublw .2
	btfsc STATUS,Z
	goto MENU_3POLOZKA	
	movfw TMP5
	sublw .3
	btfsc STATUS,Z
	goto MENU_4POLOZKA	
	movfw TMP5
	sublw .4
	btfsc STATUS,Z
	goto MENU_5POLOZKA
	movfw TMP5
	sublw .5
	btfsc STATUS,Z
	goto MENU_6POLOZKA	
	

MENU_ROLOVANI				; reseni tlacitek v menu...
	bcf STAV,3				; 3. bit = 1 => pri zmene hlasitosti se vypise hlasitost na LCD 
	PROG_PAGE_0
	CALL TEST_TLAC			; aby v teto casti programu chodila hlasitost
	PROG_PAGE_1

	btfsc TLACITKA,1
	goto MENU_SIPKA_UP
	btfsc TLACITKA,0
	goto MENU_SIPKA_DOWN
	btfsc TLACITKA,4
	goto NAVRAT_Z_MENU

	btfsc TLACITKA,5
	goto ZMENA_STAVU	

	goto MENU_ROLOVANI
;---------------------------------------------------------------
ZMENA_STAVU
	bcf TLACITKA,5
	; podle toho, kde je sipka, se zmeni stav nejake polozky...
	movfw TMP5
	andlw h'FF'	
	btfsc STATUS,Z
	goto M_ZMENA_1POLOZKY
	movfw TMP5
	sublw .1
	btfsc STATUS,Z
	goto M_ZMENA_2POLOZKY

	movfw TMP5
	sublw .2
	btfsc STATUS,Z
	goto M_ZMENA_3POLOZKY

	movfw TMP5
	sublw .4
	btfsc STATUS,Z
	goto M_ZMENA_5POLOZKY


	goto MENU_SIPKY
;---------------------------------------------------------------
M_ZMENA_1POLOZKY
		; 5:4	=> nastaveni podsviceni
		;	00	- podsviceni vypnuto
		;	01	- podsviceni zapnuto porad
		;	11	- podsviceni blika 50Hz
	btfss STAV,4
	goto M_ZMENA_1POLOZKY_OFF
	btfss STAV,5
	goto M_ZMENA_1POLOZKY_SV
	bsf STAV,4
	bcf STAV,5
	goto MENU_SIPKY
M_ZMENA_1POLOZKY_SV
	bcf STAV,4
	bcf STAV,5
	goto MENU_SIPKY
M_ZMENA_1POLOZKY_OFF	;0
	bsf STAV,4
	bsf STAV,5
	goto MENU_SIPKY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
M_ZMENA_2POLOZKY
	btfss TL_PODSVICENI
	goto M_ZMENA_2POLOZKY_ZAPNI
	bcf TL_PODSVICENI
	goto MENU_SIPKY
M_ZMENA_2POLOZKY_ZAPNI
	bsf TL_PODSVICENI
	goto MENU_SIPKY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
M_ZMENA_3POLOZKY
	btfss PREH_STAV1,3
	goto M_ZMENA_3POLOZKY_ZAPNI
	bcf PREH_STAV1,3
	goto M_ZMENA_3POLOZKY_NASTAV
M_ZMENA_3POLOZKY_ZAPNI
	bsf PREH_STAV1,3	
M_ZMENA_3POLOZKY_NASTAV
	PROG_PAGE_0
	call NASTAV_STAV
	PROG_PAGE_1
	goto MENU_SIPKY	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
M_ZMENA_5POLOZKY
	movfw EKVALIZER
	sublw .12
	btfss STATUS,Z
	goto M_ZMENA_5POLOZKY_INC
	clrf EKVALIZER
	goto M_ZMENA_5POLOZKY_NASTAV
M_ZMENA_5POLOZKY_INC
	incf EKVALIZER,f
M_ZMENA_5POLOZKY_NASTAV
	movlw h'85'
	PROG_PAGE_0
	call WR_USART
	movfw EKVALIZER
	call WR_USART
	call RD_USART
	PROG_PAGE_1
	goto MENU_SIPKY	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;---------------------------------------------------------------
MENU_SIPKA_UP
	bcf TLACITKA,1
	movfw TMP5
	sublw .0
	btfss STATUS,Z
	decf TMP5,f
	goto MENU_SIPKY
MENU_SIPKA_DOWN
	bcf TLACITKA,0
	movfw TMP5
	sublw .5				; maximalni polozka menu 0-5
	btfss STATUS,Z
	incf TMP5,f
	goto MENU_SIPKY
;---------------------------------------------------------------
MENU_1POLOZKA
	call MENU_1
	PROG_PAGE_0
	call SIPKA_2RADEK
	PROG_PAGE_1
	goto MENU_ROLOVANI
MENU_2POLOZKA
	call MENU_1
	PROG_PAGE_0
	call SIPKA_3RADEK
	PROG_PAGE_1
	goto MENU_ROLOVANI
MENU_3POLOZKA
	call MENU_1
	PROG_PAGE_0
	call SIPKA_4RADEK
	PROG_PAGE_1
	goto MENU_ROLOVANI
MENU_4POLOZKA
	call MENU_2
	PROG_PAGE_0
	call SIPKA_2RADEK
	PROG_PAGE_1
	goto MENU_ROLOVANI
MENU_5POLOZKA
	call MENU_2
	PROG_PAGE_0
	call SIPKA_3RADEK
	PROG_PAGE_1
	goto MENU_ROLOVANI
MENU_6POLOZKA
	call MENU_2
	PROG_PAGE_0
	call SIPKA_4RADEK
	PROG_PAGE_1
	goto MENU_ROLOVANI

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; 1. STRANKA MENU
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
MENU_1
	PROG_PAGE_0
	call SMAZ_LCD
	call LCD_1RADEK
	PROG_PAGE_1
	PROG_PAGE_1
	MOVLW 'M'
	CALL ZAPISD2
	MOVLW 'E'
	CALL ZAPISD2
	MOVLW 'N'
	CALL ZAPISD2
	MOVLW 'U'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW '1'
	CALL ZAPISD2
	MOVLW '/'
	CALL ZAPISD2
	MOVLW '2'
	CALL ZAPISD2
;;;;;;;;;;;;;;;;;;;;
	PROG_PAGE_0
	call LCD_2RADEK
	PROG_PAGE_1
   	MOVLW ' '
	CALL ZAPISD2
	MOVLW 'p'
	CALL ZAPISD2
	MOVLW 'o'
	CALL ZAPISD2
	MOVLW 'd'
	CALL ZAPISD2
	MOVLW 's'
	CALL ZAPISD2
	MOVLW 'v'
	CALL ZAPISD2
	MOVLW h'01'
	CALL ZAPISD2
	MOVLW 'c'
	CALL ZAPISD2
	MOVLW 'e'
	CALL ZAPISD2
	MOVLW 'n'
	CALL ZAPISD2
	MOVLW h'01'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW 'L'
	CALL ZAPISD2
	MOVLW 'C'
	CALL ZAPISD2
	MOVLW 'D'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	call M_STAV_LCD
;;;;;;;;;;;;;;;;;;;
	PROG_PAGE_0
	call LCD_3RADEK
	PROG_PAGE_1
 	MOVLW ' '
	CALL ZAPISD2
	MOVLW 'p'
	CALL ZAPISD2
	MOVLW 'o'
	CALL ZAPISD2
	MOVLW 'd'
	CALL ZAPISD2
	MOVLW 's'
	CALL ZAPISD2
	MOVLW 'v'
	CALL ZAPISD2
	MOVLW h'01'
	CALL ZAPISD2
	MOVLW 'c'
	CALL ZAPISD2
	MOVLW 'e'
	CALL ZAPISD2
	MOVLW 'n'
	CALL ZAPISD2
	MOVLW h'01'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW 't'
	CALL ZAPISD2
	MOVLW 'l'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	call M_STAV_LT

;;;;;;;;;;;;;;;;;;;
	PROG_PAGE_0
	call LCD_4RADEK
	PROG_PAGE_1
 	MOVLW ' '
	CALL ZAPISD2
	MOVLW 'b'
	CALL ZAPISD2
	MOVLW 'a'
	CALL ZAPISD2
	MOVLW 's'
	CALL ZAPISD2
	MOVLW 'y'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	call M_STAV_BASY

	return
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; 2. STRANKA MENU
MENU_2
    PROG_PAGE_0
	call SMAZ_LCD
	call LCD_1RADEK
	PROG_PAGE_1
 	MOVLW 'M'
	CALL ZAPISD2
	MOVLW 'E'
	CALL ZAPISD2
	MOVLW 'N'
	CALL ZAPISD2
	MOVLW 'U'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW '2'
	CALL ZAPISD2
	MOVLW '/'
	CALL ZAPISD2
	MOVLW '2'
	CALL ZAPISD2
;;;;;;;;;;;;;;;;;;;;;;;
	PROG_PAGE_0
	call LCD_2RADEK
	PROG_PAGE_1
 	MOVLW ' '
	CALL ZAPISD2
	MOVLW 'v'
	CALL ZAPISD2
	MOVLW 'y'
	CALL ZAPISD2
	MOVLW 'p'
	CALL ZAPISD2
	MOVLW 'n'
	CALL ZAPISD2
	MOVLW 'u'
	CALL ZAPISD2
	MOVLW 't'
	CALL ZAPISD2
	MOVLW h'01'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW 'H'
	CALL ZAPISD2
	MOVLW 'D'
	CALL ZAPISD2
	MOVLW 'D'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	call M_STAV_HDD
;;;;;;;;;;;;;;;;;;;;;;;
	PROG_PAGE_0
	call LCD_3RADEK
	PROG_PAGE_1
 	MOVLW ' '
	CALL ZAPISD2
	MOVLW 'e'
	CALL ZAPISD2
	MOVLW 'k'
	CALL ZAPISD2
	MOVLW 'v'
	CALL ZAPISD2
	MOVLW 'a'
	CALL ZAPISD2
	MOVLW 'l'
	CALL ZAPISD2
	MOVLW 'i'
	CALL ZAPISD2
	MOVLW 'z'
	CALL ZAPISD2
	MOVLW 'e'
	CALL ZAPISD2
	MOVLW 'r'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	call M_STAV_EKV
;;;;;;;;;;;;;;;;;;;;;;;
	PROG_PAGE_0
	call LCD_4RADEK
	PROG_PAGE_1
 	MOVLW ' '
	CALL ZAPISD2
	MOVLW 'r'
	CALL ZAPISD2
	MOVLW 'e'
	CALL ZAPISD2
	MOVLW 'p'
	CALL ZAPISD2
	MOVLW 'e'
	CALL ZAPISD2
	MOVLW 'a'
	CALL ZAPISD2
	MOVLW 't'
	CALL ZAPISD2
	MOVLW ' '
	CALL ZAPISD2
	call M_STAV_REPEAT
	return
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; PROCEDURY PRO VYPIS STAVU ZALOZEK V MENU
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
M_STAV_LCD
		; 5:4	=> nastaveni podsviceni
		;	00	- podsviceni vypnuto
		;	01	- podsviceni zapnuto porad
		;	11	- podsviceni blika 50Hz
	btfss STAV,4
	goto M_STAV_LCD_OFF
	btfss STAV,5
	goto M_STAV_LCD_SV
	movlw '1'
	call ZAPISD2
	return
M_STAV_LCD_SV
	movlw '2'
	call ZAPISD2
	return
M_STAV_LCD_OFF
	movlw '0'
	call ZAPISD2
	return
;;;;;;;;;;;;;;;;;;;;;;;
M_STAV_LT
	movlw '1'
	btfss TL_PODSVICENI
	movlw '0'
	call ZAPISD2
	return
;;;;;;;;;;;;;;;;;;;;;;;
M_STAV_BASY
	movlw '1'
	btfss PREH_STAV1,3
	movlw '0'
	call ZAPISD2
	return
;;;;;;;;;;;;;;;;;;;;;;;
M_STAV_HDD
	return
;;;;;;;;;;;;;;;;;;;;;;;
M_STAV_EKV
	movfw EKVALIZER
	movwf TMP4
	movlw .10
	clrf TMP2

	incf TMP2,f	
	subwf TMP4,f			; TMP4 := TMP4 - 10
	btfsc STATUS,C
	goto $-3

	addwf TMP4,f
	decf TMP2,f
	movlw .48
	addwf TMP2,w
	call ZAPISD2			; desitky

	movlw .48
	addwf TMP4,w
	call ZAPISD2			; jednotky
	return
;;;;;;;;;;;;;;;;;;;;;;;
M_STAV_REPEAT
	return
;;;;;;;;;;;;;;;;;;;;;;;

	MOVLW 'O'
	CALL ZAPISD2
	MOVLW 'N' 
	CALL ZAPISD2
	return
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

;**********************************************************
ZAPISD2  
	; krystal 20MHz => instrukce = 200ns
	BSF LCD_RS			; RS na  RB2 je 1 - DATA
	BCF LCD_RW			; R/W na RB1 je 0 - zapis
	nop					; Tas min 140ns
	MOVWF   PORTD
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	BSF LCD_ENABLE
	NOP
	NOP
	nop
	nop
	NOP					; ENABLE slespon 450ns v log1
	bcf LCD_ENABLE
	NOP
	NOP
	nop
	nop
	NOP
	;bsf LCD_ENABLE
	PROG_PAGE_0
	CALL ZPOZ_50US      ; zpozdeni 50 uS na zapis data
	PROG_PAGE_1
	RETURN
;**********************************************************
