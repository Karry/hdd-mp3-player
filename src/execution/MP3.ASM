c;********************************************************************
; Zkusebni program na cteni dat z ATA disku.                      
; Casem mozna bude prekousavat FAT32 a prehravat z disku MP3.
; To je zatim jen ale sen
;                                                                
; srpen 2005 - zari 2005 Karry - lukas.karas@centrum.cz
;********************************************************************

;**********************************************************
;   HLAVNI SOUBOR 
;**********************************************************
; !!!!!!!! VSECHNY CASOVE SMYCKY JSOU POCITANY NA Fosc=16MHz !!!!!
; !!!!!!!! NASTAVENI USARTu TAKY !!!!!!!
	LIST    	p=PIC16f877,C=132,n=60
	__CONFIG	_WDT_OFF & _HS_OSC & _PWRTE_OFF & _BODEN_OFF & _LVP_OFF 
			; LVP_OFF = RB3 jako digitalni I/O
	errorlevel -302      ; vypnuti Message [302]: Register in operand not in
                      ; bank 0.
                      ; ! zjednoduseni vypisu, ale riziko prehlednuti chyby

	include "P16F877.inc" 	; definice blbosti kolem procesoru
	include "mp3.inc" 		; definice promennych a portu

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; PROGRAM
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	org 0
 	goto START
	org	4
	goto INTERRUPT
;**********************************************************

	include "ata.asm" 		; podprogramy na ovladani ATA disku
	include "fat32.asm" 	; podprogramy na nacteni a praci s FAT32
	include "vs1001.asm"	; podprogramy na ovladani mp3 decoderu
	include "aritmetic.asm"	; podprogramy vykonavajici zakladni aritmetologicke operace
	;include "pokusne.asm"

;**********************************************************
START
	call INIT_CONFIG	; nakonfiguruje preruseni, WDT, USART, pull ups...
	call INIT_PORT		; nastavy trisy, a porty do vychozi polohy

	call DELAY_25us 	; chvili pockame, protoze napjeti zdroje co mam doma (stary PC-AT zdroj)
	call DELAY_25us 	; zezacatku dost kolisa...
	call DELAY_25us

	call POZDRAV

	;call MP3_SOFT_RESET
	call ATA_RESET				; resetujeme disk, koukneme zda tu nejakej mame
	btfss ATA_ATTRIBUTES,ATA_OK
	;goto $-2					;pokud neni pripojen disk, tak se jej pokousime neustale najit...
	nop
	call DELAY_500ms
	call IDENTIFY_DEVICE		; koukneme co disk umi
	call ODESLI_MODEL_NUMBER	; odesleme si jmeno disku 

	call DELAY_500ms
	call SCAN_MBR				; najdeme oddily s FAT32 a jejich seznam dame do bufferu 2
	call ODESLI_BUFFER2			; odesleme si seznam oddilu (FAT32) s adresami

	clrf LBA4
	clrf LBA3
	clrf LBA2
	movlw .63
	movwf LBA1					; LBA adresa 1. oddilu

	call DELAY_500ms
	call NACTI_FAT32			; nacte parametry zvoleneho oddilu
	clrf CLUSTER4
	clrf CLUSTER3
	clrf CLUSTER2
	movlw .2
	movwf CLUSTER1
	call CLUSTER_TO_LBA			; zjistime skutecnou polohu dat na disku
	movlw 1
	movwf SECTOR_C
	call READ_SECTOR			; dame prikaz je precist
	movlw .255
	movwf TEMP1
	call ODESLI_DATA			; odesleme USARTem

BIG_LOOP
	bsf ERROR_LED
	call DELAY_500ms

	bcf ERROR_LED
	call DELAY_500ms
	
	movlw 'O'
	call WR_USART
	movlw 'K'
	call WR_USART

	goto BIG_LOOP
;**********************************************************
INIT_PORT
	BANK_1
;	movlw b'00100001' 			; bity SO a DREQ jako vstupy z dekoderu
	movlw 0xff
	movwf MP3_PORT_TRIS
	movlw b'00000000'			; adresovani disku jako vystupy, jen vstup pro USART
	movwf ATA_ADDRESS_TRIS		
	movlw .0
	movwf ATA_CONTROL_TRIS		; ovladani disku jako vystupy
	movlw 0xff
	movwf DATA_PORT_LOW_TRIS	; datovou sbernici jako vstupy
	movwf DATA_PORT_HIGH_TRIS	
	BANK_0
	
	movlw b'00000111'	; signal reset-, diow- a dior- jsou aktivni v log. 0 !!!
	movwf ATA_CONTROL
	movlw b'00110111'	; CS1-, CS0- = 1 => datova sbernice disku je odpojena
	movwf ATA_ADDRESS
	clrf MP3_PORT	
	return
;**********************************************************
INIT_CONFIG 	; nakonfiguruje preruseni, WDT, USART, pull ups....
	BANK_1
	movlw b'11000111'	; ...pull up a podobny koniny
		; PORTB Pull-up Enable bit		1 = pull up enabled
		; Interrupt Edge Select bit		1 = interrupt on rising edge of RB0/INT pin
		; TMR0 Clock Source Select bit	0 = Internal instruction cycle clock (CLKO)
		; TMR0 Source Edge Select bit	0 = Increment on low-to-high transition on RA4/T0CKI pin
		; Prescaler Assignment bit		0 = Prescaler is assigned to the Timer0 module
		; PS2:PS0: Prescaler Rate Select bits	111 = TMR0 Rate 1 : 256; WDT Rate 1 : 128
	movwf OPTION_REG
	
	movlw b'00100000'	; povolime preruseni od USARTu (kdyz neco dostanem)
	movwf PIE1	
	movlw b'00000000'	; ostatni vnejsi preruseni vymaskujeme
	movwf PIE2			
	movlw b'11000000' 	; povolime preruseni na vnejsi zarizeni (USART)				
	movwf INTCON

	movlw b'00100110'	;konfigurace USARTu (asynchronni, 8bit, bez parity, rychle - (BRGH = 1))
	movwf TXSTA
	BANK_0
	movlw b'10010000'	;zapnu USART
	movwf RCSTA
	BANK_1
	;movlw .129 		; Fosc = 20 MHz, BRGH=1 => rychlost = 9615 bps
	movlw .103 		; Fosc = 16 MHz, BRGH=1 => rychlost = 9615 bps
	movwf SPBRG	

	movlw b'00000111'
	movwf ADCON1		; vsechny vstupy (RA,RE) jako digitalni
	BANK_0	
	clrf ADCON0		; pro jistotu (vypneme A/D prevodniky)

	return
;**********************************************************
WR_USART	; odesle slovo ve workingu po ICSP
	BANK_1	
	btfss TXSTA,1 
	goto WR_USART	; cekame do chvile nez bude pripraven transmit buffer 

	BANK_0	
	movwf TXREG
	return
;**********************************************************
; tento podprogram bude pro budouci praci zbytecny, je zde jen proto, abych na PC videl ze program byl spusten...
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
; odesle data, ktera jdou z disku USARTEM. Pocet dat je v reg. TEMP1
ODESLI_DATA
	call READ_DATA	
	movfw DATA_L
	call WR_USART
	movfw DATA_H
	call WR_USART	
	decfsz TEMP1,F
	goto ODESLI_DATA
	return
;**********************************************************
ODESLI_MODEL_NUMBER	; Podprogram IDENTIFY_DEVICE nam do bufferu 1 hodil jmeno disku
			; mi jej ted odesleme USARTem, aby mohl byt zobrazen na displeji
	INDF_BANK_3	; BUFFER_1 je v bance 3
	movlw 0x90	; na adrese 90
	movwf FSR
	movlw .20	; budeme odesilat 20 slov (40 znaku)
	movwf TEMP1
ODESLI_MODEL_NUMBER_ODESILANI
	movfw INDF
	movwf TEMP2	; data do bufferu byla vkladana stylem DATA_L, DATA_H, DATA_L, DATA_H...
	incf FSR,F	; ASCII hodnoty jsou ale razeny stylem DATA_H, DATA_L, DATA_H, DATA_L...
	movfw INDF	; proto to pisu tak slozite...
	incf FSR,F
	
	call WR_USART
	movfw TEMP2
	call WR_USART	

	decfsz TEMP1,F
	goto ODESLI_MODEL_NUMBER_ODESILANI

	INDF_BANK_0	
	return
;**********************************************************
ODESLI_BUFFER2
	INDF_BANK_2	; BUFFER_2 je v bance 2
	movlw 0x10	; na adrese 10
	movwf FSR
	movlw .64	; budeme odesilat 64 bytu
	movwf TEMP1
ODESLI_BUFFER2_ODESILANI
	movfw INDF
	call WR_USART
	incf FSR,F	
	decfsz TEMP1,F
	goto ODESLI_BUFFER2_ODESILANI

	INDF_BANK_0		
	return
;**********************************************************
INTERRUPT					; sem se skace po zavolani preruseni...
	movwf TEMP_WORKING
	movfw STATUS
	movwf TEMP_STATUS
	BANK_0

	btfss PIR1,5			; Meli bychom mit povoleno sice jen jedno preruseni (od USARTU), jeden ale nikdy nevi, proto ten test
	goto END_OF_INTERRUPT	; Pokud nejde o preruseni od USARTU, tak koncime...
	movfw RCREG
	btfsc RCSTA,1
	goto END_OF_INTERRUPT
	btfsc RCSTA,2
	goto END_OF_INTERRUPT	; Pokud nastala nejaka chyba pri prijimani data, tak na to s*r*m...

	; Sem bychom se podle me meli dostat pri obdrzeni nejakeho slova po USARTU, moc to ale nefunguje...
	; Budu muset zjistit, jestli to je hardwarem, ci softwarem...

END_OF_INTERRUPT			; sem skocime kdyz mame vsechny veci kolem preruseni vyrizeny
	movfw TEMP_STATUS
	movwf STATUS
	movfw TEMP_WORKING
	retfie
;**********************************************************
DELAY_500ms
; (Fosc = 16 MHz , instr. cyklus= 0.25 us) 500 000us / 0.25 us = 2 000 000 instrukcnich cyklu
;Variables: TMP2, TMP1, TMP0
;Delay 2000000 cycles
        MOVLW 0x47  ;71 DEC
        MOVWF TMP2
        MOVLW 0x2B  ;43 DEC
        MOVWF TMP1
        MOVLW 0x0D9  ;217 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
        DECFSZ TMP1,F
        GOTO $-5
        DECFSZ TMP2,F
        GOTO $-9
;End of Delay
	return
;**********************************************************
	END
