VYBER_ODDILU

	return
;********************************************************************************************************************
PRUZKUMNIK
	call SMAZ_LCD
	call LCD_1RADEK

	call ZAPISD
	movlw 'N'
	call ZAPISD
	movlw 'E'
	call ZAPISD
	movlw 'N'
	call ZAPISD
	movlw 'I'
	call ZAPISD
	movlw ' '
	call ZAPISD
	movlw 'H'
	call ZAPISD
	movlw 'O'
	call ZAPISD
	movlw 'T'
	call ZAPISD
	movlw 'O'
	call ZAPISD
	movlw 'V'
	call ZAPISD
	movlw 'O'
	call ZAPISD
	
	call ZPOZ_1S
	call ZPOZ_1S
	goto $-1
;********************************************************************************************************************

