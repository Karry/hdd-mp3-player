;**********************************************************
;**********************************************************
;**********************************************************
; OBSLUZNE PODPROGRAMY PRO MP3 DECODER vs1001g
;**********************************************************
;**********************************************************
;**********************************************************

; MP3_PORT		
; MP3_PORT_TRIS	

; BITY MP3_PORT
; #define MP3_SO		MP3_PORT,0	; serial output - tady dostavame z dekoderu data
; #define MP3_SI		MP3_PORT,1	; serial input  - pokud MP3_CS=1, tak posilame mp3 data, pokud =0, tak posilame prikaz
; #define MP3_SCLK		MP3_PORT,2	; clock - nabezna hrana urcuje platnost dat pri seriovem prenosu
; #define MP3_CS		MP3_PORT,3	; cable select  - pokud MP3_CS=1, tak po SI posilame mp3 data, pokud =0, tak posilame prikaz
; #define MP3_DREQ		MP3_PORT,4	; data request  - pokud =1, tak dekoder pozaduje dalsi mp3 data (vic jak 32B)
; #define MP3_BSYNC		MP3_PORT,5	; pro synchronizaci - ma byt nastaven pri prvnim prenasenem bitu kazdeho bytu

;**********************************************************
; do TEMP3 dame adresu registru 
; do TEMP4 dame dolni slabiku zapisovaneho slova
; do TEMP5 dame horni slabiku zapisovaneho slova

MP3_SOFT_RESET	; provede softwarovy reset dekoderu (pri zapnuti a pote po zkonceni kazde mp3)
	movlw .0	; adr. reg. MODE
	movwf TEMP3
	movlw b'00000100'	; soft reset=1
	movwf TEMP4
	movlw .0
	movwf TEMP5
	call MP3_WR_REG
	return	
;**********************************************************
MP3_WR_REG	; zapise 16bitove slovo (temp4,temp5) do registru mp3 dekoderu
			; 16bit dato se odesila od nejvyssiho bitu (15,14...8,7...1,0)
			; kde TEMP5 = bity 15-8 ; TEMP4 = bity 7-0
; pri praci pouziva TEMP4, TEMP5, TEMPW
	bcf MP3_CS			; po SI posilame prikaz
	movlw b'00000010'	; write
	call MP3_WR_BYTE	
	movfw TEMP3			; adresa zapisovvaneho registru
	call MP3_WR_BYTE
	movfw TEMP5 		; horni slabika
	call MP3_WR_BYTE
	movfw TEMP4 		; dolni slabika
	call MP3_WR_BYTE
	return
;**********************************************************
; vodesle hodnotu ve W smerem k dekoderu
MP3_WR_BYTE
	bsf MP3_BSYNC	; bude nasledovat prvni bit bytu
	movwf TEMPW
	movlw .8		
MP3_WR_BYTE__1
		bcf	MP3_SCLK
		bcf MP3_SI
		rlf TEMPW,f		; odesilame od nejvyssiho bitu k nejnizsimu
		btfsc STATUS,C	;
		bsf MP3_SI
		bsf MP3_SCLK
		bcf MP3_BSYNC
		DECFSZ W,W		
		goto MP3_WR_BYTE__1		
	bcf	MP3_SCLK
	return
;**********************************************************
