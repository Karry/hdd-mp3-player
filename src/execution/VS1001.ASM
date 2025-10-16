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
; co nejrychleji vodesle hodnotu ve W smerem k dekoderu (obsluhuje signaly DSYNC, SI, SCLK)
VS_WR_BYTE
	; k praci pouziva TEMPW
	movwf TEMPW		; dato co mame odeslat si hodime do tempu...

	bsf MP3_BSYNC	; bude nasledovat prvni bit bytu, proto nastavime BSYNC

	; 7. bit bytu
	bcf MP3_SCLK	; shodime SCLK
	bcf MP3_SI		; nevime zda bit bude 0 nebo 1, SI nulujeme
	rlf TEMPW,f		; odesilame od nejvyssiho bitu k nejnizsimu
	btfsc STATUS,C
	bsf MP3_SI
	bsf MP3_SCLK
	bcf MP3_BSYNC
	
	; 6. bit bytu
	bcf MP3_SCLK	; shodime SCLK
	bcf MP3_SI		; nevime zda bit bude 0 nebo 1, SI nulujeme
	rlf TEMPW,f		; odesilame od nejvyssiho bitu k nejnizsimu
	btfsc STATUS,C
	bsf MP3_SI
	bsf MP3_SCLK

	; 5. bit bytu
	bcf MP3_SCLK	; shodime SCLK
	bcf MP3_SI		; nevime zda bit bude 0 nebo 1, SI nulujeme
	rlf TEMPW,f		; odesilame od nejvyssiho bitu k nejnizsimu
	btfsc STATUS,C
	bsf MP3_SI
	bsf MP3_SCLK

	; 4. bit bytu
	bcf MP3_SCLK	; shodime SCLK
	bcf MP3_SI		; nevime zda bit bude 0 nebo 1, SI nulujeme
	rlf TEMPW,f		; odesilame od nejvyssiho bitu k nejnizsimu
	btfsc STATUS,C
	bsf MP3_SI
	bsf MP3_SCLK

	; 3. bit bytu
	bcf MP3_SCLK	; shodime SCLK
	bcf MP3_SI		; nevime zda bit bude 0 nebo 1, SI nulujeme
	rlf TEMPW,f		; odesilame od nejvyssiho bitu k nejnizsimu
	btfsc STATUS,C
	bsf MP3_SI
	bsf MP3_SCLK

	; 2. bit bytu
	bcf MP3_SCLK	; shodime SCLK
	bcf MP3_SI		; nevime zda bit bude 0 nebo 1, SI nulujeme
	rlf TEMPW,f		; odesilame od nejvyssiho bitu k nejnizsimu
	btfsc STATUS,C
	bsf MP3_SI
	bsf MP3_SCLK

	; 1. bit bytu
	bcf MP3_SCLK	; shodime SCLK
	bcf MP3_SI		; nevime zda bit bude 0 nebo 1, SI nulujeme
	rlf TEMPW,f		; odesilame od nejvyssiho bitu k nejnizsimu
	btfsc STATUS,C
	bsf MP3_SI
	bsf MP3_SCLK

	; 0. bit bytu
	bcf MP3_SCLK	; shodime SCLK
	bcf MP3_SI		; nevime zda bit bude 0 nebo 1, SI nulujeme
	rlf TEMPW,f		; odesilame od nejvyssiho bitu k nejnizsimu
	btfsc STATUS,C
	bsf MP3_SI
	bsf MP3_SCLK

	bcf MP3_SCLK
	return
;**********************************************************
; do TEMP1 dame adresu registru 
; do TEMP2 dame dolni slabiku zapisovaneho slova
; do TEMP3 dame horni slabiku zapisovaneho slova
VS_WR_REG	; zapise 16bitove slovo (TEMP2,TEMP3) do registru mp3 dekoderu (TEMP1)
			; 16bit dato se odesila od nejvyssiho bitu (15,14...8,7...1,0)
			; kde TEMP5 = bity 15-8 ; TEMP4 = bity 7-0
; pri praci pouziva TEMP1, TEMP2, TEMP3, TEMPW
	bcf MP3_CS			; po SI posilame prikaz
	movlw b'00000010'	; write
	call VS_WR_BYTE	
	movfw TEMP1			; adresa zapisovaneho registru
	call VS_WR_BYTE
	movfw TEMP3 		; horni slabika
	call VS_WR_BYTE
	movfw TEMP2 		; dolni slabika
	call VS_WR_BYTE
	bsf MP3_CS
	return
;**********************************************************
VS_SOFT_RESET	; provede softwarovy reset dekoderu (pri zapnuti a pote po skonceni kazde mp3)
	call DELAY_200ms

	movlw VSADDR_MODE
	movwf TEMP1
	bsf VSREG_MODE_L,2	; soft reset=1
	movfw VSREG_MODE_L
	movwf TEMP2
	movlw .0			; MODE_H
	movwf TEMP3
	call VS_WR_REG

	call DELAY_2ms
	call VS_SEND_1024_NULL	

	return	
;**********************************************************
VS_SEND_32_NULL
	call WAIT_FOR_VSDREQ
	movlw .32
	movwf TEMP2
	
	movlw .0
	call VS_WR_BYTE
	decfsz TEMP2,F
	goto $-3
	return
;**********************************************************
VS_SEND_1024_NULL
	bsf MP3_CS			; po SI posilam data
	movlw .32
	movwf TEMP1

	call VS_SEND_32_NULL
	decfsz TEMP1,F
	goto $-2
	 
	return
;**********************************************************
VS_SET_VOLUME
	movlw VSADDR_VOL
	movwf TEMP1

	movfw VSREG_VOL_L
	movwf TEMP2
	movfw VSREG_VOL_H
	movwf TEMP3
	call VS_WR_REG
	return		
;**********************************************************
WAIT_FOR_VSDREQ
	btfss MP3_DREQ
	goto WAIT_FOR_VSDREQ
	return
;**********************************************************
VS_BEEP
	call WAIT_FOR_VSDREQ

	bsf MP3_CS			; po SI posilam data
	movlw h'53'
	call VS_WR_BYTE
	movlw h'EF'
	call VS_WR_BYTE
	movlw h'6E'
	call VS_WR_BYTE
	movlw .62			; ctyr bytova testovaci sekvence. Tento posledni byte znamena, 
	call VS_WR_BYTE		; ze s pouzitim vzorkovaci frekvence 16kHz bude generovan ton 1kHz
	movlw .0
	call VS_WR_BYTE
	movlw .0
	call VS_WR_BYTE
	movlw .0
	call VS_WR_BYTE
	movlw .0			; testovaci kod musi byt nasledovan 4 nulamy
	call VS_WR_BYTE

	call DELAY_200ms	; nimusovku nechame zapnutou 200ms

	call WAIT_FOR_VSDREQ

	movlw h'45'
	call VS_WR_BYTE
	movlw h'78'
	call VS_WR_BYTE
	movlw h'69'
	call VS_WR_BYTE
	movlw h'74'			; odeslanim tohoto kodu sinusovku ukoncime...
	call VS_WR_BYTE
	movlw .0
	call VS_WR_BYTE
	movlw .0
	call VS_WR_BYTE
	movlw .0
	call VS_WR_BYTE
	movlw .0
	call VS_WR_BYTE

	call VS_SOFT_RESET
	return
;**********************************************************
VS_INIT
	clrf VSREG_MODE_L
	clrf VSREG_STATUS_L
	clrf VSREG_VOL_L		; VOL=0 => maximalni hlasitost
	clrf VSREG_VOL_H

	call VS_SOFT_RESET		; resetujeme
	call VS_SET_VOLUME		; nastavime hlasitost

	call VS_BEEP			; dvakrat za sebou pipneme
	call DELAY_200ms
	call VS_BEEP
	
	return
;**********************************************************
