;********************************************************************************************************************
; necha uzivatele, aby si vybral jeden z oddilu ze seznamu v bance 2 
; obsluzny procesor sice vycita az 4 oddily, mi ale pro jednoduchost davame na vyber
; pouze z prvnich tri
VYBER_ODDILU
	call SMAZ_LCD
	call LCD_1RADEK
	clrf TLACITKA

	movlw 'V'
	call ZAPISD
	movlw 'Y'
	call ZAPISD
	movlw 'B'
	call ZAPISD
	movlw 'E'
	call ZAPISD
	movlw 'R'
	call ZAPISD
	movlw ' '
	call ZAPISD
	movlw 'O'
	call ZAPISD
	movlw 'D'
	call ZAPISD
	movlw 'D'
	call ZAPISD
	movlw 'I'
	call ZAPISD
	movlw 'L'
	call ZAPISD

	clrf TMP3			; kolikaty oddil ted prozkoumavame
	clrf TMP4			; kolik oddilu obsahuje disk
	clrf TMP5			; na ktery ukazuje sipka
	INDF_BANK_2

VYBER_ODDILU_VYPIS
	movfw TMP3
	andlw h'FF'
	btfsc STATUS,Z
	call LCD_2RADEK
	sublw .1
	btfsc STATUS,Z
	call LCD_3RADEK
	movfw TMP3
	sublw .2
	btfsc STATUS,Z
	call LCD_4RADEK

	movlw .11
	movwf TMP1
	swapf TMP3,w		; w := TMP3 * 16
	addlw h'10'
	movwf FSR
	movfw INDF
	andlw h'FF'
	btfsc STATUS,Z
	goto VYBER_ODDILU_POSLEDNI	; stavovy byte byl nula, vice oddilu tu neni
	
	movlw ' '			; odsazeni pro sipku
	call ZAPISD
	movfw TMP3
	addlw .49			; cislo oddilu
	call ZAPISD
	movlw '.'
	call ZAPISD
	movlw ' '
	call ZAPISD

	movfw FSR
	addlw .5
	movwf FSR
VYBER_ODDILU_JMENO
	movfw INDF
	call ZAPISD
	incf FSR,f
	
	decfsz TMP1,f
	goto VYBER_ODDILU_JMENO	

	incf TMP3,f
	movfw TMP3
	sublw .3
	btfss STATUS,Z
	goto VYBER_ODDILU_VYPIS

VYBER_ODDILU_POSLEDNI
	decf TMP3,f

VYBER_ODDILU_SIPKY
	movfw TMP5
	andlw h'FF'	
	btfsc STATUS,Z
	call SIPKA_2RADEK
	sublw .1
	btfsc STATUS,Z
	call SIPKA_3RADEK
	movfw TMP5
	sublw .2
	btfsc STATUS,Z
	call SIPKA_4RADEK

VYBER_ODDILU_CEKEJ
	btfsc TLACITKA,1
	goto VYBER_ODDILU_SIPKA_UP
	btfsc TLACITKA,0
	goto VYBER_ODDILU_SIPKA_DOWN
	
	btfss TLACITKA,5
	goto VYBER_ODDILU_CEKEJ
	bcf TLACITKA,5

	movlw h'03'				; nasvavime ten oddil, na ktery ukazuje sipka
	call WR_USART
	swapf TMP5,w		; w := TMP3 * 16
	addlw h'11'
	movwf FSR
	movfw INDF	
	call WR_USART
	incf FSR,f
	movfw INDF	
	call WR_USART
	incf FSR,f
	movfw INDF	
	call WR_USART
	incf FSR,f
	movfw INDF	
	call WR_USART

	call RD_USART
	movwf TMP1
	btfsc TMP1,4		; Pokud je nastaven 4. bit vráceného bytu, znamená to, že spouštìcí 
						; záznam svazku byl korektnì naèten.	
	return
	call HLASKA_CHYBAODDILU
	call ZPOZ_1S
	call ZPOZ_1S
	call ZPOZ_1S
	goto VYBER_ODDILU
	
VYBER_ODDILU_SIPKA_UP
	bcf TLACITKA,1
	movfw TMP5
	andlw h'FF'
	btfss STATUS,Z
	decf TMP5,f
	goto VYBER_ODDILU_SIPKY
VYBER_ODDILU_SIPKA_DOWN
	bcf TLACITKA,0
	movfw TMP3
	subwf TMP5,w
	btfss STATUS,C
	incf TMP5,f				; if (TMP3 > TMP5){ TMP5++ }
	goto VYBER_ODDILU_SIPKY
;********************************************************************************************************************
PRUZKUMNIK
; v bufferu2 (bance 2) je dlouhy nazev adresare, ktery prave prochazime
; v bufferu1 (bance 3) je dlouhy nazev adresare, ktery se prave prehrava
; to znamena, ze pokud vybereme nejakou mp3, musime nakopirovat obsah bufferu2 do bufferu1	
	PROG_PAGE_1
	call COPY_BUFFER1_TO_2
	PROG_PAGE_0
	movfw PREH_ADR_CL1
	movwf PROCHAZENY_ADR1
	movfw PREH_ADR_CL2
	movwf PROCHAZENY_ADR2
	movfw PREH_ADR_CL3
	movwf PROCHAZENY_ADR3
	movfw PREH_ADR_CL4
	movwf PROCHAZENY_ADR4

PRUZKUMNIK_ZMENA_SLOZKY
	call SMAZ_LCD
	call LCD_1RADEK

	movlw .20
	movwf TMP1
	movlw h'11'
	movwf FSR
PRUZKUMNIK_JM_ADRESARE
	movfw INDF
	sublw h'FF'
	btfsc STATUS,Z
	goto PRUZKUMNIK_JM_ADRESARE_K
	movfw INDF
	call ZAPISD
	incf FSR,f
	decfsz TMP1,f
	goto PRUZKUMNIK_JM_ADRESARE
PRUZKUMNIK_JM_ADRESARE_K
	movlw h'09'
	call WR_USART
	movfw PROCHAZENY_ADR1
	call WR_USART
	movfw PROCHAZENY_ADR2
	call WR_USART
	movfw PROCHAZENY_ADR3
	call WR_USART
	movfw PROCHAZENY_ADR4
	call WR_USART
	call WR_USART
	call WR_USART			; hledame prvni zaznam, proto na techto bytech nezalezi
	movlw b'00001000'		; hledame prvni zaznam
	call WR_USART
	
	call LCD_2RADEK
	clrf ZPUSOB
	clrf TMP3				; kolik zaznamu je vypsano
	clrf TMP2				; kolikaty zaznam vypisujeme na LCD
	clrf TMP4				; na kolikaty zaznam na LCD ukazuje sipka
	clrf ZAZNAM1_TYP
	clrf ZAZNAM2_TYP
	clrf ZAZNAM3_TYP
	goto PRUZKUMNIK_VYPIS_PRIJEM
PRUZKUMNIK_VYPIS
	movfw TMP2
	andlw h'FF'
	btfsc STATUS,Z
	call LCD_2RADEK
	sublw .1
	btfsc STATUS,Z
	call LCD_3RADEK
	movfw TMP2
	sublw .2
	btfsc STATUS,Z
	call LCD_4RADEK

	movlw h'09'
	call WR_USART
	movfw PROCHAZENY_ADR1
	call WR_USART
	movfw PROCHAZENY_ADR2
	call WR_USART
	movfw PROCHAZENY_ADR3
	call WR_USART
	movfw PROCHAZENY_ADR4
	call WR_USART
	movfw AKTUALNI_ZAZNAM1
	call WR_USART
	movfw AKTUALNI_ZAZNAM2
	call WR_USART
	
	movlw b'00010000'		; hledame predchozi zaznam
	btfss ZPUSOB,0
	movlw b'00000000'		; hledame nasledujici zaznam
	call WR_USART
PRUZKUMNIK_VYPIS_PRIJEM
	; USERTem nam ted prijde odpoved na prikaz 09h
	INDF_BANK_0
	movfw TMP2				; kolikaty zaznam vypisujeme na LCD
	movwf TMP1
	bcf STATUS,C
	rlf TMP1,f				; * 2
	rlf TMP1,f				; * 4
	rlf TMP1,w				; * 8
	addlw h'50'
	movwf FSR				; ZAZNAM X _TYP

	movlw ' '
	call ZAPISD				; odsazeni pro sipku
	call RD_USART
	movwf TMP5
	movwf INDF
	incf FSR,f
	andlw h'FF'
	btfsc STATUS,Z
	goto PRUZKUMNIK_VYPIS_KONCIME

	sublw .6
	movlw '/'
	btfsc STATUS,Z
	movlw ' '
	call ZAPISD				; prvni znak podle typu (slozka lomitko, mp3 mezera)

	movlw .8
	movwf TMP1
	call RD_USART
	call PREVED_ZNAK
	call ZAPISD
	decfsz TMP1,f
	goto $-4				; vypis jmena

	movlw ' '
	btfss TMP5,0
	movlw '.'				; tecka mezi jmenem a priponou
	call ZAPISD

	movlw .3
	movwf TMP1
	call RD_USART
	call PREVED_ZNAK
	call ZAPISD
	decfsz TMP1,f
	goto $-4				; vypis pripony	

	call RD_USART
	movwf INDF
	incf FSR,f
	call RD_USART
	movwf INDF
	incf FSR,f
	call RD_USART
	movwf INDF
	incf FSR,f
	call RD_USART
	movwf INDF
	incf FSR,f

	call RD_USART
	movwf AKTUALNI_ZAZNAM1
	movwf INDF
	incf FSR,f
	call RD_USART
	movwf AKTUALNI_ZAZNAM2
	movwf INDF
	incf FSR,f

	incf TMP3,f				; kolik zaznamu je vypsano

	btfss ZPUSOB,0
	goto PRUZKUMNIK_VYPIS_INC
	movfw TMP2
	andlw h'FF'
	btfsc STATUS,Z
	goto PRUZKUMNIK_SIPKY
	decf TMP2,f
	goto PRUZKUMNIK_VYPIS
PRUZKUMNIK_VYPIS_INC
	incf TMP2,f
	movfw TMP2
	sublw .3
	btfss STATUS,Z
	goto PRUZKUMNIK_VYPIS
	decf TMP2,f
	
PRUZKUMNIK_SIPKY
	movfw TMP4
	andlw h'FF'	
	btfsc STATUS,Z
	call SIPKA_2RADEK
	sublw .1
	btfsc STATUS,Z
	call SIPKA_3RADEK
	movfw TMP4
	sublw .2
	btfsc STATUS,Z
	call SIPKA_4RADEK

PRUZKUMNIK_VYBER
	bcf STAV,3						; 3. bit = 1 => pri zmene hlasitosti se vypise hlasitost na LCD 
	CALL TEST_TLAC					; aby v teto casti programu chodila hlasitost

	btfsc TLACITKA,1
	goto PRUZKUMNIK_SIPKA_UP
	btfsc TLACITKA,0
	goto PRUZKUMNIK_SIPKA_DOWN

	btfsc TLACITKA,5
	goto PRUZKUMNIK_TLAC_VYBER
	btfsc TLACITKA,4
	goto PRUZKUMNIK_TLAC_ZPET
	goto PRUZKUMNIK_VYBER


PRUZKUMNIK_TLAC_VYBER
	INDF_BANK_0
	bcf TLACITKA,5
	movfw TMP4				; kam ukazuje sipka
	movwf TMP1
	bcf STATUS,C
	rlf TMP1,f				; * 2
	rlf TMP1,f				; * 4
	rlf TMP1,w				; * 8
	addlw h'50'
	movwf FSR				; ZAZNAM X _TYP
	movfw INDF
	incf FSR,f
	sublw .1
	btfss STATUS,Z
	goto PRUZKUMNIK_VYBRANA_MP3
PRUZKUMNIK_VYBRANA_SLOZKA
;	movfw PROCHAZENY_ADR1
;	movwf ADRESAR1
;	movfw PROCHAZENY_ADR2
;	movwf ADRESAR2
;	movfw PROCHAZENY_ADR3
;	movwf ADRESAR3
;	movfw PROCHAZENY_ADR4
;	movwf ADRESAR4

	movfw INDF
	movwf PROCHAZENY_ADR1
	movwf ADRESAR1
	incf FSR,f
	movfw INDF
	movwf PROCHAZENY_ADR2
	movwf ADRESAR2
	incf FSR,f
	movfw INDF
	movwf PROCHAZENY_ADR3
	movwf ADRESAR3
	incf FSR,f
	movfw INDF
	movwf PROCHAZENY_ADR4
	movwf ADRESAR4
;	incf FSR,f

;	movfw INDF
;	movwf ZAZNAM1
;	incf FSR,f
;	movfw INDF
;	movwf ZAZNAM2
;	incf FSR,f
	
	PROG_PAGE_1
;	call NACTI_DLOUHY_NAZEV
	call ZJISTI_NAZEV_SLOZKY
	PROG_PAGE_0
	goto PRUZKUMNIK_ZMENA_SLOZKY

PRUZKUMNIK_VYBRANA_MP3
	movlw h'80'		; prikaz pro hrani mp3
	CALL WR_USART
	movfw PROCHAZENY_ADR1
	CALL WR_USART
	movfw PROCHAZENY_ADR2
	CALL WR_USART
	movfw PROCHAZENY_ADR3
	CALL WR_USART
	movfw PROCHAZENY_ADR4
	CALL WR_USART

	movfw FSR
	addlw .4
	movwf FSR
	movfw INDF
	CALL WR_USART
	incf FSR,f
	movfw INDF
	CALL WR_USART
	CALL RD_USART

	PROG_PAGE_1
	call COPY_BUFFER2_TO_1			; bufferu1 je nazev prehravaneho adresare, proto si tam nakopirujeme jmeno
	PROG_PAGE_0						; aktualni prochazene slozky...
	goto PREHRAVANI

PRUZKUMNIK_TLAC_ZPET
	bcf TLACITKA,4
	btfss PREH_STAV0,1
	goto PRUZKUMNIK_VYBER
	goto PREHRAVANI					; pokud je nejaky soubor k prehravani, muzeme se vratit k prehravani

PRUZKUMNIK_VYPIS_KONCIME
	movlw .17
	movwf TMP1
	call USART_PRESKOC
	goto PRUZKUMNIK_SIPKY
PRUZKUMNIK_SIPKA_UP
	bcf TLACITKA,1
	movfw TMP4
	andlw h'FF'
	btfsc STATUS,Z
	goto $+3
	decf TMP4,f
	goto PRUZKUMNIK_SIPKY

	; jdeme o stranku nahoru
	call PREDCHOZI_ZAZNAM	; pokud existuje predchozi zaznam, da do TMP1 1, pokud ne, da do TMP1 0
	movfw TMP1
	andlw h'FF'
	btfsc STATUS,Z
	goto PRUZKUMNIK_SIPKY

	bsf ZPUSOB,0			; hledame nahoru
	clrf TMP3				; kolik zaznamu je vypsano
	movlw .2
	movwf TMP2				; kolikaty zaznam vypisujeme na LCD
	movwf TMP4				; na kolikaty zaznam na LCD ukazuje sipka
	call LCD_2RADEK
	call LCD_SMAZ_RADEK
	call LCD_3RADEK
	call LCD_SMAZ_RADEK
	call LCD_4RADEK
	call LCD_SMAZ_RADEK
	clrf ZAZNAM1_TYP
	clrf ZAZNAM2_TYP
	clrf ZAZNAM3_TYP
	goto PRUZKUMNIK_VYPIS

PRUZKUMNIK_SIPKA_DOWN
	bcf TLACITKA,0
	decf TMP3,w
;	movlw .3
	subwf TMP4,w
	btfsc STATUS,C
	goto $+3
	incf TMP4,f				; if (TMP3 > TMP4){ TMP4++ }
	goto PRUZKUMNIK_SIPKY

	; jdeme o stranku dolu
	call DALSI_ZAZNAM		; pokud existuje dalsi zaznam, da do TMP1 1, pokud ne, da do TMP1 0
	movfw TMP1
	andlw h'FF'
	btfsc STATUS,Z
	goto PRUZKUMNIK_SIPKY

	clrf ZPUSOB				; hledame dolu
	clrf TMP3				; kolik zaznamu je vypsano
	clrf TMP2				; kolikaty zaznam vypisujeme na LCD
	clrf TMP4				; na kolikaty zaznam na LCD ukazuje sipka
	call LCD_2RADEK
	call LCD_SMAZ_RADEK
	call LCD_3RADEK
	call LCD_SMAZ_RADEK
	call LCD_4RADEK
	call LCD_SMAZ_RADEK
	clrf ZAZNAM1_TYP
	clrf ZAZNAM2_TYP
	clrf ZAZNAM3_TYP
	goto PRUZKUMNIK_VYPIS
;********************************************************************************************************************
DALSI_ZAZNAM
; pokud existuje dalsi zaznam, da do TMP1 1, pokud ne, da do TMP1 0
; do AKTUALNI_ZAZNAM1 da cislo posledniho zaznamu na strance
	clrf TMP1
	movfw ZAZNAM1_TYP
	iorwf ZAZNAM2_TYP,w
	iorwf ZAZNAM3_TYP,w
	btfsc STATUS,Z
	return						; poud je stranka prazda, dalsi zaznam neexistuje

	movlw h'09'
	call WR_USART
	movfw PROCHAZENY_ADR1
	call WR_USART
	movfw PROCHAZENY_ADR2
	call WR_USART
	movfw PROCHAZENY_ADR3
	call WR_USART
	movfw PROCHAZENY_ADR4
	call WR_USART

	movfw ZAZNAM1_TYP
	andlw h'FF'
	btfsc STATUS,Z
	goto $+3
	movlw h'55'
	movwf FSR

	movfw ZAZNAM2_TYP
	andlw h'FF'
	btfsc STATUS,Z
	goto $+3
	movlw h'5D'
	movwf FSR

	movfw ZAZNAM3_TYP
	andlw h'FF'
	btfsc STATUS,Z
	goto $+3
	movlw h'65'
	movwf FSR

	movfw INDF
	movwf AKTUALNI_ZAZNAM1
	call WR_USART
	incf FSR,f
	movfw INDF
	movwf AKTUALNI_ZAZNAM2
	call WR_USART
	
	;movlw b'00010000'		; hledame predchozi zaznam
	movlw b'00000000'		; hledame nasledujici zaznam
	call WR_USART

	call RD_USART
	movwf TMP5

	movlw .17
	movwf TMP1
	call USART_PRESKOC

	clrf TMP1
	movfw TMP5
	andlw h'FF'
	btfsc STATUS,Z
	return
	bsf TMP1,0
	return
;********************************************************************************************************************
PREDCHOZI_ZAZNAM
; pokud existuje predchozi zaznam, da do TMP1 1, pokud ne, da do TMP1 0
; do AKTUALNI_ZAZNAM1 da cislo prvniho zaznamu na strance
	clrf TMP1
	movfw ZAZNAM1_TYP
	iorwf ZAZNAM2_TYP,w
	iorwf ZAZNAM3_TYP,w
	btfsc STATUS,Z
	return						; poud je stranka prazda, dalsi zaznam neexistuje

	movlw h'09'
	call WR_USART
	movfw PROCHAZENY_ADR1
	call WR_USART
	movfw PROCHAZENY_ADR2
	call WR_USART
	movfw PROCHAZENY_ADR3
	call WR_USART
	movfw PROCHAZENY_ADR4
	call WR_USART

	movfw ZAZNAM3_TYP
	andlw h'FF'
	btfsc STATUS,Z
	goto $+3
	movlw h'65'
	movwf FSR

	movfw ZAZNAM2_TYP
	andlw h'FF'
	btfsc STATUS,Z
	goto $+3
	movlw h'5D'
	movwf FSR

	movfw ZAZNAM1_TYP
	andlw h'FF'
	btfsc STATUS,Z
	goto $+3
	movlw h'55'
	movwf FSR

	movfw INDF
	movwf AKTUALNI_ZAZNAM1
	call WR_USART
	incf FSR,f
	movfw INDF
	movwf AKTUALNI_ZAZNAM2
	call WR_USART
	
	movlw b'00010000'		; hledame predchozi zaznam
	;movlw b'00000000'		; hledame nasledujici zaznam
	call WR_USART

	call RD_USART
	movwf TMP5

	movlw .17
	movwf TMP1
	call USART_PRESKOC

	clrf TMP1
	movfw TMP5
	andlw h'FF'
	btfsc STATUS,Z
	return
	bsf TMP1,0
	return
;********************************************************************************************************************
SIPKA_2RADEK
	call LCD_2RADEK
	MOVLW '>'
	CALL ZAPISD
	call LCD_3RADEK
	MOVLW ' '
	CALL ZAPISD
	call LCD_4RADEK
	MOVLW ' '
	CALL ZAPISD
	return
;********************************************************************************************************************
SIPKA_3RADEK
	call LCD_2RADEK
	MOVLW ' '
	CALL ZAPISD
	call LCD_3RADEK
	MOVLW '>'
	CALL ZAPISD
	call LCD_4RADEK
	MOVLW ' '
	CALL ZAPISD
	return
;********************************************************************************************************************
SIPKA_4RADEK
	call LCD_2RADEK
	MOVLW ' '
	CALL ZAPISD
	call LCD_3RADEK
	MOVLW ' '
	CALL ZAPISD
	call LCD_4RADEK
	MOVLW '>'
	CALL ZAPISD
	return
;********************************************************************************************************************
