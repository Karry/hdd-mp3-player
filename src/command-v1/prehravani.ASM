
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; smycka prehravani (zobrazuje nazev souboru a slozky, odehrany cas a dalsi blbosti...)

PREHRAVANI
 	movlw h'81'    ;vraci stav prehravani
	CALL WR_USART
    CALL RD_USART
	MOVWF PREH_STAV0
	CALL RD_USART
	MOVWF PREH_STAV1
	CALL RD_USART
	CALL RD_USART
	bsf PREH_STAV0,0
	bcf PREH_STAV1,0
	;bcf PREH_STAV1,4
	call NASTAV_STAV

	movlw h'83'    		; vraci informace o prehravanem souboru
	CALL WR_USART
	MOVLW .6
	MOVWF TMP1
	CALL USART_PRESKOC
    CALL RD_USART
	MOVWF PREH_ADR_CL1 	; cl1,cl2,cl3,cl4....4bitove cislo,ktere urcuje 1. cluster adresare
	movwf ADRESAR1
	CALL RD_USART
    MOVWF PREH_ADR_CL2
	movwf ADRESAR2
	CALL RD_USART
    MOVWF PREH_ADR_CL3
	movwf ADRESAR3
	CALL RD_USART
	MOVWF PREH_ADR_CL4
	movwf ADRESAR4
	CALL RD_USART
	MOVWF PREH_SOUB_1   ; PREH_SOUB_1,PREH_SOUB_2.....cislo zaznamu obsahujici prehravany soubor
	movwf ZAZNAM1
	CALL RD_USART
	MOVWF PREH_SOUB_2
	movwf ZAZNAM2
	
	
	PROG_PAGE_1
	call NACTI_DLOUHY_NAZEV
	PROG_PAGE_0
	
	 	
	movlw h'11'
	movwf ZAC_ZOB_SOUB
	movlw h'91'
	movwf ZAC_ZOB_ADR
	movlw .100
	movwf CASOVAC			; casovac je dekrementovan v preruseni kazdy 5ms, 
							; timto tedy dosahneme presne 500ms smycky
	clrf TLACITKA
	bsf STAV,3					; 3. bit = 1 => pri zmene hlasitosti se vypise hlasitost na LCD 

	call SMAZ_LCD

PREHRAVANI_SMYCKA
	call LCD_1RADEK
	call LCD_SMAZ_RADEK
	call LCD_1RADEK
	movlw h'00'
	movwf TMP4
	call ROLUJ				; TMP4 = 0 -> rolujeme nazev adresare 

	call LCD_2RADEK
	call LCD_SMAZ_RADEK
	call LCD_2RADEK
	movlw h'01'
	movwf TMP4
	call ROLUJ				; TMP4 = 1 -> rolujeme nazev souboru

	CALL CAS_MP3
	PROG_PAGE_1
	call INFO
	PROG_PAGE_0
	call ZOBRAZ_HLASITOST
	BTFSC PREH_STAV0,2
	GOTO  PREHRAVANI		; pokud byla zmenena prehravana mp3 (automaticky), nactemem si jeji jmeno
	
PREHRAVANI_SMYCKA_DELAY
	CALL TEST_TLAC
	CALL PREH_OBSLUHA_TLACITEK
	movfw CASOVAC
	andlw h'FF'
	btfss STATUS,Z
	goto PREHRAVANI_SMYCKA_DELAY

	movlw .100
	movwf CASOVAC			; casovac je dekrementovan v preruseni kazdy 5ms, 
							; timto tedy dosahneme presne 500ms smycky
 
	BTFSC PREH_STAV0,2
	GOTO  PREHRAVANI		; pokud byla zmenena prehravana mp3 (tlacitkem), nactemem si jeji jmeno

	btfss TLACITKA,2
	goto PREHRAVANI_NOMENU
	bcf TLACITKA,2
	PROG_PAGE_1
	goto MENU
PREHRAVANI_NOMENU

	btfsc TLACITKA,0
	goto $+4
	btfsc TLACITKA,1
	goto $+2
	goto $+4
	bcf TLACITKA,0
	bcf TLACITKA,1
	goto PRUZKUMNIK

	GOTO PREHRAVANI_SMYCKA	    	

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
ROLUJ
	clrf TMP5

	movlw .19
	movwf TMP1
	INDF_BANK_2

	movfw ZAC_ZOB_SOUB
	btfss TMP4,0
	movfw ZAC_ZOB_ADR

	movwf FSR

	movfw INDF
	sublw h'FF'
	btfsc STATUS,Z
	bsf TMP5,0	
	btfsc STATUS,Z
	goto ROLUJ_KONVYP
	movfw INDF
	CALL ZAPISD
	INCF FSR,F 
	
ROLUJ_ZACVYP
	movfw INDF
	sublw h'FF'
	btfsc STATUS,Z
	bsf TMP5,1
	btfsc STATUS,Z
	goto ROLUJ_KONVYP
		
	movfw INDF
	CALL ZAPISD
	INCF FSR,F 
	DECFSZ TMP1,F
	GOTO ROLUJ_ZACVYP
ROLUJ_KONVYP
	; pokud byl na prvni zobrazovane pozici znak h'FF' (konec retezce), 
	; je nastaven bit 0 TMP5, pokud byl jinde, je nastaven bit 1 TMP5

	movfw TMP5
	andlw h'FF'
	btfsc STATUS,Z
	goto ROLUJ_INCREMENTUJ

	btfss TMP5,0
	goto ROLUJ_KRATKE		; konec retezce byl vypsan ale ne na prvni pozici...

	btfss TMP4,0
	goto $+4	
	movlw h'11'
	movwf ZAC_ZOB_SOUB
	return
	movlw h'91'
	movwf ZAC_ZOB_ADR
	return
ROLUJ_KRATKE				; ...proto se podivame zda neni retezec dost kratky (takovy neroluje)
	movfw ZAC_ZOB_SOUB
	btfss TMP4,0
	movfw ZAC_ZOB_ADR
	andlw b'01111111'
	sublw b'00010001'
	btfsc STATUS,Z
	return
ROLUJ_INCREMENTUJ
	btfss TMP4,0
	goto $+3
	incf ZAC_ZOB_SOUB,f
	return

	incf ZAC_ZOB_ADR,f
	return
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; zobrazi aktualni hlasitost na LCD
ZOBRAZ_HLASITOST
	btfss STAV,3
	return

	movlw h'A1'
	call ZAPISI
	; kurzor vlevo na 3. radek
	btfsc PREH_STAV1,4	; je-li tento bit 1 => MUTE
	goto ZOBRAZ_HLASITOST_MUTE	

	movlw 'V'
	call ZAPISD
	movlw 'O'
	call ZAPISD
	movlw 'L'
	call ZAPISD
	movlw ' '
	call ZAPISD

	movfw AKTUAL_HLAS	
	movwf TMP5
	bcf STATUS,C
	rrf TMP5,f			; hlasitost menime po 2, proto ji upravime do rozsahu 0-128
	clrf TMP2
	movlw .100

	incf TMP2,f	
	subwf TMP5,f		; TMP5 := TMP5 - 100
	btfsc STATUS,C
	goto $-3

	addwf TMP5,f
	decf TMP2,f
	movlw .48
	addwf TMP2,w
	call ZAPISD			; stovky
	clrf TMP2
	movlw .10

	incf TMP2,f	
	subwf TMP5,f		; TMP5 := TMP5 - 10
	btfsc STATUS,C
	goto $-3

	addwf TMP5,f
	decf TMP2,f
	movlw .48
	addwf TMP2,w
	call ZAPISD			; desitky

	movlw .48
	addwf TMP5,w
	call ZAPISD			; jednotky

	return
ZOBRAZ_HLASITOST_MUTE
	movlw 'M'
	call ZAPISD
	movlw 'U'
	call ZAPISD
	movlw 'T'
	call ZAPISD
	movlw 'E'
	call ZAPISD
	movlw ' '
	call ZAPISD
	movlw ' '
	call ZAPISD
	movlw ' '
	call ZAPISD

	return

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; zobrazi cas prehravani MP3 na LCD (cas od casu dochazi chybam v dekodovani
; a tim i k udavanemu casu, proto je potreba brat tento udaj pouze informacne)
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
	btfss PREH_STAV0,1		; je-li pripraven soubor...
	goto CAS_MP3_ZOBRAZ_CAS
	btfsc PREH_STAV0,0		; ...a presto se nic neprehrava
	goto CAS_MP3_ZOBRAZ_CAS
	btfsc STAV,2
	goto CAS_MP3_SHOVEJ_CAS
CAS_MP3_ZOBRAZ_CAS
	bsf STAV,2

	CALL PREVOD			;vypocet  minut a sekund
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
CAS_MP3_SHOVEJ_CAS
	bcf STAV,2

	movlw ' '
	call ZAPISD
	movlw ' '
	call ZAPISD
	movlw ' '
	call ZAPISD
	movlw ':'
	call ZAPISD
	movlw ' '
	call ZAPISD
	movlw ' '
	call ZAPISD
	return

;**********************************************************
;----------------------------------------------------------------------------
DELENO10
	; preteceni := pomocna mod 10
	; pomocna := pomocna div 10
	; zpusob deleni je podobny jako u PREVOD
	CLRF  PRETECENI			; PRETECENI := 0
	MOVLW .16				; // pomocna ma 16bitu
	MOVWF COUNTER
DELENO10_LOOP
	RLF POMOCNA1,f
	RLF POMOCNA2,f
	RLF PRETECENI,f
	MOVLW .10
	SUBWF PRETECENI,W
	BTFSc STATUS,C
	MOVWF PRETECENI

	RLF   VYSLEDEK1,f
	RLF   VYSLEDEK2,f

	DECFSZ COUNTER,f
	GOTO  DELENO10_LOOP

	movfw VYSLEDEK1
	movwf POMOCNA1
	movfw VYSLEDEK2
	movwf POMOCNA2
	RETURN

;**************************************************************************
PREVOD	; z poctu odehranych vterin vypocita pocet odehranych minut a vterin
	; MINUTY := VTERINY div 60	// div je celociselne deleni se zbytkem
	; VTERINY := VTERINY mod 60	// mod je zbytek po deleni
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
	RLF   MINUTY2,1			;		MINUTY := (MINUTY * 2)
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
; 7. bit - play
; 6. bit - stop
; 5. bit - previjeni dopredu
; 4. bit - previjeni dozadu
; 3. bit - [nepouzit]
; 2. bit - menu
; 1. bit - menu up
; 0. bit - menu down

PREH_OBSLUHA_TLACITEK
; obsluhuje udalosti jednotlivych tlacitek pri prehravani
	btfsc TLACITKA,7
	CALL PLAY
	bcf TLACITKA,7

	btfss TLACITKA,5				; pokud bylo stisknuto tlacitko previjeni...
	goto PREH_OBSLUHA_NOREWIND
	call ZPOZ_300MS
	bcf TLACITKA,5
	btfss TL_DOPREDU				; ...koukneme se zda je stale drzeno...
	goto PREH_OBSLUHA_DALSI_MP3

	bsf PREH_STAV1,0				; ..a pokud ano, dame mp3 previjet...
	bsf PREH_STAV0,0
	call NASTAV_STAV

	call CAS_MP3
	call ZPOZ_300MS					; /nebudeme to s tim vypisovanim casu prehanet/
	btfsc TL_DOPREDU
	goto $-3

	bcf PREH_STAV1,0				; ..do okamziku, nez tlacitko pusti
	call NASTAV_STAV	
PREH_OBSLUHA_NOREWIND
	btfsc TLACITKA,4
	goto PREH_OBSLUHA_PREDCHOZI_MP3
;	CALL STOP
;	CALL PAUSE
	return
;---------------------------
PREH_OBSLUHA_PREDCHOZI_MP3
	bcf TLACITKA,4
	movlw b'00010110'
	movwf TMP5					; do TMP5 dame parametry hledani
	goto $+3
PREH_OBSLUHA_DALSI_MP3
	movlw b'00000110'
	movwf TMP5					; do TMP5 dame parametry hledani

	movlw h'09'
	call WR_USART
	movfw PREH_ADR_CL1
	call WR_USART
	movfw PREH_ADR_CL2
	call WR_USART
	movfw PREH_ADR_CL3
	call WR_USART
	movfw PREH_ADR_CL4
	call WR_USART
	movfw PREH_SOUB_1
	call WR_USART
	movfw PREH_SOUB_2
	call WR_USART
	movfw TMP5					; parametry hledani
	call WR_USART


	call RD_USART
	sublw h'06'
	btfss STATUS,Z
	goto PREH_OBSLUHA_NENALEZENO
	; nasli jsme mp3
	movlw .15
	movwf TMP1
	call USART_PRESKOC
	call RD_USART
	movwf PREH_SOUB_1
	call RD_USART
	movwf PREH_SOUB_2

	movlw h'80'		; prikaz pro hrani mp3
	CALL WR_USART
	movfw PREH_ADR_CL1
    CALL WR_USART
	movfw PREH_ADR_CL2
	CALL WR_USART
	movfw PREH_ADR_CL3
    CALL WR_USART
	movfw PREH_ADR_CL4
    CALL WR_USART
	movfw PREH_SOUB_1
    CALL WR_USART
	movfw PREH_SOUB_2
    CALL WR_USART
	CALL RD_USART

	bsf PREH_STAV0,2			; nastavime tento bit, protoze se zmenila prehravana mp3	
	return
PREH_OBSLUHA_NENALEZENO
	movlw .17
	movwf TMP1
	call USART_PRESKOC
	return
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

TEST_TLAC

	btfss TL_VOLUME_UP		
	goto TEST_TLAC_NO_MUTE	
	btfss TL_VOLUME_DOWN
	goto TEST_TLAC_NO_MUTE		; jeslize jsou stisknuta obe tlatitka hlasitosti, dame MUTE
TEST_TLAC_MUTE
	bsf PREH_STAV1,4
	call NASTAV_STAV
	btfsc STAV,3
	call ZOBRAZ_HLASITOST
	call ZPOZ_20MS
	call ZPOZ_20MS
	call ZPOZ_20MS
	call ZPOZ_20MS				; protoze se nikdy nepovede pustit tlacitka soucasne, proto tato prodleva
	goto TEST_TLAC_KONHLAS

TEST_TLAC_NO_MUTE
	BTFSC TL_VOLUME_UP		
	CALL VOLUME_UP

	BTFSC TL_VOLUME_DOWN		
	CALL VOLUME_DOWN
TEST_TLAC_KONHLAS

	RETURN

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PLAY
	btfss PREH_STAV0,0
	goto $+3
	bcf PREH_STAV0,0
	goto $+2
	bsf PREH_STAV0,0

	bcf PREH_STAV1,0
	CALL NASTAV_STAV
	return
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;PAUSE
;	btfss PREH_STAV0,0
;	goto  $+5
;	bcf	  PREH_STAV0,0
;	MOVFW PREH_STAV0
;	CALL WR_USART
;	return
;	bsf	  PREH_STAV0,0
;	MOVFW PREH_STAV0
;	CALL WR_USART
;	CALL RD_USART
;	RETURN
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

VOLUME_UP
	btfss PREH_STAV1,4
	goto $+3
	bcf PREH_STAV1,4
	call NASTAV_STAV			; jestli predtim bylo mute, vypneme

	movlw .2
	addwf AKTUAL_HLAS,w
	btfss STATUS,C
	goto VOLUME_UP_OK
	return						; pokud je jiz hlasitost maximalni, nemuzeme ji zvetsovat

VOLUME_UP_OK
	MOVLW h'82'
	CALL WR_USART
	incf AKTUAL_HLAS,f
	incf AKTUAL_HLAS,f			; protoze hlasitost ma pomeren dost kroku, pricitame po 2
	MOVFW AKTUAL_HLAS
	sublw h'FF'
	CALL WR_USART
	MOVFW AKTUAL_HLAS
	sublw h'FF'
	CALL WR_USART
	call ZPOZ_20MS				; kdyz se neprehrava mp3 je odezva obsluzneho procesoru temer okamzita
	call ZPOZ_20MS				; proto tady cekame, aby zmena hlasitosti nebyla moc rychla (kdyz se neprehrava)
	CALL RD_USART
	btfsc STAV,3
	call ZOBRAZ_HLASITOST
	RETURN
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
VOLUME_DOWN
	btfss PREH_STAV1,4
	goto $+3
	bcf PREH_STAV1,4
	call NASTAV_STAV			; jestli predtim bylo mute, vypneme

	movlw .2
	subwf AKTUAL_HLAS,w
	btfsc STATUS,C
	goto VOLUME_DOWN_OK
	return						; pokud je jiz hlasitost minimalni, nemuzeme ji zmensovat

VOLUME_DOWN_OK
    MOVLW h'82'
	CALL WR_USART
	decf AKTUAL_HLAS,f
	decf AKTUAL_HLAS,f			; protoze hlasitost ma pomeren dost kroku, odecitame po 2
    MOVFW AKTUAL_HLAS
	sublw h'FF'
    CALL WR_USART
    MOVFW AKTUAL_HLAS
	sublw h'FF'
    CALL WR_USART
	call ZPOZ_20MS				; kdyz se neprehrava mp3 je odezva obsluzneho procesoru temer okamzita
	call ZPOZ_20MS				; proto tady cekame, aby zmena hlasitosti nebyla moc rychla (kdyz se neprehrava)
    CALL RD_USART
	btfsc STAV,3
	call ZOBRAZ_HLASITOST
	RETURN
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
NASTAV_STAV
	movlw h'84'
	call WR_USART
	movfw PREH_STAV0
	call WR_USART
	movfw PREH_STAV1
	call WR_USART
	call RD_USART
	return
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
ZAKLADNI_NASTAVENI	 
; nastavy vychozi hodnoty po zapnuti
 	movlw h'81'    		; vraci stav prehravani
	CALL WR_USART
    CALL RD_USART
	MOVWF PREH_STAV0
	CALL RD_USART
	MOVWF PREH_STAV1
	CALL RD_USART
	CALL RD_USART
	bcf PREH_STAV1,4	; vypneme mute
	call NASTAV_STAV

    MOVLW h'82'
	CALL WR_USART
    MOVFW AKTUAL_HLAS
	sublw h'FF'
    CALL WR_USART
    MOVFW AKTUAL_HLAS
	sublw h'FF'
    CALL WR_USART
    CALL RD_USART		; nastavime hlasitost
	return

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
