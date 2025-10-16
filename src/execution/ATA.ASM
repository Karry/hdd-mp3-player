;**********************************************************
;**********************************************************
;**********************************************************
; OBSLUZNE PODPROGRAMY PRO ATA
;**********************************************************
;**********************************************************
;**********************************************************

;**********************************************************
; cteni a zapis ATA registru 
;**********************************************************
RD_STATUS         
	movlw D_STATUS      ; Status 
	call RUTR 
	movwf ATA_STATUS
	return
;*****************************************
RD_ERROR
	movlw D_ERROR      ; Error
	call RUTR
	movwf ATA_ERROR
	return
;*****************************************
RD_STATUS_A     
	movlw D_STATUS_A    ; Alternate Status 
	call RUTR 
	movwf ATA_STATUS_A
	return
;*****************************************
RD_SC
	movlw D_SECTOR_C    ; Sector Count
	call RUTR
	movwf SECTOR_C
	return
;*****************************************
RD_LBA1
	movlw D_LBA1    ; Sector Number 
	call RUTR                
	movwf LBA1 
	return
;*****************************************
RD_LBA2
	movlw D_LBA2  ; Cylinder Low
	call RUTR
	movwf LBA2
	return
;*****************************************
RD_LBA3
	movlw D_LBA3  ; Cylinder High   
	call RUTR
	movwf LBA3
	return
;*****************************************
RD_DEVICE
	movlw D_DEVICE  ; Device Head
	call RUTR
	movwf DEVICE
	return
;*****************************************
;*****************************************
WR_DC
	movf DEVICE_C,w     ; Device Control
	movwf TEMPW
	movlw D_DEVICE_C
	call RUTW
	return
;*****************************************
WR_COMMAND          
	movf COMMAND,w      ; Command       
	movwf TEMPW
	movlw D_COMMAND
	call RUTW
	return
;*****************************************
WR_SC	                 
    movf SECTOR_C,w     ; Sector Count
	movwf TEMPW
	movlw D_SECTOR_C     
	call RUTW
	return
;*****************************************
WR_LBA1
	movf LBA1,w     
	movwf TEMPW
	movlw D_LBA1    
	call RUTW
	return
;*****************************************
WR_LBA2
	movf LBA2,w   ; Cylinder Low
	movwf TEMPW
	movlw D_LBA2
	call RUTW
	return
;*****************************************
WR_LBA3
	movf LBA3,w   ; Cylinder High
	movwf TEMPW
	movlw D_LBA3
	call RUTW
	return
;*****************************************
WR_DEVICE
	movf DEVICE,w     ; Device Head 
	movwf TEMPW
	movlw D_DEVICE
	call RUTW
	return
;*****************************************
WR_FEATURES
	movf FEATURES,w     ; Features
	movwf TEMPW
	movlw D_FEATURES
	call RUTW
	return
;*****************************************
; zapise vsechny registry potrebne k vykonani prikazu (adresove registry a prikaz)
WR_BLOCK
;	call WAIT_FOR_READY_FOR_COMMAND
	call RD_STATUS
	btfsc ATA_STATUS,ERR
	goto $+5					; Nastal error disku. Co budeme delat? S*r*m* na to a jdeme dal
	btfsc ATA_STATUS,BSY
	goto $-4					; Bsy <> 0, cekame dal 
	btfss ATA_STATUS,DRDY
	goto $-6

	call WR_FEATURES
	call WR_SC
	call WR_LBA1
	call WR_LBA2
	call WR_LBA3
	call WR_DEVICE
	call WR_COMMAND
	return
;*****************************************
; ve workingu mame adresu registru ktery mame precist, 
; pak v nem vracime jeho hodnotu...
RUTR          
	movwf ATA_ADDRESS 		   ; adresa pozadovaneho registru

	BANK_1
    movlw 0xFF
    movwf DATA_PORT_LOW_TRIS   ; z datove zbernice cteme
    movwf DATA_PORT_HIGH_TRIS
	BANK_0

	bcf ATA_DIOR_N
    nop							; PIO delay min. 120ns (PIO 4) 	
    movfw DATA_PORT_LOW			; Read DD0..D7 IDE
	bsf ATA_DIOR_N

    return
;**********************************************************
; ve workingu mame adresu registru ktery mame zapsat,
; a v reg. TEMPW hodnotu kterou mame do tohoto registru zapsat
RUTW
	movwf ATA_ADDRESS

	BANK_1
    movlw 0x0
    movwf DATA_PORT_LOW_TRIS   ; do datove sbernice zapisujeme
    movwf DATA_PORT_HIGH_TRIS
	BANK_0

    movf TEMPW,w        
    movwf DATA_PORT_LOW			; Write DD0..DD7 IDE 
	clrf DATA_PORT_HIGH

	bcf ATA_DIOW_N
	nop
	bsf ATA_DIOW_N
          
	BANK_1
    movlw 0xff
    movwf DATA_PORT_LOW_TRIS   ; datova sbernice na cteni
    movwf DATA_PORT_HIGH_TRIS
	BANK_0

	return
;**********************************************************
READ_DATA
;	call WAIT_FOR_DATA	; tento odskok do dalsich podprogramu si nemohu, dovolit, protoze mam jen 8bit STACK
	; Wait: ( Bsy=0 AND Drq=1 ) OR err=1
	; 7   6    5  4   3   2    1   0
	; BSY DRDY DF DSC DRQ CORR IDX ERR
	; (cekame az disk bude mit pro nas prichystana data)
	movlw D_STATUS      ; Status 
	call RUTR 
	movwf ATA_STATUS
	btfsc ATA_STATUS,ERR
	goto READ_DATA_CTEME		; Nastal error disku. Co budeme delat? S*r*m* na to a data precteme...

	btfsc ATA_STATUS,BSY
	goto READ_DATA				; Bsy <> 0, cekame dal 
	
	btfss ATA_STATUS,DRQ
	goto READ_DATA				; Drq <> 1, cekame dal 
	
READ_DATA_CTEME

    movlw D_DATA_R
	movwf ATA_ADDRESS

	BANK_1
    movlw 0xFF
    movwf DATA_PORT_LOW_TRIS   ; z datove zbernice cteme
    movwf DATA_PORT_HIGH_TRIS
	BANK_0

	bcf ATA_DIOR_N
    nop							; PIO delay min. 120ns (PIO 4) 	
	nop
    movfw DATA_PORT_LOW			; Read DD0..D7 IDE
	movwf DATA_L
    movfw DATA_PORT_HIGH		; Read DD8..D15 IDE
	movwf DATA_H
	bsf ATA_DIOR_N

    return
;**********************************************************
; stava se, ze obcas nas zajima jen cast vracenych dat, tak ty ktere nas nezajimaji, preskocime
; ocakava parametr v registru TEMP1 (kolik slov ma preskocit)
; pokud TEMP1 = 0 tak preskoci 256 slov
PRESKOC
	call READ_DATA
	decfsz TEMP1,F
	goto PRESKOC
	return
;**********************************************************
; rekne disku na ze pristi instrukce, registry, data.... budou pro mastera
SELECT_DEVICE
	movlw b'11100000'	; adresy budou v LBA, budeme pracovat s masterem
	movwf DEVICE
	call WR_DEVICE
	return
;**********************************************************
ZAPIS_DO_BUFFERU_1	; buffer1 ma 64B a je v bance 3 na adrese 0x190 - 0x1CF
					; jako parametr dostanem TEMP1, kde je pocet bytu k zapisu
					; maximalni hodnota v TEMP1 muze byt 32 (1 slovo = 2 byty)
	INDF_BANK_3		; neprime adresovani na banku 3
	movlw 0x90		; adresa ja 190, devaty byt urcuje banku (0,1 / 2,3) fsr je tedy 90
	movwf FSR		
ZAPIS_DO_BUFFERU_1__ZAPIS
	call READ_DATA
	
	movfw DATA_L
	movwf INDF
	incf FSR,F
	movfw DATA_H
	movwf INDF
	incf FSR,F

	decfsz TEMP1,F
	goto ZAPIS_DO_BUFFERU_1__ZAPIS

	INDF_BANK_0	
	return
;**********************************************************
CLEAR_BUFFER2		; BUFFER2 je 64bytu dat v bance 2 na adrese 0x110 - 0x14F
					; pouziva TEMP1
	movlw .64
	movwf TEMP1
	INDF_BANK_2		; neprime adresovani na banku 2
	movlw 0x10
	movwf FSR
	movlw .0

CLEAR_BEFFER2__CLEAR
	movwf INDF
	incf FSR,F
	decfsz TEMP1,F
	goto CLEAR_BEFFER2__CLEAR

	INDF_BANK_0		; neprime adresovani na banku 0
	return
;**********************************************************
ATA_RESET
	; Resetuje disk zjisti, zda vubec nejaky disk je pripojen
	clrf ATA_ATTRIBUTES	; registr obsahujici bity rikajici co disk umi

	bcf ATA_RESET_N		; resetujeme disk
	call DELAY_25us		; signal reset musi byt min. 25us
	bsf ATA_RESET_N		; koncime s resetem disku

	call WAIT_FOR_READY	; vynulujeme device bit v DEVICE registru (disk musi byt master!), ...
	call SELECT_DEVICE	; ...nastavime bit L - LBA addressing

	call WAIT_FOR_READY
   	movlw b'00000010'	; zakazeme preruseni (ted mam na mysli signal INTRQ z disku)
   	movwf DEVICE_C		; bit nIEN = 1 -> zakazeme preruseni disku (stejne nemame signal INTRQ pripojen)
	call WR_DC			; zapiseme hodnotu do registru DEVICE CONTROL

	movlw b'11100000'	; adresy budou v LBA, budeme pracovat s masterem
	movwf DEVICE
	clrf SECTOR_C
	clrf LBA1	
	clrf LBA2
	clrf LBA3
	clrf FEATURES
	movlw h'00'			; code prikazu nop
	movwf COMMAND
	call WR_BLOCK		; ted provedeme prvni prikaz (nop) a podivame se co nam disk vrati

	call WAIT_FOR_READY
	call RD_DEVICE		; Precteme reg. device. Pokud je disk OK, tak by nam mel vratit to, co jsme do nej predtim zapsaly
	movfw DEVICE
	sublw b'11100000'
	btfsc STATUS,Z		; pokud DEVICE <> b'11100000', tak tu bud disk nemame, nebo je nejakej rozsypanej, nebo je spatne svicivanej (treba SLAVE)
	bsf ATA_ATTRIBUTES,ATA_OK	; 0. bit = 1 -> disk je pritomen, zapnuty a funkcni...

	return		
;**********************************************************
READ_SECTOR
	; Tento podprogram prevezme parametry SECTOR_C (kolik sec. mame precist)
	; a LBA1 - LBA4, kde je ulozena LBA adresa sectoru od ktereho mame cist
	; Postara se o spravne zadani adresy do disku (LBA28 / LBA48) a zavolani prikazu ke cteni...
	; Samotne cteni se musi obslouzit v jine casti programu (podle toho co cteme...)

;	call WAIT_FOR_READY
	; Cekame az Bsy bit = 0 
	call RD_STATUS
	btfsc ATA_STATUS,ERR
	goto $+3					; Nastal error disku. Co budeme delat? S*r*m* na to a jdeme dal
	btfsc ATA_STATUS,BSY
	goto $-4					; Bsy <> 0, cekame dal 


;	call SELECT_DEVICE
	movlw b'11100000'	; adresy budou v LBA, budeme pracovat s masterem
	movwf DEVICE
	call WR_DEVICE

;	call WAIT_FOR_READY_FOR_COMMAND
	call RD_STATUS
	btfsc ATA_STATUS,ERR
	goto $+5					; Nastal error disku. Co budeme delat? S*r*m* na to a jdeme dal
	btfsc ATA_STATUS,BSY
	goto $-4					; Bsy <> 0, cekame dal 
	btfss ATA_STATUS,DRDY
	goto $-6

	btfsc ATA_ATTRIBUTES,LBA48_SUPPORT
	goto READ_SECTOR_LBA48

READ_SECTOR_LBA27		; zadavani adresy v LBA28 je celkem jednoduche, LBA bity 24-27 jsou obsazene v dolnich 4 bitech DEVICE reg.
	clrf FEATURES
	call WR_FEATURES
	call WR_SC
	call WR_LBA1
	call WR_LBA2
	call WR_LBA3
	movfw LBA4			; Z nejvyssi casti adresy...
	andlw b'00001111'	; ...pouzijeme pouze dolni 4bity...
	iorlw b'11100000'	; ...horni 3bity nastavime (LBA adresovani, master)...
	movwf DEVICE		; ...a zapiseme do DEVICE.
	call WR_DEVICE
	movlw 0x20			; Read sector. OPCODE - 20h (with retries) or 21h (without retries)
	movwf COMMAND		; ...podle me to znamena ze prikaz 20h se bude pri neuspechu pokouset znova o cteni....
	call WR_COMMAND		; ...protoze se v novejsich spicifacich jiz prikaz 21h nevyskytuje, pouzivam ke cteni 20h.
	return

READ_SECTOR_LBA48
	; !!! Pripominam ze to co zde pisu (o LBA48) vim ze specifikace ATA8, v praxi jsem LBA48 na zadnem disku jeste nezkousel !!!
	; Zadavani adresy pri LBA48 se o neco lisi nez LBA28. Do registru LBA 1,2,3 se data zadavaji 2x. 
	; Prvi zadavani znamena horni cast adresy, druhe zadavani dolni cast adresy.
	; Znova sem pisu ze v tomto programu vyuzijeme jen LBA o 32bitech (2TB) a ne celych LBA48
	movlw .0
	movwf TEMPW
	movlw D_SECTOR_C    ; vyssi cast parametru SECTOR_C = 0
	call RUTW	
	call WR_SC			; nizci cast parametru SECTOR_C

	movlw .0
	movwf TEMPW
	movlw D_LBA3		; LBA bity 47:40
	call RUTW
	movlw .0
	movwf TEMPW
	movlw D_LBA2		; LBA bity 39:32
	call RUTW
	movfw LBA4
	movwf TEMPW
	movlw D_LBA1		; LBA bity 31:24
	call RUTW

	call WR_LBA3		; LBA bity 23:16
	call WR_LBA2		; LBA bity 15:8
	call WR_LBA1		; LBA bity  7:0
	movlw h'24'			; pri LBA48 se musi pouzit tohoto prikazu ke cteni (READ SECTOR(S) EXT - 24h, PIO data-in)
	movwf COMMAND
	call WR_COMMAND
	return
;**********************************************************
IDENTIFY_DEVICE
	; ted uz vime, ze mame pripojen nejaky disk, tento podprogram provede prikaz 
	; identify device a zjisti co je disk zac. Nektere dulezite informace ulozi 
	; (nastavi byty v ATA_ATTRIBUTES) a jmenovku disku hodi do bufferu

	; rekneme disku, ze s nim chcem pracovat (s masterem)
	call WAIT_FOR_READY
	call SELECT_DEVICE
	
	; podivame se zda tu vubec disk je a co podporuje (LBA)
	call WAIT_FOR_READY	; celame nez bude disk opet ready pro dalsi prikazy

	movlw b'11100000'	; adresy budou v LBA, budeme pracovat s masterem
	movwf DEVICE
	clrf SECTOR_C
	clrf LBA1	
	clrf LBA2
	clrf LBA3
	clrf FEATURES
	movlw 0xEC			; code prikazu IDENTIFY DEVICE
	movwf COMMAND
	call WR_BLOCK

	; pokud se neco nepodelalo, dostanem 256 16ti bitovych slov kde je napsano co disk umi a co je to zac...
	; slova cisluji od nuly, (tzn. ze slov je 0-255)
	movlw .27		; prvnich 27 slov je pro nas nepotrebnych
	movwf TEMP1
	call PRESKOC
	
	; [27-46] model mumber (ASCI retezec s nazvem disku)
	; tady precteme 20 slov a rovnou je odesleme do pric
		; pokud nekde od disku dostavame ASCII retezec jsou data nasledujici: 
		; pr. disk nam posila string “Copyright”
		;		1. DATA_H = 'C' 
		; 		1. DATA_l = 'o'
		;		2. DATA_H = 'P' 
		; 		2. DATA_l = 'y'
	movlw .20		; dalsich 20 slov obsahuje 40 s ASCII znaku s nazvem disku
	movwf TEMP1
	call ZAPIS_DO_BUFFERU_1
		
	; ted jsme uz precetli 47 slov z 256 :-)
	movlw .2		; dalsi 2 slova jsou nam k nicemu
	movwf TEMP1
	call PRESKOC
		
	call READ_DATA	; slovo 49 - capabilities (schopnosti)
			; 15:14 Reserved for the IDENTIFY PACKET DEVICE command.
			;    13 1 = Standby timer values as specified in this standard are supported
			;       0 = Standby timer values shall be managed by the device
			;    12 Reserved for the IDENTIFY PACKET DEVICE command.
			;    11 1 = IORDY supported
			;       0 = IORDY may be supported
			;    10 1 = IORDY may be disabled
			;     9 1 = LBA supported
			;     8 1 = DMA supported.
			;   7:0 Retired	
	btfsc DATA_H,1	;bit 9 = 1 -> LBA supported
	bsf ATA_ATTRIBUTES,LBA_SUPPORT

	;precetli jsme 50 slov
	movlw .10
	movwf TEMP1
	call PRESKOC
	
	call READ_DATA	; 60
	movfw DATA_L
	movwf PARAM_MAX_LBA1		; nejnizsi cast adresy
	movfw DATA_H
	movwf PARAM_MAX_LBA2	
	
	call READ_DATA	; 61
	movfw DATA_L
	movwf PARAM_MAX_LBA3
	movfw DATA_H
	movwf PARAM_MAX_LBA4		; nejvyssi cast adresy
	
	;precetli jsme 62 slov, zbyva 194
	movlw .21
	movwf TEMP1
	call PRESKOC

	; 83 slov, na rade je slovo 83 (pripominam ze slova jsou cislovana od nuly)
	call READ_DATA	; 83 - command supported. Tady nas zajima bit 10 - 1 = 48-bit Address feature set supported
	btfsc DATA_H,2	; pokud disk umi LBA 48 pripiseme tuto skutecnost do ATA_ATTRIBUTES
	bsf ATA_ATTRIBUTES,LBA48_SUPPORT

	;precetli jsme 84 slov
	movlw .16
	movwf TEMP1
	call PRESKOC
		
	btfss ATA_ATTRIBUTES,LBA48_SUPPORT
	goto INIT_ATA__NOT_SUPPORT_LBA48
			; pokud je podporovano LBA 48, nachazi se ve slovech [100-103] skutecny pocet sektoru 
			; do slov 60-61 by se sice vesel pocet sektoru u disku do 2TB, podle standardu se tam ale zapisuje pouze hodnota max pro LBA 28 (cca 120 GB)
			; mi precteme ale jen nejnizsi 2 slova, predpokladam totiz ze disk neni vetsi jak 2TB
			call READ_DATA	; 100
			movfw DATA_L
			movwf PARAM_MAX_LBA1		; nejnizsi cast adresy
			movfw DATA_H
			movwf PARAM_MAX_LBA2	

			call READ_DATA	; 101
			movfw DATA_L
			movwf PARAM_MAX_LBA3
			movfw DATA_H
			movwf PARAM_MAX_LBA4		; nejvyssi cast adresy			
		goto INIT_ATA__DALSI
INIT_ATA__NOT_SUPPORT_LBA48
	movlw .2	; 100, 101
	movwf TEMP1
	call PRESKOC	
INIT_ATA__DALSI
	; precetli jsme 102 slov
	movlw .4	; 102, 103, 104, 105
	movwf TEMP1
	call PRESKOC

	call READ_DATA	; slovo 106 - pokud bit 15=0 a bit 14=1, tak obsahuje pravdive informace
						; pro nas je podstatne, ze pokud je bit 12 = 1, tak sektor je vetsi nez 256 slov
						; pokud je sektor vetsi nez 256 slov, je jeho velikost ve slovech [117-118]
	btfsc DATA_H,7
	goto INIT_ATA__DALSI2
	btfss DATA_H,6
	goto INIT_ATA__DALSI2
	btfsc DATA_H,4
	bsf ATA_ATTRIBUTES,BIG_SECTOR
INIT_ATA__DALSI2
	; precteno 107, zbyva 149
	movlw .149	; 107 - 256
	movwf TEMP1
	call PRESKOC
		
	; ted vime co mame za disk, tak se na to jdem podivat...
	; pokud disk splnuje vsechny nase pozadavky, tak nastavime 7 bit v ATA_ATTRIBUTES
	bcf ATA_ATTRIBUTES,APPLICABLE	
	btfss ATA_ATTRIBUTES,LBA_SUPPORT
	return
	; pokud jsme tady, disk podporuje LBA (dneska se jich uz moc nevidi, co by LBA neumeli)
	btfsc ATA_ATTRIBUTES,BIG_SECTOR
	return
	; mazec, disk ma velikost sektoru 256 slov, vetsi naroky na disk nemam :-)
	bsf ATA_ATTRIBUTES,APPLICABLE ; disk umi to co potrebujeme...	

	return
;**************************************************************************
;**********************************************************
; CEKACI PROCEDURY
;**********************************************************
DELAY_25us
	; pouziva TEMP1
	; (Fosc = 20 MHz , instr. cyklus= 0.20 us) 25us / 0.20 us = 125 instrukcnich cyklu
	; (Fosc = 16 MHz , instr. cyklus= 0.25 us) 25us / 0.25 us = 100 instrukcnich cyklu
	; (Fosc = 04 MHz , instr. cyklus= 1.00 us) 25us / 1.00 us =  25 instrukcnich cyklu	
        MOVLW 0x2A  ;42 DEC -> Delay 127 cycles
        ;MOVLW 0x21   ;33 DEC -> Delay 100 cycles
        ;MOVLW 0x08  ;25 DEC -> Delay  25 cycles
        MOVWF TEMP1
        DECFSZ TEMP1,F
        GOTO $-1
	;End of Delay
	return
;**************************************************************************
WAIT_FOR_READY
	; Cekame az Bsy bit = 0 
	; (cekame az disk nebude zaneprazdnen)
	call RD_STATUS
	movfw ATA_STATUS
	andlw b'10000000'
	btfsc STATUS,Z
	return
	goto WAIT_FOR_READY
;**************************************************************************
;WAIT_FOR_READY_FOR_COMMAND
;	call WAIT_FOR_READY
;	btfss ATA_STATUS,DRDY
;	goto WAIT_FOR_READY_FOR_COMMAND
;	return
;**************************************************************************
