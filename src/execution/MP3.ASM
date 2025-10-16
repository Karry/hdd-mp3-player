;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;  MP3 PREPRCAVAC
; ================
; 
; Program mp3 prehravace pouzivajici jako zdroj dat ATA disk.
; 
; Umi identifikovat disk, precist libovolny sektor, v MBR  najit oddily se systemem souboru FAT32, 
; nacist spousteci zaznam FAT32, praci s FAT32, prehravani mp3 pres vs1001 a komunikaci s vs1001.
;
;
; dodelat:
;	- po skonceni mp3 nacist dalsi mp3
;	- Nejak udelat aby soubory byly prehravany podle abecedy
;	- pak uz jen vychytavky...	(napr. do vs1001 naprogramovat ekvalizer a nejak ho ovladat...)
;
; srpen 2005 - rijen 2005 Karry - lukas.karas@centrum.cz
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


;**********************************************************
;   HLAVNI SOUBOR 
;**********************************************************
; !!!!!!!! VSECHNY CASOVE SMYCKY JSOU POCITANY NA Fosc=16MHz !!!!!
; !!!!!!!! NASTAVENI USARTu TAKY !!!!!!!
	LIST    	p=PIC16f877,C=132,n=60
	__CONFIG	_WDT_OFF & _HS_OSC & _PWRTE_OFF & _BODEN_OFF & _LVP_OFF 
			; LVP_OFF = RB3 jako digitalni I/O
	errorlevel -302		; vypnuti Message [302]: Register in operand not in bank 0.
						; ! zjednoduseni vypisu, ale riziko prehlednuti chyby
	#DEFINE VS1001 1	; 1 = vs1001 pripojen, casti kodu pro vs1001 se prekladaji, ...
						; ...pokud 0 je pripojen pouze disk, na port se nic neposila
;**********************************************************

	include "P16F877.inc" 	; definice blbosti kolem procesoru
	include "mp3.inc" 		; definice promennych, konstant a portu

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

;**********************************************************
START
	call INIT_CONFIG	; nakonfiguruje preruseni, WDT, USART, pull ups...
	call INIT_PORT		; nastavy trisy, a porty do vychozi polohy

	call DELAY_25us 	; chvili pockame, protoze napjeti zdroje co mam doma (stary PC-AT zdroj)
	call DELAY_25us 	; zezacatku dost kolisa...
	call DELAY_25us

	call POZDRAV				; abych se u kompu nenudil

#IF VS1001==1
	call VS_INIT
#ENDIF

	call ATA_RESET				; resetujeme disk, koukneme zda tu nejakej mame
	btfss ATA_ATTRIBUTES,ATA_OK
	goto $-2					; pokud neni pripojen disk, tak se jej pokousime neustale najit...
	nop							; ...pokud tam zadny disk neni, tak bychom se stejne ani sem nemeli dostat, protoze budem porad cekat na WAIT_FOR_READY

	call IDENTIFY_DEVICE		; koukneme co disk umi
CEK_PRIKAZ_01h
	call CEKEJ_PRIKAZ
	movfw 0x078					; prvni byte prikazoveho zasobniku
	clrf PRIJATYCH_DAT			; prikaz byl vybran -> prazdny zasobnik
	sublw h'01'					; ...pokud to byl prikaz 01h...
	btfss STATUS,Z
	goto CEK_PRIKAZ_01h
	movfw ATA_ATTRIBUTES		; ...vodesleme zpet vlastnosti disku a jeho jmenovku (vis. popis protokolu)
	call WR_USART
	call ODESLI_MODEL_NUMBER	; odesleme jmeno disku 

	call SCAN_MBR				; najdeme oddily s FAT32 a jejich seznam dame do bufferu 2
CEK_PRIKAZ_02h_03h
	call CEKEJ_PRIKAZ			; pockame si na prikaz
	clrf STAV_PRIKAZU			; smazeme registr signalizujici platnost prikazu
	call PRIKAZ_02h				; testujeme zda prisel prikaz 02h, pokud ano tak jej provedeme a nastavime platnost prikazu
	call PRIKAZ_03h				; ---//---
	btfss STAV_PRIKAZU,0		; Pokud si zadna z procedur prikaz neprevzala, ...
	clrf PRIJATYCH_DAT			; ...vymazeme zasobnik prikazu. (prikaz neni pro tuto chvili platny)
	btfss ATA_ATTRIBUTES,FAT32_LOAD	; cekame dokud nedojde k nasteni nejakeho oddilu
	goto CEK_PRIKAZ_02h_03h		; pokud byl oddil vporadku nacten, pokracujeme...

	clrf PREH_STAV
;********************************************************************************************************************
;********************************************************************************************************************
;********************************************************************************************************************
;********************************************************************************************************************
BIG_LOOP
	; Tady ta smycka beha po nacteni disku a nejake FATky porad dokola.
	; Pri kazdem prubehu smyckou vyresime prikazy, ktere prisly, a pokud prehravame 
	; nejakou mp3 a dekoder chce po nas data, tak ho nakrmime alespon jednim sektorem...
	; Mimo to musime v teto smycce osefovat, ze kdyz skonci mp3, nacteme dalsi...
	movfw PRIJATYCH_DAT
	andlw h'FF'
	btfsc STATUS,Z
	goto BIG_LOOP__NENI_PRIKAZ
	
	clrf STAV_PRIKAZU			; smazeme registr signalizujici platnost prikazu
	; Pokud jsme tady, tak prisel nejaky prikaz, jdem predat prikaz jednotlivym proceduram
	call PRIKAZ_04h				; testujeme zda prisel prikaz 04h, pokud ano tak jej provedeme a nastavime platnost prikazu
	call PRIKAZ_05h				; --- // ---
	call PRIKAZ_06h				; --- // ---
	call PRIKAZ_07h				; --- // ---
	call PRIKAZ_08h				; --- // ---

	call PRIKAZ_80h				; --- // ---
	call PRIKAZ_81h				; --- // ---
	call PRIKAZ_82h				; --- // ---
	
	btfss STAV_PRIKAZU,0		; Pokud si zadna z procedur prikaz neprevzala, ...
	clrf PRIJATYCH_DAT			; ...vymazeme zasobnik prikazu. (prikaz neni pro tuto chvili platny)

BIG_LOOP__NENI_PRIKAZ

#IF VS1001==1					; pokud mame pripojen dekoder...
	btfss PREH_STAV,0			; ...a pokud se prehrava mp3...
	goto MP3_NOT_PLAY
	
	movfw PREH_DATA_POZICE
	subwf CLUSTER_SIZE,W
	btfss STATUS,Z				; ...podivame se zda jiz nejsme na konci clusteru...
	goto SEND_MP3_DATA

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
	movfw CLUSTER1
	movwf PREH_DATA_CL1
	movfw CLUSTER2
	movwf PREH_DATA_CL2
	movfw CLUSTER3
	movwf PREH_DATA_CL3
	movfw CLUSTER4
	movwf PREH_DATA_CL4
	
	btfss POZICE,0				; Pokud byl cluster posledni v retezci, skoncime s prehravanim...
	goto SEND_MP3_DATA
	
	bcf PREH_STAV,0
	bcf PREH_STAV,1
	bcf PREH_STAV,2
	goto MP3_NOT_PLAY

SEND_MP3_DATA
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
	call WAIT_FOR_VSDREQ
	call READ_DATA
	movfw DATA_L
	call VS_WR_BYTE
	movfw DATA_H
	call VS_WR_BYTE
	decfsz TEMP1,f	
	goto SEND_MP3_WORD

	incf PREH_DATA_POZICE,f
MP3_NOT_PLAY
#ENDIF

	goto BIG_LOOP
;********************************************************************************************************************
;********************************************************************************************************************
;********************************************************************************************************************
;********************************************************************************************************************
INIT_PORT
	BANK_1

#IF VS1001==1
	movlw b'00010001' 			; bity SO a DREQ jako vstupy (signaly z dekoderu)
#ELSE
	movlw 0xff
#ENDIF

	movwf MP3_PORT_TRIS
	movlw b'10000000'			; adresovani disku jako vystupy
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
	movlw .103 			; Fosc = 16 MHz, BRGH=1 => rychlost = 9615 bps
	movwf SPBRG	

	movlw b'00000111'
	movwf ADCON1		; vsechny vstupy (RA,RE) jako digitalni
	BANK_0	
	clrf ADCON0			; pro jistotu (vypneme A/D prevodniky)

	clrf PRIJATYCH_DAT	; zasobnik prikazu prazdny...
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
INTERRUPT					; sem se skace po zavolani preruseni...
	movwf TEMP_WORKING
	movfw STATUS
	movwf TEMP_STATUS
	movfw FSR
	movwf TEMP_FSR
	BANK_0
	INDF_BANK_0

	btfss PIR1,RCIF			; Meli bychom mit povoleno sice jen jedno preruseni (od USARTU), jeden ale nikdy nevi, proto ten test
	goto END_OF_INTERRUPT	; Pokud nejde o preruseni od USARTU, tak koncime...
	movfw RCREG				; !!! vynulovat pøíznak !!!	
	movwf PRIJATE_DATO

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
;	movlw '['
;	call WR_USART
;	movfw PRIJATYCH_DAT
;	addlw .48
;	call WR_USART
;	movlw ']'
;	call WR_USART	
END_OF_INTERRUPT			; sem skocime kdyz mame vsechny veci kolem preruseni vyrizeny
	movfw TEMP_FSR
	movwf FSR
	movfw TEMP_STATUS
	movwf STATUS
	movfw TEMP_WORKING
	retfie
;**********************************************************
DELAY_2ms
;Delay 8000 cycles
        MOVLW 0x13  ;19 DEC
        MOVWF TMP1
        MOVLW 0x8B  ;139 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
        DECFSZ TMP1,F
        GOTO $-5
;End of Delay	
	return
;**********************************************************
DELAY_200ms
;Delay 197123 cycles
        MOVLW 0x00  ;0 DEC
        MOVWF TMP1
        MOVLW 0x00  ;0 DEC
        MOVWF TMP0
        DECFSZ TMP0,F
        GOTO $-1
        DECFSZ TMP1,F
        GOTO $-3
;End of Delay
	return
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
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; tady jsou procedury resici jednotlive prikazy
; Pokud je v zasobniku prikaz pro nejakou proceduru, musi tato procedura nastavit byt STAV_PRIKAZU do 1 (i kdyz treba nema vsechny parametry)
; Pokud procedura najde svuj prikaz a jsou prijate vsechny parametry, musi odeslat nejakou odpoved po USARTu a smazat reg. PRIJATYCH_DAT!!!
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
CEKEJ_PRIKAZ					; ceka dokud nedostaneme nejaky prikaz
	movfw PRIJATYCH_DAT
	andlw h'FF'
	btfsc STATUS,Z				; koukneme se zda prisel nejaky prikaz...
	goto CEKEJ_PRIKAZ
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_02h						; 02h - vrat oddily se systemem FAT32
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'02'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 02h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 02h, nastavime byt STAV_REGISTRU
	movfw PRIJATYCH_DAT
	sublw .1					; pro prikaz 02h museji prijit 2 byty (prikaz + 1 parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 02h s jednim parametrem (vrat oddily se systemem FAT32)

	movfw 0x079					; parametr prikazu 02h (cislo svazku, jehoz parametry chceme vratit)
	andlw b'00000011'			; parametr musi byt v rozsahu 0-3
	movwf TEMP1
	bcf STATUS,C
	rlf TEMP1,F
	rlf TEMP1,F
	rlf TEMP1,F
	rlf TEMP1,W					; parametr vynasobime 16
	addlw 0x10					; buffer 2 je v bance 2 na adrese 0x10
	movwf FSR
	INDF_BANK_2
	movlw .16					; budeme odesilat 16 bytu
	movwf TEMP1
PRIKAZ_02h__ODESILANI_ODDILU
	movfw INDF
	call WR_USART
	incf FSR,F
	decfsz TEMP1,F
	goto PRIKAZ_02h__ODESILANI_ODDILU
	clrf PRIJATYCH_DAT
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_03h						; 03h – nastav oddil
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'03'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 03h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 03h, nastavime byt STAV_REGISTRU
	movfw PRIJATYCH_DAT
	sublw .4					; pro prikaz 03h museji prijit 5 byty (prikaz + 4byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 03h s 4bytovym parametrem (nacti oddily se systemem FAT32)

	movfw 0x079					; parametrem prikazu 03h ma byt 4bytova adresa zacatku svazku, ktery se ma nacist
	movwf LBA1
	movfw 0x07A
	movwf LBA2
	movfw 0x07B
	movwf LBA3
	movfw 0x07C
	movwf LBA4
	call NACTI_FAT32			; nacte parametry zvoleneho oddilu

	movfw ATA_ATTRIBUTES
	call WR_USART
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_04h						; 04h – vrat velikost clusteru
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'04'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 04h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 04h, nastavime byt STAV_REGISTRU
	; pro prikaz 04h nejsou definovany zadne parametry, proto jiz nic jineho netestujeme

	movfw CLUSTER_SIZE
	call WR_USART
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_05h						; 05h – vrat jmeno a adresu souboru
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'05'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 05h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 05h, nastavime byt STAV_REGISTRU
	movfw PRIJATYCH_DAT
	sublw .6					; pro prikaz 05h museji prijit 7 bytu (prikaz + 6byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 05h s 6bytovym parametrem 

	movfw 0x07D					; 5. parametr prikazu (cast adresare) Muze byt v rozsahu 0..[CLUSTER_SIZE -1]
	movwf POZICE
	subwf CLUSTER_SIZE,W		; W := CLUSTER_SIZE - [sektor v clusteru]
								; pokud W <= 0 tak je 5. parametr mimo rozsah. Prvni byte odpovedi bude 80h
	btfsc STATUS,Z				; pokud neni vysledek nula...
	goto PRIKAZ_05h__PAR_OK		; ...je parametr OK
	btfsc STATUS,C				; Pokud neni vysledek zaporny...
	goto PRIKAZ_05h__PAR_OK		; ...je parametr OK

	;Parametr byl zadan prilis velky (v jednom clusteru je CLUSTER_SIZE * 16 zaznamu)
PRIKAZ_05h__PAR_NOT_OK
	INDF_BANK_2
	movlw 0x10					; 1. byte bufferu 2
	movwf FSR
	movlw h'80'					; jako prvni byte odpovedi dame 80h (parametr byl prilis velky)
	movwf INDF
	goto PRIKAZ_05h__KONEC
PRIKAZ_05h__PAR_OK	
	; Parametr "castClusteru" byl zadan spravne, jdem se podivat zda parametr "CisloZaznamu" je v rozsahu 0..15
	movfw 0x07E					; kolikaty zaznam v casti adersare (sektoru) mame precist
	andlw b'11110000'
	btfss STATUS,Z				; pokud je parametr vetsi jak 15...
	goto PRIKAZ_05h__PAR_NOT_OK	; ...tak odesleme jako prvni byte odpovedi 80h

	; Jdem precist sektor clusteru, v kterem se nachazi pozadovany zaznam. Cislo tohoto sektoru (offset v clusteru) mame v POZICE.
	movfw 0x079					; nejnizsi cast clusteru adresare
	movwf CLUSTER1
	movfw 0x07A
	movwf CLUSTER2
	movfw 0x07B
	movwf CLUSTER3
	movfw 0x07C
	movwf CLUSTER4
	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu zaznamu na disku
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR			; dame prikaz jej precist

	movfw 0x07E					; kolikaty zaznam v casti adersare (sektoru) mame precist
	andlw b'00001111'
	movwf TEMP1					; rozsah by mel byt spravne, pro jistotu jej ale orizneme [0..15]
	andlw h'FF'
	btfsc STATUS,Z				; pokud chceme prvni soubor ze sektoru...
	goto PRIKAZ_05h__MAME_SOUBOR	; ...skocime rovnou na jeho cteni.

	swapf TEMP1,F				; protoze kazdy zaznam o souboru ma 32B=16slov, tak musime TEMP1 vynasobit 16...
	call PRESKOC				; a tolik slov preskocit (tolik slov je pro nas nepotrebnych)
PRIKAZ_05h__MAME_SOUBOR
	call FILE_INFO
PRIKAZ_05h__KONEC
	; At uz bylo v zaznamu cokoli, odesleme 16 bytu z BUFFERU 2
	movlw .16
	movwf TEMP1
	call ODESLI_BUFFER2			; odesleme si zaznam o souboru	

	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik prikazu
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_06h						; 06h – vrat cislo dalsiho clusteru v alokacnim retezu
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'06'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 06h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 06h, nastavime byt STAV_REGISTRU
	movfw PRIJATYCH_DAT
	sublw .4					; pro prikaz 06h museji prijit 5 bytu (prikaz + 4byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 06h s 4bytovym parametrem 

	movfw 0x079					; nejnizsi cast clusteru
	movwf CLUSTER1
	movfw 0x07A
	movwf CLUSTER2
	movfw 0x07B
	movwf CLUSTER3
	movfw 0x07C
	movwf CLUSTER4
	call NEXT_CLUSTER
	movfw POZICE				; pokud POZICE = 00h, je vse v poradku (vratime c. dalsiho clusteru v retezci). 
								; Pokud POZICE = FFh byl predany cluster posledni v retezu, nebo byl prazdny...
	call WR_USART
	movfw CLUSTER1
	call WR_USART
	movfw CLUSTER2
	call WR_USART
	movfw CLUSTER3
	call WR_USART
	movfw CLUSTER4
	call WR_USART
	
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik prikazu
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_07h						; 07h – cti cluster
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'07'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 07h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 07h, nastavime byt STAV_REGISTRU
	movfw PRIJATYCH_DAT
	sublw .4					; pro prikaz 07h museji prijit 5 bytu (prikaz + 4byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 06h s 4bytovym parametrem 

	movfw 0x079					; nejnizsi cast clusteru
	movwf CLUSTER1
	movfw 0x07A
	movwf CLUSTER2
	movfw 0x07B
	movwf CLUSTER3
	movfw 0x07C
	movwf CLUSTER4
	clrf POZICE
	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu pozadovaneho clusteru na disku...
	movfw CLUSTER_SIZE
	movwf SECTOR_C				; tentokrat cteme cely cluster a ne sector
	call READ_SECTOR;S

	movfw CLUSTER_SIZE
	movwf TEMP2					; kolik sektoru budeme odesilat

PRIKAZ_07h__ODESLI_SECTOR
	movlw .0					; budeme odesilat cely sector (256slov = 512bytu)
	movwf TEMP1
	call ODESLI_DATA
	decfsz TEMP2,F 				; a to tolikrat, kolik ma cluster sektroru
	goto PRIKAZ_07h__ODESLI_SECTOR
	
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik prikazu
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_08h						; 08h – vrat velikost souboru
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'08'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 08h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 08h, nastavime byt STAV_REGISTRU
	movfw PRIJATYCH_DAT
	sublw .6					; pro prikaz 08h museji prijit 7 bytu (prikaz + 6byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 08h s 6bytovym parametrem 

	movfw 0x07D					; 5. parametr prikazu (cast adresare) Muze byt v rozsahu 0..[CLUSTER_SIZE -1]
	movwf POZICE
	subwf CLUSTER_SIZE,W		; W := CLUSTER_SIZE - [sektor v clusteru]
								; pokud W <= 0 tak je 5. parametr mimo rozsah. Prvni byte odpovedi bude 80h
	btfsc STATUS,Z				; pokud neni vysledek nula...
	goto PRIKAZ_08h__PAR_OK		; ...je parametr OK
	btfsc STATUS,C				; Pokud neni vysledek zaporny...
	goto PRIKAZ_08h__PAR_OK		; ...je parametr OK

	;Parametr byl zadan prilis velky (v jednom clusteru je CLUSTER_SIZE * 16 zaznamu)
PRIKAZ_08h__PAR_NOT_OK
	movlw h'80'					; jako prvni byte odpovedi dame 80h (parametr byl prilis velky)
	movwf TEMP2
	goto PRIKAZ_08h__KONEC
PRIKAZ_08h__PAR_OK	
	; Parametr "castClusteru" byl zadan spravne, jdem se podivat zda parametr "CisloZaznamu" je v rozsahu 0..15
	movfw 0x07E					; kolikaty zaznam v casti adersare (sektoru) mame precist
	andlw b'11110000'
	btfss STATUS,Z				; pokud je parametr vetsi jak 15...
	goto PRIKAZ_08h__PAR_NOT_OK	; ...tak odesleme jako prvni byte odpovedi 80h

	; Jdem precist sektor clusteru, v kterem se nachazi pozadovany zaznam. Cislo tohoto sektoru (offset v clusteru) mame v POZICE.
	movfw 0x079					; nejnizsi cast clusteru adresare
	movwf CLUSTER1
	movfw 0x07A
	movwf CLUSTER2
	movfw 0x07B
	movwf CLUSTER3
	movfw 0x07C
	movwf CLUSTER4
	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu zaznamu na disku
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR			; dame prikaz jej precist

	movfw 0x07E					; kolikaty zaznam v casti adersare (sektoru) mame precist
	andlw b'00001111'
	movwf TEMP1					; rozsah by mel byt spravne, pro jistotu jej ale orizneme [0..15]
	andlw h'FF'
	btfsc STATUS,Z				; pokud chceme prvni soubor ze sektoru...
	goto PRIKAZ_08h__MAME_SOUBOR	; ...skocime rovnou na jeho cteni.

	swapf TEMP1,F				; protoze kazdy zaznam o souboru ma 32B=16slov, tak musime TEMP1 vynasobit 16...
	call PRESKOC				; a tolik slov preskocit (tolik slov je pro nas nepotrebnych)
PRIKAZ_08h__MAME_SOUBOR
	movlw h'00'					; jako prvni byte odpovedi dame 00h -> spravne parametry
	movwf TEMP2
	call FILE_SIZE
PRIKAZ_08h__KONEC
	movfw TEMP2
	call WR_USART				; signalizace stavu odpovedi

	movlw .4
	movwf TEMP1
	call ODESLI_BUFFER2			; odesleme si velikost souboru

	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik prikazu
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_80h						; 80h – hraj mp3 soubor
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'80'
	btfss STATUS,Z
	return						; nebyl prijat prikaz 80h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 80h, nastavime byt STAV_REGISTRU
	movfw PRIJATYCH_DAT
	sublw .6					; pro prikaz 80h museji prijit 7 bytu (prikaz + 6byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 08h s 6bytovym parametrem 

	movfw 0x07D					; 5. parametr prikazu (cast adresare) Muze byt v rozsahu 0..[CLUSTER_SIZE -1]
	movwf POZICE
	subwf CLUSTER_SIZE,W		; W := CLUSTER_SIZE - [sektor v clusteru]
								; pokud W <= 0 tak je 5. parametr mimo rozsah. Prvni byte odpovedi bude 80h
	btfsc STATUS,Z				; pokud neni vysledek nula...
	goto PRIKAZ_80h__PAR_OK		; ...je parametr OK
	btfsc STATUS,C				; Pokud neni vysledek zaporny...
	goto PRIKAZ_80h__PAR_OK		; ...je parametr OK

	;Parametr byl zadan prilis velky (v jednom clusteru je CLUSTER_SIZE * 16 zaznamu)
PRIKAZ_80h__PAR_NOT_OK
	INDF_BANK_2
	movlw 0x10					; 1. byte bufferu 2
	movwf FSR
	movlw h'80'					; jako prvni byte odpovedi dame 80h (parametr byl prilis velky)
	movwf INDF
	goto PRIKAZ_80h__KONEC
PRIKAZ_80h__PAR_OK	
	; Parametr "castClusteru" byl zadan spravne, jdem se podivat zda parametr "CisloZaznamu" je v rozsahu 0..15
	movfw 0x07E					; kolikaty zaznam v casti adersare (sektoru) mame precist
	andlw b'11110000'
	btfss STATUS,Z				; pokud je parametr vetsi jak 15...
	goto PRIKAZ_80h__PAR_NOT_OK	; ...tak odesleme jako prvni byte odpovedi 80h

	; Jdem precist sektor clusteru, v kterem se nachazi pozadovany zaznam. Cislo tohoto sektoru (offset v clusteru) mame v POZICE.
	movfw 0x079					; nejnizsi cast clusteru adresare
	movwf CLUSTER1
	movfw 0x07A
	movwf CLUSTER2
	movfw 0x07B
	movwf CLUSTER3
	movfw 0x07C
	movwf CLUSTER4
	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu zaznamu na disku
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR			; dame prikaz jej precist

	movfw 0x07E					; kolikaty zaznam v casti adersare (sektoru) mame precist
	andlw b'00001111'
	movwf TEMP1					; rozsah by mel byt spravne, pro jistotu jej ale orizneme [0..15]
	andlw h'FF'
	btfsc STATUS,Z				; pokud chceme prvni soubor ze sektoru...
	goto PRIKAZ_80h__MAME_SOUBOR	; ...skocime rovnou na jeho cteni.

	swapf TEMP1,F				; protoze kazdy zaznam o souboru ma 32B=16slov, tak musime TEMP1 vynasobit 16...
	call PRESKOC				; a tolik slov preskocit (tolik slov je pro nas nepotrebnych)
PRIKAZ_80h__MAME_SOUBOR
	call FILE_INFO

	INDF_BANK_2
	movlw 0x10					; 1. byte bufferu 2
	movwf FSR
	movfw INDF
	sublw h'06'					; pokud na zadanem miste se nachazi soubor s priponou mp3...
	btfss STATUS,Z
	goto PRIKAZ_80h__KONEC
			
	; ...nastavime jej jako prehravany soubor.
	movlw 0x1C					; 13. byte bufferu 2
	movwf FSR
	movfw INDF
	movwf PREH_DATA_CL1
	incf FSR,f
	movfw INDF
	movwf PREH_DATA_CL2
	incf FSR,f
	movfw INDF
	movwf PREH_DATA_CL3
	incf FSR,f
	movfw INDF
	movwf PREH_DATA_CL4
	
	clrf PREH_DATA_POZICE
	movlw b'00000011'
	movwf PREH_STAV

PRIKAZ_80h__KONEC
	INDF_BANK_2
	movlw 0x10					; 1. byte bufferu 2
	movwf FSR
	movfw INDF
	call WR_USART	
	
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik prikazu
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_81h						; 81h – vrat stav prehravaneho souboru
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'81'
	btfss STATUS,Z
	return						; nebyl prijat prikaz 04h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 04h, nastavime byt STAV_REGISTRU
	; pro prikaz 04h nejsou definovany zadne parametry, proto jiz nic jineho netestujeme

	movfw PREH_STAV
	call WR_USART
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_82h						; 82h – nastav hlasitost
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'82'
	btfss STATUS,Z
	return						; nebyl prijat prikaz 82h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 82h, nastavime byt STAV_REGISTRU
	movfw PRIJATYCH_DAT
	sublw .2					; pro prikaz 82h museji prijit 3 byty (prikaz + 2byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 82h s 2bytovym parametrem 

	movfw 0x079					; hlasitost pro levy kanal
	movwf VSREG_VOL_L	
	movfw 0x07A					; hlasitost pro pravy kanal
	movwf VSREG_VOL_H
	call VS_SET_VOLUME			; nastavime hlasitost	

	movlw h'FF'
	call WR_USART
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	END
