;********************************************************************************************************************
; RUTINY PRO PRACI S LCD
;********************************************************************************************************************
INIT_LCD
	call ZPOZ_20MS			; nez se ustali napeti
	call INIT8B
	call ZPOZ_20MS
	call INIT8B
	call ZPOZ_20MS
	call INIT8B
	call ZPOZ_20MS
	call INIT8B
	call ZPOZ_20MS
	call INIT8B

	call CZ_INI

	movlw b'00000110' 
	call ZAPISI
	movlw b'00000001' 
	call ZAPISI
	CALL ZPOZ_2MS
	return
;********************************************************************************************************************
SMAZ_LCD
	movlw b'00000001' 
	call ZAPISI
	CALL ZPOZ_2MS
	return
;********************************************************************************************************************
INIT8B: 
	movlw   b'00111000'     ; 8 - bit
	call    ZAPISI
	movlw   b'00001111'     ; LCD on, kurzor on,no blik 
	call    ZAPISI
	return
;********************************************************************************************************************
LCD_SMAZ_RADEK
	movlw .20
	movwf TMP1
	movlw ' '
	call ZAPISD
	decfsz TMP1,f
	goto $-3	
	return
;********************************************************************************************************************
LCD_1RADEK
	movlw h'80'		; adresa 00h - 0
	call ZAPISI
	return
;********************************************************************************************************************
LCD_2RADEK
	movlw h'AA'		; adresa 2Ah - 42
	call ZAPISI
	return
;**********************************************************
LCD_3RADEK
	movlw h'94'		; adresa 10h - 16
	call ZAPISI
	return
;**********************************************************
LCD_4RADEK
	movlw h'd4'		; adresa 50h - 80
	call ZAPISI
	return
;**********************************************************
CZ_INI	
	clrf	TMP3		; cislo bytu, ktery jsme naplnily do uzivatelske pameti LCD
	movlw	0x40		; prvni adresa znaku v LCD displeji
	call	ZAPISI
CZ_INI_2	
	movf	TMP3,W
	call	TAB_CZ
	call	ZAPISD
	incf	TMP3,F
	movlw	0x40		; až ADRESA dosáhne 40h tak je konec
	subwf	TMP3,W
	btfss	STATUS,Z
	goto	CZ_INI_2

	return
;**********************************************************
TAB_CZ	
	addwf	PCL,F		; definování ceských znaku pro LCD

	; znak0 = 40h	á
	retlw	0x02	; '      X '
	retlw	0x04	; '     X  '
	retlw	0x1E	; '   XXXX '
	retlw	0x01	; '       X'
	retlw	0x0F	; '    XXXX'
	retlw	0x11	; '   X   X'
	retlw	0x0F	; '    XXXX'
	retlw	0x00	; '        '
	
	; znak1 = 48h	í
	retlw	0x02	; '      X '
	retlw	0x04	; '     X  '
	retlw	0x0C	; '    XX  '
	retlw	0x04	; '     X  '
	retlw	0x04	; '     X  '
	retlw	0x04	; '     X  '
	retlw	0x0E	; '    XXX '
	retlw	0x00	; '        '

	; znak2 = 50h	e s hackem
	retlw	0x0A	; '    X X '
	retlw	0x04	; '     X  '
	retlw	0x0E	; '    XXX '
	retlw	0x11	; '   X   X'
	retlw	0x1F	; '   XXXXX'
	retlw	0x10	; '   X    '
	retlw	0x0E	; '    XXX '
	retlw	0x00	; '        '

	; znak3 = 58h	š
	retlw	0x0A	; '    X X '
	retlw	0x04	; '     X  '
	retlw	0x0E	; '    XXX '
	retlw	0x10	; '   X    '
	retlw	0x0E	; '    XXX '
	retlw	0x01	; '       X'
	retlw	0x1E	; '   XXXX '
	retlw	0x00	; '        '

	; znak4 = 60h	c s hackem
	retlw	0x0A	; '    X X '
	retlw	0x04	; '     X  '
	retlw	0x0E	; '    XXX '
	retlw	0x10	; '   X    '
	retlw	0x10	; '   X    '
	retlw	0x11	; '   X   X'
	retlw	0x0E	; '    XXX '
	retlw	0x00	; '        '

	; znak5 = 68h	r s hackem
	retlw	0x0A	; '    X X '
	retlw	0x04	; '     X  '
	retlw	0x16	; '   X XX '
	retlw	0x19	; '   XX  X'
	retlw	0x10	; '   X    '
	retlw	0x10	; '   X    '
	retlw	0x10	; '   X    '
	retlw	0x00	; '        '

	; znak6 = 70h	z s hackem
	retlw	0x0A	; '    X X '
	retlw	0x04	; '     X  '
	retlw	0x1F	; '   XXXXX'
	retlw	0x02	; '      X '
	retlw	0x04	; '     X  '
	retlw	0x08	; '    X   '
	retlw	0x1F	; '   XXXXX'
	retlw	0x00	; '        '
	; znak7 = 78h	ý
	retlw	0x02	; '      X '
	retlw	0x04	; '     X  '
	retlw	0x11	; '   X   X'
	retlw	0x11	; '   X   X'
	retlw	0x0F	; '    XXXX'
	retlw	0x01	; '       X'
	retlw	0x0E	; '    XXX '
	retlw	0x00	; '        '
;************************************************
ZAPISI  
	; krystal 20MHz => instrukce = 200ns
	BCF LCD_RS			; RS na  RB2 je 0 - instrukce
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
	bsf LCD_ENABLE

	CALL ZPOZ_50US      ; zpozdeni 50 uS na vykonani instrukce
	RETURN
;**********************************************************
ZAPISD  
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

	CALL ZPOZ_50US      ; zpozdeni 50 uS na zapis data
	RETURN
;**********************************************************
