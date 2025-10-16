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
POKUSNY_KOD	
	movlw b'11100000'	; adresy budou v LBA, budeme pracovat s masterem
	movwf DEVICE
	movlw .0
	movwf SECTOR_C
	movwf LBA1	
	clrf LBA2
	clrf LBA3
	clrf FEATURES
	movlw 0x21		; read sector
	movlw 0xEC		; identify device
	movwf COMMAND
	call WR_BLOCK

	call WAIT_FOR_READY			; cekame az disk nebude zaneprazdnen
	movfw ATA_STATUS
	call WR_USART
	movlw h'ff'
	call WR_USART

	;call KONTROLA
	;movlw h'88'
	;call WR_USART
	
	movlw h'ff'			; dalsich XX slov odesleme na USART...
	movwf TEMP5
POK5_ODESLI
	call WAIT_FOR_DATA		; cekame na data
	call READ_DATA
	movfw DATA_H
	call WR_USART
	movfw DATA_L
	call WR_USART
	decfsz TEMP5,F
	goto POK5_ODESLI

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
	movlw b'10000000'	;zapnu USART, povolim continuous receive
	movwf RCSTA
	movlw b'10010000'	;zapnu USART, povolim continuous receive
	movwf RCSTA

	btfss PIR1,5	; vlajka preruseni 1 = The USART receive buffer is full
	goto POKUSNY_KOD4

	bcf PIR1,5

	;movfw RCREG
	;sublw h'8a'
	;btfss STATUS,Z
	;goto POKUSNY_KOD4

	movlw b'10000000'	;zapnu USART, povolim continuous receive
	movwf RCSTA
	movlw b'10010000'	;zapnu USART, povolim continuous receive
	movwf RCSTA

	bsf ERROR_LED
	return
;**********************************************************
