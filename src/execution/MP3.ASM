START
	call INIT_CONFIG	; nakonfiguruje preruseni, WDT, USART, pull ups...
	call INIT_PORT		; nastavy trisy, a porty do vychozi polohy

	call DELAY_25us 	; chvili pockame, protoze napjeti zdroje co mam doma (stary PC-AT zdroj)
	call DELAY_25us 	; zezacatku dost kolisa a nepomuze tomu ani POR...
	call DELAY_25us

;LOOP
;	movlw 'O'
;	call WR_USART
;	movlw 'K'
;	call WR_USART
;	call DELAY_200ms
;	call DELAY_200ms
;	goto LOOP


	PROG_PAGE_1
	call VS_INIT
	PROG_PAGE_3
	call VS_LOAD_PLUGIN
	PROG_PAGE_0

	call ATA_RESET				; resetujeme disk, koukneme zda tu nejakej mame
	btfss ATA_ATTRIBUTES,ATA_OK
	goto $-2					; pokud neni pripojen disk, tak se jej pokousime neustale najit...
	nop							; ...pokud tam zadny disk neni, tak bychom se stejne ani sem nemeli dostat, protoze budem porad cekat na WAIT_FOR_READY

	call IDENTIFY_DEVICE		; koukneme co disk umi

CEK_PRIKAZ_01h
	PROG_PAGE_1
	call CEKEJ_PRIKAZ
	PROG_PAGE_0

	movfw 0x078					; prvni byte prikazoveho zasobniku
	clrf PRIJATYCH_DAT			; prikaz byl vybran -> prazdny zasobnik
	sublw h'01'					; ...pokud to byl prikaz 01h...
	btfss STATUS,Z
	goto CEK_PRIKAZ_01h

	movfw ATA_ATTRIBUTES		; ...vodesleme zpet vlastnosti disku a jeho jmenovku (vis. popis protokolu)
	call WR_USART
	call ODESLI_MODEL_NUMBER	; odesleme jmeno disku 


	PROG_PAGE_2
	call SCAN_MBR				; najdeme oddily s FAT32 a jejich seznam dame do bufferu 2
	PROG_PAGE_0
CEK_PRIKAZ_02h_03h
	PROG_PAGE_1
	call CEKEJ_PRIKAZ			; pockame si na prikaz
	clrf STAV_PRIKAZU			; smazeme registr signalizujici platnost prikazu
	call PRIKAZ_02h				; testujeme zda prisel prikaz 02h, pokud ano tak jej provedeme a nastavime platnost prikazu
	PROG_PAGE_2
	call PRIKAZ_03h				; ---//---
	PROG_PAGE_0
	btfss STAV_PRIKAZU,0		; Pokud si zadna z procedur prikaz neprevzala, ...
	clrf PRIJATYCH_DAT			; ...vymazeme zasobnik prikazu. (prikaz neni pro tuto chvili platny)
	btfss ATA_ATTRIBUTES,FAT32_LOAD	; cekame dokud nedojde k nasteni nejakeho oddilu
	goto CEK_PRIKAZ_02h_03h		; pokud byl oddil vporadku nacten, pokracujeme...

;********************************************************************************************************************
;********************************************************************************************************************
;********************************************************************************************************************
;********************************************************************************************************************
BIG_LOOP	
	; Tady ta smycka beha po nacteni disku a nejake FATky porad dokola.
	; Pri kazdem prubehu smyckou vyresime prikazy, ktere prisly, a pokud prehravame 
	; nejakou mp3 tak dekoder nakrmime jednim sektorem...
	; Mimo to je v teto smycce osefovano, ze kdyz skonci mp3, nacteme dalsi... (v zavislosti na nastaveni repeatu)
	; pokud se dostaneme na konec slozky a je nastaveno vyhledavani dalsich slozek, tak nejakou najdeme...

	movfw PRIJATYCH_DAT
	andlw h'FF'
	btfsc STATUS,Z
	goto BIG_LOOP__NENI_PRIKAZ
	
	clrf STAV_PRIKAZU			; smazeme registr signalizujici platnost prikazu
	; Pokud jsme tady, tak prisel nejaky prikaz, jdem predat prikaz jednotlivym proceduram
	PROG_PAGE_1
	call PRIKAZ_02h				; testujeme zda prisel prikaz 02h, pokud ano tak jej provedeme a nastavime platnost prikazu
	PROG_PAGE_2
	call PRIKAZ_03h				; --- // ---
	PROG_PAGE_1
	call PRIKAZ_04h				; --- // ---
	call PRIKAZ_05h				; --- // ---
	call PRIKAZ_06h				; --- // ---
	call PRIKAZ_07h				; --- // ---
	call PRIKAZ_08h				; --- // ---
	call PRIKAZ_09h				; --- // ---
	call PRIKAZ_0Ah				; --- // ---
	PROG_PAGE_2
	call PRIKAZ_0Bh				; --- // ---
	call PRIKAZ_0Ch				; --- // ---
	call PRIKAZ_0Dh				; --- // ---
	PROG_PAGE_1

	call PRIKAZ_80h				; --- // ---
	call PRIKAZ_81h				; --- // ---
	call PRIKAZ_82h				; --- // ---
	call PRIKAZ_83h				; --- // ---
	call PRIKAZ_84h				; --- // ---
	PROG_PAGE_2
	call PRIKAZ_85h				; --- // ---
	call PRIKAZ_86h				; --- // ---
	call PRIKAZ_87h				; --- // ---
	PROG_PAGE_0
	
	btfss STAV_PRIKAZU,0		; Pokud si zadna z procedur prikaz neprevzala, ...
	clrf PRIJATYCH_DAT			; ...vymazeme zasobnik prikazu. (prikaz neni pro tuto chvili platny)

BIG_LOOP__NENI_PRIKAZ
	movfw KONST_NECINNOSTI1
	andwf KONST_NECINNOSTI2,w
	sublw h'FF'
	btfsc STATUS,Z
	goto BIG_LOOP__NO_STANDBY	; pokud je KONST_NECINNOSTI = h'FFFF', tak disk nechame porad zapnuty
	
	movfw CITAC_NECINNOSTI1
	iorwf CITAC_NECINNOSTI2,w
	btfsc STATUS,Z
	call ATA_STANDBY			; pokud z disku jsme jiz dlouho nic necetli, tak jej dame do STANDBY
								; potrebna doba je v KONST_NECINNOSTI

BIG_LOOP__NO_STANDBY

	btfss PREH_STAV0,0			; Pokud je zvoleno play,...
	goto MP3_NOT_PLAY

	btfss PREH_STAV0,1			; ...a je co prehravat...
	goto MP3_NOT_PLAY
	
	movfw PREH_DATA_POZICE
	subwf CLUSTER_SIZE,W
	btfss STATUS,Z				; ...podivame se zda jiz nejsme na konci clusteru...
	goto SEND_MP3_DATA

	movfw PREH_D_FRAGMENT1		; ...pokud ano, podivame se zda nejsme na posledni casti fragmentu...
	iorwf PREH_D_FRAGMENT2,w
	btfss STATUS,Z
	goto BIG_LOOP_DEC_FRAGMENT	; ...pokud ne, tak PREH_D_FRAGMENT1-- ; PREH_DATA_CL++

	movfw PREH_DATA_CL1			; ...pokud jo, tak si najdeme dalsi cluster v retezci.
	movwf CLUSTER1
	movfw PREH_DATA_CL2
	movwf CLUSTER2
	movfw PREH_DATA_CL3
	movwf CLUSTER3
	movfw PREH_DATA_CL4
	movwf CLUSTER4

	clrf PREH_DATA_POZICE
	call NEXT_CLUSTER
	
	btfss POZICE,0				; Pokud byl cluster posledni v retezci...
	goto BIG_LOOP_DALSI_FRAGMENT

	call DALSI_SKLADBA			; ...tak najdeme dalsi soubor co se ma prehrat (pokud je nastaven repeat a dalsi kraviny)
	; otestujeme zda se ma nejaka dalsi mp3 prehravat
	btfss PREH_STAV0,0			; Je zvoleno play?
	goto MP3_NOT_PLAY
	btfss PREH_STAV0,1			; Je co prehravat?
	goto MP3_NOT_PLAY
	goto SEND_MP3_DATA

BIG_LOOP_DALSI_FRAGMENT
	movfw CLUSTER1
	movwf PREH_DATA_CL1
	movfw CLUSTER2
	movwf PREH_DATA_CL2
	movfw CLUSTER3
	movwf PREH_DATA_CL3
	movfw CLUSTER4
	movwf PREH_DATA_CL4

	call ZJISTI_FRAGMENT

	movfw FRAGMENT1
	movwf PREH_D_FRAGMENT1
	movfw FRAGMENT2
	movwf PREH_D_FRAGMENT2

	;movlw 'F'
	;call WR_USART

	goto SEND_MP3_DATA
BIG_LOOP_DEC_FRAGMENT
	;----------------------------
	movfw VS_LOUDNESS
	andlw h'FF'
	btfsc STATUS,Z				; pokud je nastaven nejaky filter, tak jej reaktivujeme...
	goto BIG_LOOP_DEC_FRAGMENT_NO_PLUG

	movlw VSADDR_AIADDR
	movwf TEMP1
	movlw 0x00
	movwf TEMP2	
	movlw 0x42
	movwf TEMP3
	PROG_PAGE_1
	call VS_WR_REG				; nastavime zacatek uzivatelskeho programu (0x4200)
	PROG_PAGE_0

	movlw VSADDR_AICTRL0
	movwf TEMP1
	movfw VS_LOUDNESS
	movwf TEMP2	
	movlw 0x00
	movwf TEMP3
	PROG_PAGE_1	
	call VS_WR_REG				; nastavime pozadovany filter
	PROG_PAGE_0

BIG_LOOP_DEC_FRAGMENT_NO_PLUG
	;----------------------------

	; PREH_D_FRAGMENT1 --
	movlw .1
	subwf PREH_D_FRAGMENT1,f
	btfsc STATUS,C
	goto $+2
	subwf PREH_D_FRAGMENT2,f

	; PREH_DATA_CL ++
	incf PREH_DATA_CL1,f
	btfss STATUS,Z
	goto $+8
	incf PREH_DATA_CL2,f
	btfss STATUS,Z
	goto $+5
	incf PREH_DATA_CL3,f
	btfss STATUS,Z
	goto $+2
	incf PREH_DATA_CL4,f

	clrf PREH_DATA_POZICE

SEND_MP3_DATA
	btfss PREH_STAV1,0			; 0. bit = 1 => previjeni mp3 dopredu
	goto NOT_MP3_REWIND_FORWARD
	bsf VSREG_MODE_L,1			; fast forward on

	btfss PREH_STAV1,2			; 2. bit = 1 => previji se pomalu, vzdy se po nejake dobe kratky usek souboru prehraje	
	goto MP3_REWIND_FORWARD

	movfw PREH_CITAC_PREV		; MP3 previjime pomalu...
	sublw .20					; ...podivame se kolik sektoru jsme previnuly...
	btfsc STATUS,C				; ...pokud jich je vic jak 20...
	goto MP3_REWIND_FORWARD		; 
	
	bcf VSREG_MODE_L,1			; ...tak dalsi pustime normalne. (fast forward off)

	movfw PREH_CITAC_PREV
	sublw .25
	btfss STATUS,Z				; pokud jsme jich uz normalne pustily 5, ... (25-20)
	goto MP3_REWIND_FORWARD

	clrf PREH_CITAC_PREV		; ...vymazeme citac previjeni (zas nejaky sektory pustime rychle)
MP3_REWIND_FORWARD
	movlw VSADDR_MODE
	movwf TEMP1
	movfw VSREG_MODE_L
	movwf TEMP2
	clrf TEMP3
	PROG_PAGE_1	
	call VS_WR_REG
	PROG_PAGE_0
	
	btfsc PREH_STAV1,2			; 2. bit = 1 => previji se pomalu, vzdy se po nejake dobe kratky usek souboru prehraje	
	incf PREH_CITAC_PREV,f
NOT_MP3_REWIND_FORWARD

	movfw PREH_DATA_CL1			; Mame zjisteny cluster a jeho cast, kterou mame prehravat...
	movwf CLUSTER1
	movfw PREH_DATA_CL2
	movwf CLUSTER2
	movfw PREH_DATA_CL3
	movwf CLUSTER3
	movfw PREH_DATA_CL4
	movwf CLUSTER4
	movfw PREH_DATA_POZICE
	movwf POZICE

	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu dat na disku...
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR			; dame prikaz precist data...

	bsf MP3_CS					; po SI posilam data
	movlw .0					; posilame celkem 256 slov
	movwf TEMP1		
SEND_MP3_WORD
	PROG_PAGE_1
	call WAIT_FOR_VSDREQ
	PROG_PAGE_0
	call READ_DATA
	movfw DATA_L
	PROG_PAGE_1
	call VS_WR_BYTE
	movfw DATA_H
	call VS_WR_BYTE
	PROG_PAGE_0
	decfsz TEMP1,f	
	goto SEND_MP3_WORD

	incf PREH_DATA_POZICE,f
MP3_NOT_PLAY

	btfss PREH_STAV0,0			; Pokud je zvoleno play,...
	goto BIG_LOOP
	btfsc PREH_STAV0,1			; ...neni co prehravat...
	goto BIG_LOOP
	btfsc PREH_STAV0,3			; ...ma se pokracovat v prehravani...
	goto BIG_LOOP
	btfsc PREH_STAV0,4			; ...neni zvolen repeat...
	goto BIG_LOOP
	btfss PREH_STAV0,6			; ...ma se pokracovat v prehravani v dalsich slozkach...
	goto BIG_LOOP

	; jdeme prozkoumavat podadresare v aktualnim adresari, nebo hledat dalsi adresare s MP3
	PROG_PAGE_2
	goto HLEDEJ_ADRESAR
HLEDEJ_ADRESAR_RETURN
	PROG_PAGE_0

	goto BIG_LOOP
;********************************************************************************************************************
;********************************************************************************************************************
;********************************************************************************************************************
;********************************************************************************************************************
DALSI_SKLADBA
	; tato procedura je volana, kdyz skonci mp3, aby nasla v adresari dalsi mp3 ktera se ma prehravat...
	call ULOZ_KONFIGUTACI

;	bcf PREH_STAV0,0		; 0. bit = 	0 => stop nebo pauza (nic nehraje)
	bcf PREH_STAV0,1		; 1. bit = 	0 => neni zadny soubor k prehravani (nastaveni bitu play nema zadny ucinek)
	bcf PREH_STAV0,2		; 2. bit = 	1 => je nastaven, kdyz se zmeni prehravany soubor (bez volani prikazu) do doby, nez prijde prikaz na dotaz STAVU... (81h)
	bcf PREH_STAV1,0		; 0. bit =  0 => normalni prehravani (mp3 se nepreviji)
	btfsc PREH_STAV0,3		; 3. bit = 	0 => po skonceni souboru se pokracuje v prehravani (zavisi na nastaveni repeatu)
	return

; PREH_STAV0
; 	4. bit = 	0 => repeat off
;				1 => repeat on
; 	5. bit =	0 => repeat adresare (prvni cluster adresare musi byt nastaven v PREH_ADDR_ZACATEK_CL[1-4] )
;				1 => repeat souboru (po skonceni prehravani souboru se ten samy soubor zacne prehravat znova)
	btfss PREH_STAV0,4
	goto DALSI_SKLADBA_NO_R_S
	btfss PREH_STAV0,5
	goto DALSI_SKLADBA_NO_R_S	
DALSI_SKLADBA_REPAT_SOUBORU
	movfw PREH_ADR_CL1
	movwf CLUSTER1
	movfw PREH_ADR_CL2
	movwf CLUSTER2
	movfw PREH_ADR_CL3
	movwf CLUSTER3
	movfw PREH_ADR_CL4
	movwf CLUSTER4
	movfw PREH_ZAZNAM1
	movwf ZAZNAM1
	movfw PREH_ZAZNAM2
	movwf ZAZNAM2

	PROG_PAGE_1
	call SKOC_NA_ZAZNAM
	PROG_PAGE_0
	btfsc POZICE,0				; tento test by tu byt nemusel, protoze jsme jiz tento soubor hrali, jeden ale nikdy nevi...
	return
	PROG_PAGE_1
	call FILE_INFO
	PROG_PAGE_0

	INDF_BANK_2
	; ...nastavime jej jako prehravany soubor.
	movlw 0x1C					; 13. byte bufferu 2
	movwf FSR
	movfw INDF
	movwf PREH_DATA_CL1
	movwf CLUSTER1
	incf FSR,f
	movfw INDF
	movwf PREH_DATA_CL2
	movwf CLUSTER2
	incf FSR,f
	movfw INDF
	movwf PREH_DATA_CL3
	movwf CLUSTER3
	incf FSR,f
	movfw INDF
	movwf PREH_DATA_CL4
	movwf CLUSTER4

	call ZJISTI_FRAGMENT

	movfw FRAGMENT1
	movwf PREH_D_FRAGMENT1
	movfw FRAGMENT2
	movwf PREH_D_FRAGMENT2

	goto DALSI_SKLADBA_PLAY		; nic jineho nemusime nastavovat, protoze hrajeme ten samy soubor co predtim
DALSI_SKLADBA_NO_R_S
; PREH_STAV0
; 	4. bit = 	0 => repeat off
;				1 => repeat on
; 	5. bit =	0 => repeat adresare (prvni cluster adresare musi byt nastaven v PREH_ADDR_ZACATEK_CL[1-4] )
;				1 => repeat souboru (po skonceni prehravani souboru se ten samy soubor zacne prehravat znova)
	; tak ted jdem hledat dalsi soubor v adresari...
	
; 	HL_PARAMETRY 	-- parametry hledani
;	HL_ADR_CL[1-4]	-- prnvi cluster prohledavaneho adresare
;	ZAZNAM[1-2]		-- zaznam od ktereho hledame
	movlw b'00000110'
	movwf HL_PARAMETRY
	movfw PREH_ADR_CL1
	movwf HL_ADR_CL1
	movfw PREH_ADR_CL2
	movwf HL_ADR_CL2
	movfw PREH_ADR_CL3
	movwf HL_ADR_CL3
	movfw PREH_ADR_CL4
	movwf HL_ADR_CL4
	movfw PREH_ZAZNAM1
	movwf ZAZNAM1
	movfw PREH_ZAZNAM2
	movwf ZAZNAM2
	
	PROG_PAGE_1
	call HLEDEJ
	PROG_PAGE_0	

	INDF_BANK_2
	movlw 0x30
	movwf FSR
	movfw INDF
	sublw h'06'
	btfsc STATUS,Z
	goto DALSI_SKLADBA_MAME_SOUBOR

	; zadny dalsi mp3 soubor v adresari neni...
	btfss PREH_STAV0,4				; ..podivame se, zda neni nastaven repeat slozky
	return

	; je nastaven repeat slozky a uz neni co prehravat. Jdem hledat prvni mp3 ve slozce...

	; HL_PARAMETRY
	;		7. bit - tento bit nelze nastavit uzivatelem
	;				= 0 > adresar je ROOT
	;				= 1 > adresar neni ROOT	
	movlw b'00000110'				; parametry hledani, pokud hledame prvni mp3 adresari ktery neni ROOT 
									; (prvni zaznam je ukazatel na predchozi adresar)
	btfss HL_PARAMETRY,7
	movlw b'00001110'				; parametry hledani, pokud hledame prvni mp3 v ROOT adresari (prvni zaznam)
	movwf HL_PARAMETRY

	movlw h'01'						; prvni cluster prohledavaneho adresare mame jiz nastaven,
	movwf ZAZNAM1					; parametry taky, ted jen zaznam od klereho hledame... 
	clrf ZAZNAM2					; (pokud hledame v ROOTu, hledame prvni zaznam)

	PROG_PAGE_1
	call HLEDEJ
	PROG_PAGE_0	

	INDF_BANK_2
	movlw 0x30
	movwf FSR
	movfw INDF
	sublw h'06'
	btfss STATUS,Z
	return							; sem bychom se nemeli dostat, protoze kdyz uz neco hralo, tak tu nejaky soubor musi byt?!
	;goto DALSI_SKLADBA_MAME_SOUBOR
DALSI_SKLADBA_MAME_SOUBOR
	INDF_BANK_2
	movlw 0x3C
	movwf FSR
	movfw INDF
	movwf PREH_DATA_CL1
	movwf CLUSTER1
	incf FSR,f
	movfw INDF
	movwf PREH_DATA_CL2
	movwf CLUSTER2
	incf FSR,f
	movfw INDF
	movwf PREH_DATA_CL3
	movwf CLUSTER3
	incf FSR,f
	movfw INDF
	movwf PREH_DATA_CL4
	movwf CLUSTER4
	incf FSR,f
	movfw INDF
	movwf PREH_ZAZNAM1
	incf FSR,f
	movfw INDF
	movwf PREH_ZAZNAM2

	call ZJISTI_FRAGMENT

	movfw FRAGMENT1
	movwf PREH_D_FRAGMENT1
	movfw FRAGMENT2
	movwf PREH_D_FRAGMENT2


DALSI_SKLADBA_PLAY
	clrf PREH_DATA_POZICE
	bsf PREH_STAV0,0
	bsf PREH_STAV0,1			; nastavime si vlastosti prehravani: (PREH_STAV[0-1])
	bsf PREH_STAV0,2

	PROG_PAGE_1
	call VS_SOFT_RESET

	bcf VSREG_MODE_L,1			; prehravame normalni rychlosti 
	bcf PREH_STAV1,0			; prehravame normalni rychlosti 
	
	movlw VSADDR_MODE
	movwf TEMP1
	movfw VSREG_MODE_L
	movwf TEMP2
	clrf TEMP3
	call VS_WR_REG
	PROG_PAGE_0
	
	return
;********************************************************************************************************************
INIT_PORT
	BANK_1

	movlw b'10010001' 			; bity SO a DREQ jako vstupy (signaly z dekoderu)
	movwf MP3_PORT_TRIS
	movlw b'00000000'			; adresovani disku jako vystupy
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
	BANK_0
	MOVLW b'00110001'	; preddelicka 1:8, timer1 on, interni osc
	MOVWF T1CON			; 
	clrf TMR1H
	clrf TMR1L

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
	bsf PIE1, TMR1IE	; Enable Timer1 interrupt

	movlw b'11000000' 	; povolime preruseni na vnejsi zarizeni (USART)				
	movwf INTCON

	movlw b'00100110'	;konfigurace USARTu (asynchronni, 8bit, bez parity, rychle - (BRGH = 1))
	movwf TXSTA
	BANK_0
	movlw b'10010000'	;zapnu USART
	movwf RCSTA
	BANK_1
	movlw .64 		; Fosc = 20 MHz, BRGH=1 => rychlost = 19231 bps
	;movlw .129 	; Fosc = 20 MHz, BRGH=1 => rychlost =  9615 bps
	;movlw .103 	; Fosc = 16 MHz, BRGH=1 => rychlost =  9615 bps
	movwf SPBRG	

	movlw b'00000111'
	movwf ADCON1		; vsechny vstupy (RA,RE) jako digitalni
	BANK_0	
	clrf ADCON0			; pro jistotu (vypneme A/D prevodniky)

#IF SPI_SOFTWARE==1
;spi setup
	BANK_1
	clrf SSPSTAT
	bsf SSPSTAT,CKE
	BANK_0
	clrf SSPCON			; SPI master, 5MHz clock
	bsf SSPCON,SSPEN	; enable port
#ENDIF
; mastaveni dulezitych registru
	clrf PRIJATYCH_DAT	; zasobnik prikazu prazdny...
	movlw h'70'	
	movwf KONST_NECINNOSTI1
	movlw h'17'			; 1770h = 6000d => pri 0.1s preruseni 10 minut
	movwf KONST_NECINNOSTI2

	clrf PREH_ADR_CL1
	clrf PREH_ADR_CL2
	clrf PREH_ADR_CL3
	clrf PREH_ADR_CL4
	clrf PREH_ZAZNAM1
	clrf PREH_ZAZNAM2
	clrf PREH_STAV0
	clrf PREH_STAV1

; nacteni konfigurace z EEPROM
	BANK_2
	clrf EEADR
	BANK_3
	bsf EECON1,RD
	BANK_2
	movfw EEDATA
	BANK_0
	movwf VSREG_VOL_L

	BANK_2
	incf EEADR,f
	BANK_3
	bsf EECON1,RD
	BANK_2
	movfw EEDATA
	BANK_0
	movwf VSREG_VOL_H
	
	BANK_2
	incf EEADR,f
	BANK_3
	bsf EECON1,RD
	BANK_2
	movfw EEDATA
	BANK_0
	movwf PREH_STAV0

	BANK_2
	incf EEADR,f
	BANK_3
	bsf EECON1,RD
	BANK_2
	movfw EEDATA
	BANK_0
	movwf PREH_STAV1
	return
;**********************************************************
WR_EEPROM				; zapíše data z EEDATA na místo EEADR
	BANK_2
	movfw EEDATA
	BANK_0
	movwf TEMP1			; zapisovanou hodnotu dame do TEMP1
	BANK_3
	bsf EECON1,RD
	BANK_2
	subwf EEDATA,W		; podivame se, zda nechceme zapisovat hodnotu, ktera uz je zde ulozena...
	BANK_0
	btfsc STATUS,Z
	return				; pokud ano, tak nic nezapisujeme a koncime
	movfw TEMP1
	BANK_2
	movwf EEDATA
	BANK_3	
	bcf INTCON,GIE		; Zákaz pøerušení
	bsf EECON1,WREN		; Povolení zápisu
	movlw h'55'			; zapiš hodnotu
	movwf EECON2 		; do EECON2
	movlw h'AA'			; zapiš další
	movwf EECON2 		; do EECON2
	bsf EECON1,WR 		; Zahájení zápisu
	bsf INTCON,GIE 		; Povol pøerušení		
	btfsc EECON1,WR		; èekáme, než se dokonèí zápis
	goto $-1	
	bcf EECON1,EEIF
	BANK_0
	return
;**********************************************************
ULOZ_KONFIGUTACI
	; uloží do EEPROMy natavení
	BANK_2	
	movlw .0
	movwf EEADR
	BANK_0
	movfw VSREG_VOL_L
	BANK_2
	movwf EEDATA
	call WR_EEPROM

	BANK_2
	movlw .1
	movwf EEADR
	BANK_0
	movfw VSREG_VOL_H
	BANK_2
	movwf EEDATA
	call WR_EEPROM

	BANK_2
	movlw .2
	movwf EEADR
	BANK_0
	movfw PREH_STAV0
	BANK_2
	movwf EEDATA
	call WR_EEPROM

	BANK_2
	movlw .3
	movwf EEADR
	BANK_0
	movfw PREH_STAV1
	BANK_2
	movwf EEDATA
	call WR_EEPROM

	INDF_BANK_0
	movlw .4
	movwf TEMP2
	movlw 0x40					; POCATEK_DAT1
	movwf FSR
ULOZ_KONFIGUTACI_LOOP1
	movfw TEMP2
	BANK_2
	movwf EEADR
	movfw INDF
	movwf EEDATA
	incf FSR,f
	call WR_EEPROM
	; BANK_2	; neni potreba, protoze z predchozi proceduru se vracime v BANCE 0
	incf TEMP2,f
	movfw TEMP2
	sublw .8
	btfss STATUS,Z
	goto ULOZ_KONFIGUTACI_LOOP1

	;INDF_BANK_0
	;movlw .9
	;movwf TEMP2
	movlw 0x62					; PREH_ADR_CL1		equ 0x062
	movwf FSR
ULOZ_KONFIGUTACI_LOOP2
	movfw TEMP2
	BANK_2
	movwf EEADR
	movfw INDF
	movwf EEDATA
	incf FSR,f
	call WR_EEPROM
	; BANK_2	; neni potreba, protoze z predchozi proceduru se vracime v BANCE 0
	incf TEMP2,f
	movfw TEMP2
	sublw .19
	btfss STATUS,Z
	goto ULOZ_KONFIGUTACI_LOOP2

	
	return
;**********************************************************
WR_USART	; odesle slovo ve workingu po USARTu
			; prijimani dat je reseno prez preruseni...
	BANK_1	
	btfss TXSTA,1 
	goto WR_USART	; cekame do chvile nez bude pripraven transmit buffer 

	BANK_0	
	movwf TXREG
	return
;**********************************************************
; tento podprogram bude pro budouci praci zbytecny, je zde jen proto, abych na PC videl ze program byl spusten...
;POZDRAV  ; odesle po seriove lince pozdrav
;	movlw 'A'	
;	call WR_USART
;	movlw 'h'
;	call WR_USART
;	movlw 'o'
;	call WR_USART
;	movlw 'j'
;	call WR_USART
;	movlw '!'
;	call WR_USART
;	return
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
ODESLI_BUFF2_HIGH
	; odesle z horni poloviny bufferu2 tolik bytu, kolik je v TEMP1
	INDF_BANK_2	; BUFFER_2 je v bance 2
	movlw 0x30	; horni pulka od adresy 30h
	movwf FSR
ODESLI_BUFF2_HIGH_ODESILANI
	movfw INDF
	call WR_USART
	incf FSR,F	
	decfsz TEMP1,F
	goto ODESLI_BUFF2_HIGH_ODESILANI

	INDF_BANK_0		
	return
;**************************************************************************
ODESLI_BUFFER2
	; v TEMP1 ocakava hodnotu kolik bytu ma odeslat
	INDF_BANK_2	; BUFFER_2 je v bance 2
	movlw 0x10	; na adrese 10
	movwf FSR
ODESLI_BUFFER2_ODESILANI
	movfw INDF
	call WR_USART
	incf FSR,F	
	decfsz TEMP1,F
	goto ODESLI_BUFFER2_ODESILANI

	INDF_BANK_0		
	return
;**********************************************************
INTERRUPT					; sem se skace po zavolani preruseni (uz jsou vyreseny ulohy dulezitych registru)
	btfsc PIR1,RCIF			; testujeme o jake preruseni jde
	goto INTERRUPT_USART	; Pokud jde o preruseni od USARTU, skocime...
	btfsc PIR1,TMR1IF		; testujeme o jake preruseni jde
	goto INTERRUPT_TIMER1	; Pokud jde o preruseni od TIMER1, skocime...
	goto END_OF_INTERRUPT	; Pokud jde o jine preruseni, koncime

INTERRUPT_TIMER1
	bcf PIR1,TMR1IF
	movlw h'df'
	movwf TMR1L
	movlw h'0b'
	movwf TMR1H

;	movfw CITAC_NECINNOSTI1
;	iorwf CITAC_NECINNOSTI2,w
;	btfsc STATUS,Z
;	call WR_USART

	movfw CITAC_NECINNOSTI1
	iorwf CITAC_NECINNOSTI2,w
	btfsc STATUS,Z
	goto END_OF_INTERRUPT	; pokud je CITAC_NECINNOSTI = 0, nic se nedekrementuje
	
	movlw .1
	subwf CITAC_NECINNOSTI1,f
	btfss STATUS,C
	subwf CITAC_NECINNOSTI2,f

	goto END_OF_INTERRUPT

INTERRUPT_USART
	movfw RCREG				; !!! vynulovat pøíznak !!!	
	movwf PRIJATE_DATO

;	movlw '['
;	call WR_USART
;	movfw PRIJATE_DATO
;	call WR_USART
;	movlw ']'
;	call WR_USART

	movfw PRIJATYCH_DAT
	sublw .7				; pokud je v zasobniku uz plno (PRIJATYCH_DAT=8), tak koncime
	btfss STATUS,C
	goto END_OF_INTERRUPT	; Zasobnik je plny, nic prijimat nebudeme

	movfw PRIJATYCH_DAT
	addlw 0x78				; zacatek zasobniku prikazu
	movwf FSR
	movfw PRIJATE_DATO		; prijmuta data -> do W
	movwf INDF				; prijate dato na prvni volne misto v zasobniku
	
	incf  PRIJATYCH_DAT,F	; pricteme k indikaci zasobniku

END_OF_INTERRUPT			; sem skocime kdyz mame vsechny veci kolem preruseni vyrizeny
	movfw TEMP_PCLATH
	movwf PCLATH
	movfw TEMP_FSR
	movwf FSR
	movfw TEMP_STATUS
	movwf STATUS
	movfw TEMP_WORKING
	retfie
;**********************************************************
DELAY_2ms
; (Fosc = 20 MHz , instr. cyklus= 200 ns) 2 000us / 0.2  us = 10 000 instrukcnich cyklu
;Variables: TMP1, TMP0
;Delay 10001 cycles
        MOVLW 0x10  ;16 DEC
        MOVWF TMP1
        MOVLW 0x0CF  ;207 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
        DECFSZ TMP1,F
        GOTO $-5
;End of Delay
	return
;**********************************************************
DELAY_200ms
; (Fosc = 20 MHz , instr. cyklus= 200 ns) 200 000us / 0.2  us = 1 000 000 instrukcnich cyklu
;Variables: TMP2, TMP1, TMP0
;Delay 1000000 cycles
        MOVLW 0x15  ;21 DEC
        MOVWF TMP2
        MOVLW 0x59  ;89 DEC
        MOVWF TMP1
        MOVLW 0x0B1  ;177 DEC
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
