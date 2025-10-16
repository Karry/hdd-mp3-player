; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; tady jsou procedury resici jednotlive prikazy
; Pokud je v zasobniku prikaz pro nejakou proceduru, musi tato procedura nastavit byt STAV_PRIKAZU do 1 (i kdyz treba nema vsechny parametry)
; Pokud procedura najde svuj prikaz a jsou prijate vsechny parametry, musi odeslat nejakou odpoved po USARTu a smazat reg. PRIJATYCH_DAT!!!
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; CAST 2 
PRIKAZ_03h						; 03h ñ nastav oddil
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'03'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 03h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 03h, nastavime byt STAV_PRIKAZU
	movfw PRIJATYCH_DAT
	sublw .4					; pro prikaz 03h museji prijit 5 byty (prikaz + 4byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 03h s 4bytovym parametrem (nacti oddily se systemem FAT32)

	; z·lohujeme si d˘leûitÈ hodnoty do bufferu 1
	INDF_BANK_3
	movlw 0x90
	movwf FSR
	movfw POCATEK_DAT1
	movwf INDF
	incf FSR,f
	movfw POCATEK_DAT2
	movwf INDF
	incf FSR,f
	movfw POCATEK_DAT3
	movwf INDF
	incf FSR,f
	movfw POCATEK_DAT4
	movwf INDF
	incf FSR,f

	movfw POCATEK_FAT1
	movwf INDF
	incf FSR,f
	movfw POCATEK_FAT2
	movwf INDF
	incf FSR,f
	movfw POCATEK_FAT3
	movwf INDF
	incf FSR,f
	movfw POCATEK_FAT4
	movwf INDF
	incf FSR,f

	movfw ROOT_DIR_CL1
	movwf INDF
	incf FSR,f
	movfw ROOT_DIR_CL2
	movwf INDF
	incf FSR,f
	movfw ROOT_DIR_CL3
	movwf INDF
	incf FSR,f
	movfw ROOT_DIR_CL4
	movwf INDF
	incf FSR,f
	movfw ATA_ATTRIBUTES
	movwf INDF

	movfw 0x079					; parametrem prikazu 03h ma byt 4bytova adresa zacatku svazku, ktery se ma nacist
	movwf LBA1
	movfw 0x07A
	movwf LBA2
	movfw 0x07B
	movwf LBA3
	movfw 0x07C
	movwf LBA4

;	PROG_PAGE_2
	call NACTI_FAT32			; nacte parametry zvoleneho oddilu
;	PROG_PAGE_2

	movfw ATA_ATTRIBUTES
	PROG_PAGE_0
	call WR_USART
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik prikazu
	PROG_PAGE_2
	btfss ATA_ATTRIBUTES,FAT32_LOAD
	goto PRIKAZ_03h_NENACTENO
PRIKAZ_03h_NACTENO
	; ted se podivame, zda pri predchozim spusteni byl take nacten tento oddil, a zda mame po nacteni zacit prehravat
	btfss PREH_STAV0,7				; 7. bit = 1 => po naËtenÌ oddÌlu se zaËne p¯ehr·vat mp3, kterou se p¯i poslednÌm p¯ehr·v·ni skonËilo 
	goto PRIKAZ_03h_KONEC_NEHRAJ
	
	; precteme informace o posledni prehrane skladbe a umistime je do buferru 1
	INDF_BANK_3
	movlw 0x90
	movwf FSR
	movlw .4
	movwf TEMP1
PRIKAZ_03h_LOOP1
	movfw TEMP1
	BANK_2
	movwf EEADR
	BANK_3
	bsf EECON1,RD
	BANK_2
	movfw EEDATA
	movwf INDF
	incf FSR,f
	BANK_0
	incf TEMP1,f
	movfw TEMP1
	sublw .19
	btfss STATUS,Z
	goto PRIKAZ_03h_LOOP1
	
	; podivame se zda posledne nahrany svazek byl shodny s aktualnim
	movlw 0x90
	movwf FSR
	movfw POCATEK_DAT1
	subwf INDF,w
	btfss STATUS,Z
	goto PRIKAZ_03h_PROHLEDEJ_ROOT
	incf FSR,f
	movfw POCATEK_DAT2
	subwf INDF,w
	btfss STATUS,Z
	goto PRIKAZ_03h_PROHLEDEJ_ROOT
	incf FSR,f
	movfw POCATEK_DAT3
	subwf INDF,w
	btfss STATUS,Z
	goto PRIKAZ_03h_PROHLEDEJ_ROOT
	incf FSR,f
	movfw POCATEK_DAT4
	subwf INDF,w
	btfss STATUS,Z
	goto PRIKAZ_03h_PROHLEDEJ_ROOT
	incf FSR,f
	; mame ten samy oddil, jako pri poslednim prehravani, 
	; proto se podivame, zda tu je ten soubor, ktery hral minule naposled.
	; A pokud ano, nastavime se na jeho konec. Beh programu jiz zaridi, ze bude
	; nalezena dalsi mp3 a nastavena k prehravani.

	movfw INDF
	movwf PREH_ADR_CL1
	movwf CLUSTER1
	incf FSR,f
	movfw INDF
	movwf PREH_ADR_CL2
	movwf CLUSTER2
	incf FSR,f
	movfw INDF
	movwf PREH_ADR_CL3
	movwf CLUSTER3
	incf FSR,f
	movfw INDF
	movwf PREH_ADR_CL4
	movwf CLUSTER4
	incf FSR,f
	PROG_PAGE_1
	call PRVNI_CL_ADRESARE
	; V POZICE vrati 00h, pokud cluster je prvni cluster nejakeho adresare, FFh, pokud neobsahuje adresar
	PROG_PAGE_2
	btfsc POZICE,0
	goto PRIKAZ_03h_PROHLEDEJ_ROOT


	; adresar se na dotazovanem miste nachazi...
	INDF_BANK_3
	movlw 0x98
	movwf FSR
	movfw INDF
	movwf ZAZNAM1
	movwf PREH_ZAZNAM1
	incf FSR,f
	movfw INDF
	movwf ZAZNAM2
	movwf PREH_ZAZNAM2
	PROG_PAGE_1
	call SKOC_NA_ZAZNAM
	; - pokud ZAZNAM[1-2] ukazuji mimo adresar, vrati v POZICE FFh (jinak 00h)
	PROG_PAGE_2
	btfsc POZICE,0
	goto PRIKAZ_03h_PROHLEDEJ_ROOT
	; zaznam se v adresari take nachazi....

	PROG_PAGE_1
	call FILE_INFO	
	PROG_PAGE_2
	INDF_BANK_2
	movlw 0x10
	movwf FSR
	movfw INDF
	sublw h'06' 	; = 06h -> zaznam je soubor s priponou MP3
	btfss STATUS,Z
	goto PRIKAZ_03h_PROHLEDEJ_ROOT
	; ...dokonce se jedna o soubor mp3, tak se nastavime na jeho konec a hotovo...

	clrf PREH_D_FRAGMENT1
	clrf PREH_D_FRAGMENT2

	INDF_BANK_3
	movlw 0x9B
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
	incf FSR,f

	movfw CLUSTER_SIZE
	movwf PREH_DATA_POZICE
	; ted bychom meli byt nastaveni na konec MP3, ktera se prehravala naposled 
	; a automaticky bychom se meli dostat na nasledujici...

	goto PRIKAZ_03h_KONEC

PRIKAZ_03h_NENACTENO
	; pokud nebyla FATka ˙spÏönÏ naËtena, vr·tÌme zpÏt z·lohovanÈ hodnoty...
	INDF_BANK_3
	movlw 0x90
	movwf FSR
	movfw INDF
	movwf POCATEK_DAT1
	incf FSR,f
	movfw INDF
	movwf POCATEK_DAT2
	incf FSR,f
	movfw INDF
	movwf POCATEK_DAT3
	incf FSR,f
	movfw INDF
	movwf POCATEK_DAT4
	incf FSR,f

	movfw INDF
	movwf POCATEK_FAT1
	incf FSR,f
	movfw INDF
	movwf POCATEK_FAT2
	incf FSR,f
	movfw INDF
	movwf POCATEK_FAT3
	incf FSR,f
	movfw INDF
	movwf POCATEK_FAT4
	incf FSR,f

	movfw INDF
	movwf ROOT_DIR_CL1
	incf FSR,f
	movfw INDF
	movwf ROOT_DIR_CL2
	incf FSR,f
	movfw INDF
	movwf ROOT_DIR_CL3
	incf FSR,f
	movfw INDF
	movwf ROOT_DIR_CL4
	incf FSR,f
	movfw INDF
	movwf ATA_ATTRIBUTES

PRIKAZ_03h_KONEC
;	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return

PRIKAZ_03h_PROHLEDEJ_ROOT
	clrf PREH_D_FRAGMENT1
	clrf PREH_D_FRAGMENT2
	clrf PREH_ADR_CL1
	clrf PREH_ADR_CL2
	clrf PREH_ADR_CL3
	clrf PREH_ADR_CL4
	clrf PREH_ZAZNAM1
	clrf PREH_ZAZNAM2
	bcf PREH_STAV0,1			; neni soubor k prehravani

;	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik

	clrf HL_ADR_CL1
	clrf HL_ADR_CL2
	clrf HL_ADR_CL3
	clrf HL_ADR_CL4				; hledej v ROOT
	movlw b'00101110'			; hledej 1. mp3
	movwf HL_PARAMETRY

	PROG_PAGE_1
	call HLEDEJ
	PROG_PAGE_2

	BANK_2
	movfw 0x30
	BANK_0
	sublw h'06'					; = 06h -> zaznam je soubor s priponou MP3
	btfss STATUS,Z
	return

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; byla nalezena 1. MP3 v ROOT adresari
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

	PROG_PAGE_0
	call ZJISTI_FRAGMENT
	PROG_PAGE_2
	movfw FRAGMENT1
	movwf PREH_D_FRAGMENT1
	movfw FRAGMENT2
	movwf PREH_D_FRAGMENT2
	; aktualni prehravany soubor i prehravana slozka byly nastaveny...

	clrf PREH_DATA_POZICE
	bsf PREH_STAV0,0			; je zvoleno play
	bsf PREH_STAV0,1			; je co prehravat
	bsf PREH_STAV0,2			; byl automaticky zmenen prehravany soubor

	bcf VSREG_MODE_L,1			; prehravame normalni rychlosti 
	bcf PREH_STAV1,0			; prehravame normalni rychlosti 

	PROG_PAGE_1	
	call VS_SOFT_RESET

	movlw VSADDR_MODE
	movwf TEMP1
	movfw VSREG_MODE_L
	movwf TEMP2
	clrf TEMP3
	call VS_WR_REG
	PROG_PAGE_2

	return
PRIKAZ_03h_KONEC_NEHRAJ
	clrf PREH_D_FRAGMENT1
	clrf PREH_D_FRAGMENT2
	clrf PREH_ADR_CL1
	clrf PREH_ADR_CL2
	clrf PREH_ADR_CL3
	clrf PREH_ADR_CL4
	clrf PREH_ZAZNAM1
	clrf PREH_ZAZNAM2
	bcf PREH_STAV0,1			; neni soubor k prehravani

;	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_0Bh						; 0Bh ñ zjisti velikost fragmentu
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'0b'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 0Bh
	bsf STAV_PRIKAZU,0			; mame tu prikaz 0Bh, nastavime byt STAV_PRIKAZU
	movfw PRIJATYCH_DAT
	sublw .4					; pro prikaz 0Bh museji prijit 5 bytu (prikaz + 4byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 0Bh s 4bytovym parametrem 

	movfw 0x079					; nejnizsi cast clusteru
	movwf CLUSTER1
	movfw 0x07A
	movwf CLUSTER2
	movfw 0x07B
	movwf CLUSTER3
	movfw 0x07C
	movwf CLUSTER4

	PROG_PAGE_0
	call ZJISTI_FRAGMENT
	PROG_PAGE_2
; v CLUSTER[1-4] prijme cislo clusteru a do FRAGMENT[1-2] umisti kolik clusteru 
; po tomto clusteru nasledujich tvori jeden fragment
; (pokud je retezec tvoren pouze z tohoto clusteru, je vraceno cislo 0)

; Pokud soucasny cluster je prazdny (coz by se stat nemelo) vrati v POZICE FFh
; Jinak, pokud s vse povede, dame do POZICE 0

; ! PODPROGRAM NENI POUZITELNY PRO CLUSTER 0 (prvni cluster ROOT adresare)
; ! PODPROGRAM NETESTUJE ZDA NEBYLO ZADANO VETSI CISLO NEZ JE POCET CLUSTERU !!!
	
	PROG_PAGE_0
	movfw POZICE 
	call WR_USART
	movfw FRAGMENT1
	call WR_USART
	movfw FRAGMENT2
	call WR_USART
	PROG_PAGE_2
	
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik prikazu
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_0Ch						; 0Ch ñ najdi z·znam o tomto adres·¯i v nad¯azenÈm adres·¯i
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'0C'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 0Ch
	bsf STAV_PRIKAZU,0			; mame tu prikaz 0Ch, nastavime byt STAV_PRIKAZU
	movfw PRIJATYCH_DAT
	sublw .4					; pro prikaz 0Ch museji prijit 5 bytu (prikaz + 4byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 0Ch s 4bytovym parametrem 

	movfw 0x079					; nejnizsi cast clusteru
	movwf CLUSTER1
	movfw 0x07A
	movwf CLUSTER2
	movfw 0x07B
	movwf CLUSTER3
	movfw 0x07C
	movwf CLUSTER4

	movfw CLUSTER1
	iorwf CLUSTER2,W
	iorwf CLUSTER3,W
	iorwf CLUSTER4,W
	btfsc STATUS,Z
	goto PRIKAZ_0Ch_JEROOT		; pokud CLUSTER[1-4]=0, tak se jedna o 1. cluster ROOT adr., proto nemusime dale resit co tam je...

	PROG_PAGE_1
	call PRVNI_CL_ADRESARE		; V POZICE vrati 00h, pokud cluster je prvni cluster nejakeho adresare, FFh, pokud neobsahuje adresar
	PROG_PAGE_2
	movfw POZICE
	andlw h'FF'
	btfss STATUS,Z
	goto PRIKAZ_0Ch_NENI_ZACATEK_ADR	

	PROG_PAGE_1
	call HLEDEJ_V_NADRAZENEM
	PROG_PAGE_2

	movlw h'00'
	goto PRIKAZ_0Ch_ODESLI
PRIKAZ_0Ch_NENI_ZACATEK_ADR
	movlw h'81'
	goto PRIKAZ_0Ch_ODESLI
PRIKAZ_0Ch_JEROOT
	movlw h'01'
PRIKAZ_0Ch_ODESLI

	PROG_PAGE_0
	call WR_USART

	INDF_BANK_3
	movlw h'90'
	movwf FSR

	movfw INDF
	call WR_USART
	incf FSR,f
	movfw INDF
	call WR_USART
	incf FSR,f
	movfw INDF
	call WR_USART
	incf FSR,f
	movfw INDF
	call WR_USART
	incf FSR,f

	movfw ZAZNAM1
	call WR_USART
	movfw ZAZNAM2
	call WR_USART
	PROG_PAGE_2
	
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik prikazu
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_0Dh						; 0Dh ñ nastav dobu, po ktere se disk prepne do STANDBY
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'0D'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 0Dh
	bsf STAV_PRIKAZU,0			; mame tu prikaz 0Dh, nastavime byt STAV_PRIKAZU
	movfw PRIJATYCH_DAT
	sublw .2					; pro prikaz 0Ch museji prijit 3 bytu (prikaz + 2byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 0Dh s 2bytovym parametrem 

	movfw 0x079
	iorwf 0x07A,w
	btfsc STATUS,Z
	goto PRIKAZ_0Dh_OKAMZITE

	movfw 0x079					; 2. byte zasobniku prikazu		
	movwf KONST_NECINNOSTI1
	movwf CITAC_NECINNOSTI1
	movfw 0x07A					; 3. byte zasobniku prikazu		
	movwf KONST_NECINNOSTI2
	movwf CITAC_NECINNOSTI2		; disk je vypinan po urcite dobe necinosti

	goto PRIKAZ_0Dh_KONEC
PRIKAZ_0Dh_OKAMZITE
	clrf CITAC_NECINNOSTI1
	clrf CITAC_NECINNOSTI2

PRIKAZ_0Dh_KONEC

	PROG_PAGE_0
	movlw h'ff'
	call WR_USART
	PROG_PAGE_2

	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_85h						; 85h ñ nastav p¯edvolen˝ ÑekvalizÈrì
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'85'					
	btfss STATUS,Z
	return						; nebyl prijat prikaz 0Dh
	bsf STAV_PRIKAZU,0			; mame tu prikaz 0Dh, nastavime byt STAV_PRIKAZU
	movfw PRIJATYCH_DAT
	sublw .1					; pro prikaz 85h museji prijit 2 byty (prikaz + 1byt parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 85h s 1 bytem parametru

	movfw 0x079
	andlw h'FF'
	btfsc STATUS,Z
	goto PRIKAZ_85h_VYPNI

	movfw 0x079	
	sublw .12
	btfss STATUS,C
	goto PRIKAZ_85h_SPATNY_PARAMETR

	movfw 0x079	
	movwf VS_LOUDNESS

	movlw VSADDR_AIADDR
	movwf TEMP1
	movlw 0x00
	movwf TEMP2	
	movlw 0x42
	movwf TEMP3
	PROG_PAGE_1	
	call VS_WR_REG				; nastavime zacatek uzivatelskeho programu (0x4200)
	PROG_PAGE_2

	movlw VSADDR_AICTRL0
	movwf TEMP1
	movlw 0x00
	movwf TEMP2	
	movlw 0x00
	movwf TEMP3
	PROG_PAGE_1	
	call VS_WR_REG				; resetujeme plugin
	PROG_PAGE_2

	movlw VSADDR_AICTRL0
	movwf TEMP1
	movfw VS_LOUDNESS
	movwf TEMP2	
	movlw 0x00
	movwf TEMP3
	PROG_PAGE_1	
	call VS_WR_REG				; nastavime pozadovany filter
	PROG_PAGE_2

	PROG_PAGE_0
	movlw h'ff'
	call WR_USART
	PROG_PAGE_2
	goto PRIKAZ_85h_KONEC

PRIKAZ_85h_SPATNY_PARAMETR
	PROG_PAGE_0
	movlw h'00'
	call WR_USART
	PROG_PAGE_2
	goto PRIKAZ_85h_KONEC

PRIKAZ_85h_VYPNI
	clrf VS_LOUDNESS

	movlw VSADDR_AICTRL0
	movwf TEMP1
	movlw 0x00
	movwf TEMP2	
	movlw 0x00
	movwf TEMP3
	PROG_PAGE_1	
	call VS_WR_REG				; resetujeme plugin
	PROG_PAGE_2

	movlw VSADDR_AIADDR
	movwf TEMP1
	clrf TEMP2	
	clrf TEMP3
	PROG_PAGE_1	
	call VS_WR_REG				; vypneme plugin

	PROG_PAGE_0
	movlw h'ff'
	call WR_USART
	PROG_PAGE_2
PRIKAZ_85h_KONEC
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_86h						; 86h ñ vraù nastavenou hlasitost
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'86'
	btfss STATUS,Z
	return						; nebyl prijat prikaz 86h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 86h, nastavime byt STAV_PRIKAZU
	; pro prikaz 04h nejsou definovany zadne parametry, proto jiz nic jineho netestujeme

	PROG_PAGE_0
	movfw VSREG_VOL_H			; hlasitost pro levy kanal
	call WR_USART	
	movfw VSREG_VOL_L			; hlasitost pro pravy kanal
	call WR_USART
	PROG_PAGE_2
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_87h						; 87h ñ uloû nastavenÌ p¯ehr·v·nÌ do EEPROM
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'87'
	btfss STATUS,Z
	return						; nebyl prijat prikaz 87h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 87h, nastavime byt STAV_PRIKAZU
	; pro prikaz 87h nejsou definovany zadne parametry, proto jiz nic jineho netestujeme

	PROG_PAGE_0
	call ULOZ_KONFIGUTACI
	
	movlw h'FF'					; pro prikaz je vzdy odpoved FFh
	call WR_USART
	PROG_PAGE_2
	
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
