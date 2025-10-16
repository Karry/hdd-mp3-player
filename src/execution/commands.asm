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
	PROG_PAGE_0
	call WR_USART
	PROG_PAGE_1
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
	PROG_PAGE_0
	call NACTI_FAT32			; nacte parametry zvoleneho oddilu
	PROG_PAGE_1

	movfw ATA_ATTRIBUTES
	PROG_PAGE_0
	call WR_USART
	PROG_PAGE_1
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
	PROG_PAGE_0
	call WR_USART
	PROG_PAGE_1
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
	PROG_PAGE_0
	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu zaznamu na disku
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR			; dame prikaz jej precist
	PROG_PAGE_1

	movfw 0x07E					; kolikaty zaznam v casti adersare (sektoru) mame precist
	andlw b'00001111'
	movwf TEMP1					; rozsah by mel byt spravne, pro jistotu jej ale orizneme [0..15]
	andlw h'FF'
	btfsc STATUS,Z				; pokud chceme prvni soubor ze sektoru...
	goto PRIKAZ_05h__MAME_SOUBOR	; ...skocime rovnou na jeho cteni.

	swapf TEMP1,F				; protoze kazdy zaznam o souboru ma 32B=16slov, tak musime TEMP1 vynasobit 16...
	PROG_PAGE_0
	call PRESKOC				; a tolik slov preskocit (tolik slov je pro nas nepotrebnych)
	PROG_PAGE_1
PRIKAZ_05h__MAME_SOUBOR
	PROG_PAGE_0
	call FILE_INFO
	PROG_PAGE_1
PRIKAZ_05h__KONEC
	; At uz bylo v zaznamu cokoli, odesleme 16 bytu z BUFFERU 2

	movlw .16
	movwf TEMP1
	PROG_PAGE_0
	call ODESLI_BUFFER2			; odesleme si zaznam o souboru	
	PROG_PAGE_1

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
	PROG_PAGE_0
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
	PROG_PAGE_1
	
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
	PROG_PAGE_0
	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu pozadovaneho clusteru na disku...
	movfw CLUSTER_SIZE
	movwf SECTOR_C				; tentokrat cteme cely cluster a ne sector
	call READ_SECTOR;S
	PROG_PAGE_1

	movfw CLUSTER_SIZE
	movwf TEMP2					; kolik sektoru budeme odesilat

PRIKAZ_07h__ODESLI_SECTOR
	movlw .0					; budeme odesilat cely sector (256slov = 512bytu)
	movwf TEMP1
	PROG_PAGE_0
	call ODESLI_DATA
	PROG_PAGE_1
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
	PROG_PAGE_0
	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu zaznamu na disku
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR			; dame prikaz jej precist
	PROG_PAGE_1

	movfw 0x07E					; kolikaty zaznam v casti adersare (sektoru) mame precist
	andlw b'00001111'
	movwf TEMP1					; rozsah by mel byt spravne, pro jistotu jej ale orizneme [0..15]
	andlw h'FF'
	btfsc STATUS,Z				; pokud chceme prvni soubor ze sektoru...
	goto PRIKAZ_08h__MAME_SOUBOR	; ...skocime rovnou na jeho cteni.

	swapf TEMP1,F				; protoze kazdy zaznam o souboru ma 32B=16slov, tak musime TEMP1 vynasobit 16...
	PROG_PAGE_0
	call PRESKOC				; a tolik slov preskocit (tolik slov je pro nas nepotrebnych)
	PROG_PAGE_1
PRIKAZ_08h__MAME_SOUBOR
	movlw h'00'					; jako prvni byte odpovedi dame 00h -> spravne parametry
	movwf TEMP2
	PROG_PAGE_0
	call FILE_SIZE
	PROG_PAGE_1
PRIKAZ_08h__KONEC
	movfw TEMP2
	PROG_PAGE_0
	call WR_USART				; signalizace stavu odpovedi
	PROG_PAGE_1

	movlw .4
	movwf TEMP1
	PROG_PAGE_0
	call ODESLI_BUFFER2			; odesleme si velikost souboru
	PROG_PAGE_1

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
	PROG_PAGE_0
	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu zaznamu na disku
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR			; dame prikaz jej precist
	PROG_PAGE_1

	movfw 0x07E					; kolikaty zaznam v casti adersare (sektoru) mame precist
	andlw b'00001111'
	movwf TEMP1					; rozsah by mel byt spravne, pro jistotu jej ale orizneme [0..15]
	andlw h'FF'
	btfsc STATUS,Z				; pokud chceme prvni soubor ze sektoru...
	goto PRIKAZ_80h__MAME_SOUBOR	; ...skocime rovnou na jeho cteni.

	swapf TEMP1,F				; protoze kazdy zaznam o souboru ma 32B=16slov, tak musime TEMP1 vynasobit 16...
	PROG_PAGE_0
	call PRESKOC				; a tolik slov preskocit (tolik slov je pro nas nepotrebnych)
PRIKAZ_80h__MAME_SOUBOR
	PROG_PAGE_0
	call FILE_INFO
	PROG_PAGE_1

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
	bsf PREH_STAV0,0
	bsf PREH_STAV0,1

	bcf VSREG_MODE_L,1			; prehravame normalni rychlosti 
	bcf PREH_STAV1,0			; prehravame normalni rychlosti 
	
	call VS_SOFT_RESET

	movlw VSADDR_MODE
	movwf TEMP1
	movfw VSREG_MODE_L
	movwf TEMP2
	clrf TEMP3
	call VS_WR_REG

PRIKAZ_80h__KONEC
	INDF_BANK_2
	movlw 0x10					; 1. byte bufferu 2
	movwf FSR
	movfw INDF
	PROG_PAGE_0
	call WR_USART	
	PROG_PAGE_1
	
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik prikazu
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_81h						; 81h – vrat stav prehravaneho souboru
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'81'
	btfss STATUS,Z
	return						; nebyl prijat prikaz 81h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 81h, nastavime byt STAV_REGISTRU
	; pro prikaz 81h nejsou definovany zadne parametry, proto jiz nic jineho netestujeme

	movfw PREH_STAV0
	PROG_PAGE_0
	call WR_USART
	PROG_PAGE_1

	movfw PREH_STAV1
	PROG_PAGE_0
	call WR_USART
	PROG_PAGE_1

	bcf PREH_STAV0,2			; 2. bit je nastaven, kdyz se zmeni prehravany soubor (bez volani prikazu) do doby, nez prijde prikaz na dotaz STAVU... (81h)

	movlw VSADDR_DECODE_TIME
	movwf TEMP1
	call VS_RD_REG				; zjistime si aktualni pozici v souboru v sekundach
	movfw TEMP2
	PROG_PAGE_0
	call WR_USART
	movfw TEMP3
	call WR_USART	
	PROG_PAGE_1

;	movlw VSADDR_STATUS
;	movwf TEMP1
;	call VS_RD_REG
;	movfw TEMP2
;	PROG_PAGE_0
;	call WR_USART
;	PROG_PAGE_1

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
	movwf VSREG_VOL_H
	movfw 0x07A					; hlasitost pro pravy kanal
	movwf VSREG_VOL_L
	call VS_SET_VOLUME			; nastavime hlasitost	

	movlw h'FF'
	PROG_PAGE_0
	call WR_USART
	PROG_PAGE_1
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_83h						; 83h – vrat informace o prehravanem souboru
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'83'
	btfss STATUS,Z
	return						; nebyl prijat prikaz 83h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 83h, nastavime byt STAV_REGISTRU
	; pro prikaz 83h nejsou definovane zadne parametry, proto jiz nic jineho netestujeme

	movlw VSADDR_AUDATA
	movwf TEMP1
	call VS_RD_REG
	movfw TEMP2
	PROG_PAGE_0
	call WR_USART
	movfw TEMP3
	call WR_USART	
	PROG_PAGE_1
	; odeslali jsme AUDATA

	movlw VSADDR_HDAT0
	movwf TEMP1
	call VS_RD_REG
	movfw TEMP2
	PROG_PAGE_0
	call WR_USART
	movfw TEMP3
	call WR_USART	
	PROG_PAGE_1
	; odeslali jsme HDAT0

	movlw VSADDR_HDAT1
	movwf TEMP1
	call VS_RD_REG
	movfw TEMP2
	PROG_PAGE_0
	call WR_USART
	movfw TEMP3
	call WR_USART	
	PROG_PAGE_1
	; odeslali jsme HDAT1

	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_84h						; 84h – nastav stav prehravani
	movfw 0x078					; prvni byte zasobniku prikazu
	sublw h'84'
	btfss STATUS,Z
	return						; nebyl prijat prikaz 84h
	bsf STAV_PRIKAZU,0			; mame tu prikaz 84h, nastavime byt STAV_REGISTRU
	movfw PRIJATYCH_DAT
	sublw .2					; pro prikaz 8h museji prijit 3 byty (prikaz + 2byty parametr)
	btfsc STATUS,C
	return						; jeste nemame vsechny parametry
	; Prisel prikaz 84h s 2bytovym parametrem 

	movfw PREH_STAV0
	andlw b'00000110'
	movwf PREH_STAV0
	movfw 0x079					; parametr 1
	andlw b'11111001'			; nektere bity vymaskujeme (vsechny nelze ovladat prikazem)
	iorwf PREH_STAV0,w	
	movwf PREH_STAV0

	movfw 0x07A					; parametr 2
	movwf PREH_STAV1

	bcf VSREG_MODE_L,1			; prehravame normalni rychlosti (zda se mp3 prevyji je reseno v hlavni smycce podle stavu registru PREH_STAV1)
	bcf VSREG_MODE_L,7			;bass/treble enhancer
	btfsc PREH_STAV1,3			; 3. bit =	1 => zvyrazneni basu a vysek (moznost dekoderu vs1001 "bass/treble enhancer")
	bsf VSREG_MODE_L,7			;bass/treble enhancer
	
	movlw VSADDR_MODE
	movwf TEMP1
	movfw VSREG_MODE_L
	movwf TEMP2
	clrf TEMP3
	call VS_WR_REG
	
	movlw VSADDR_STATUS
	call VS_RD_REG
	movfw TEMP2
	movwf VSREG_STATUS_L

	bcf VSREG_STATUS_L,2		; Bit 2 is analog powerdown bit.
	btfsc PREH_STAV1,4			; 4. bit = 1 => MUTE
	bsf VSREG_STATUS_L,2		; Bit 2 is analog powerdown bit.
	
	movlw VSADDR_STATUS
	movwf TEMP1
	movfw VSREG_STATUS_L
	movwf TEMP2
	clrf TEMP3
	call VS_WR_REG

	PROG_PAGE_0
	movlw h'FF'
	call WR_USART
	PROG_PAGE_1
	clrf PREH_CITAC_PREV
	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
