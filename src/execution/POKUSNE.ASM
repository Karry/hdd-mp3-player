;**********************************************************
; POKUSNE PODPROGRAMY. TADY BUDU POSTUPNE TESTOVAT FUNKCNOST PODPROGRAMU...
POZDRAV  ; odesle po seriove lince pozdrav
	movlw 'A'	
	call WR_USART
	movlw 'h'
	call WR_USART
	movlw 'o'
	call WR_USART
	movlw 'j'
	call WR_USART
	movlw '!'
	call WR_USART
	return
;**********************************************************
KONTROLA
	; jen tak pro kontrolu nam do PC posle hodnoty vsech ATA registru 
	; (abych mel prehled)
	call RD_STATUS_A
	movfw ATA_STATUS_A 
	call WR_USART	
	
	call RD_ERROR
	movfw ATA_ERROR 
	call WR_USART	
	
	call RD_SC
	movfw SECTOR_C
	call WR_USART	
	
	call RD_LBA1
	movfw LBA1
	call WR_USART	
	
	call RD_LBA2
	movfw LBA2
	call WR_USART	
	
	call RD_LBA3
	movfw LBA3
	call WR_USART	
	
	call RD_DEVICE
	movfw DEVICE
	call WR_USART	
	
	call RD_STATUS
	movfw ATA_STATUS 
	call WR_USART	
	
	return	
;**********************************************************
POKUSNY_KOD4  ; pocka nez prijde nejake dato 
	call DELAY_500ms

;	movlw b'10010000'	;zapnu USART, povolim continuous receive
;	movwf RCSTA

	movfw RCREG
	call WR_USART

	btfss PIR1,5	; vlajka preruseni 1 = The USART receive buffer is full
	goto POKUSNY_KOD4

	bcf PIR1,5
	
	sublw h'8A'
	btfss STATUS,Z
	goto POKUSNY_KOD4

	bsf ERROR_LED
	return
;**********************************************************
