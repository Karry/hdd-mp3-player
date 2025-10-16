;**********************************************************
;**********************************************************
;**********************************************************
; OBSLUZNE PODPROGRAMY PRO FAT32, HLEDANI ODDILU
;**********************************************************
;**********************************************************
;**********************************************************

;**************************************************************************
SCAN_MBR
	; Tato procedura ma na prvni pohled jednoduchy ukol, podiva se do MBR a do BUFFERU 2 hodi nasledujici data:
	; 4 x 16 bytovy zaznam, kde kazdy zaznam reprezentuje jeden oddil se systemem FAT32
	; struktura zaznamu je nasledujici:		1  byt (pokud = 0 tak v zaznamu neni zaznam o oddilu, pokud = FFh , je zaznam o oddilu)
	;										4  byty = adresa kde se nachazi spousteci zaznam oddilu
	;										11 bytu = jmenovka oddilu s FAT32 (neni dulezita, jen aby bylo co vypsat na display :-)
	call CLEAR_BUFFER2

	clrf LBA1
	clrf LBA2
	clrf LBA3
	clrf LBA4				; jako prvni cteme MBR

	clrf POZICE				; kolik zaznamu o oddilech uz bylo zapsano do bufferu2
SCAN_BR						
	; tady na tom navesti mame zadanou adresu MBR nebo BR nejakeho rozsireneho oddilu
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR		; cteme MBR nebo BR rozsireneho oddilu

	movlw .223				; 223 slov = 446 bytu
	movwf TEMP1
	call PRESKOC			; na prvnich 446 bytech MBR je zavadeci program systemu (samozrejme, pokud na disku system je)
	movlw .32
	movwf TEMP1
	call ZAPIS_DO_BUFFERU_1	; do bufferu si dame vsechny zaznamy BR (16*4=64bytu / 32slov)
	movlw .1
	movwf TEMP1
	call PRESKOC
	; tak ted jsme precetli cely MBR/BR a zaznamy o jeho oddilech mame v BEFFERU 1, tak se jdem na ne podivat...
	
	; Nejdriv si ale hodime aktualni LBA adresu do operandu Y pro aritmeticke operace
	INDF_BANK_1				; neprime adresovani na banku 1 (aritmeticke operace)
	movlw 0xA4				; FSR na OPERAND_Y
	movwf FSR	
	movfw LBA1
	movwf INDF
	incf FSR,F
	movfw LBA2
	movwf INDF
	incf FSR,F
	movfw LBA3
	movwf INDF
	incf FSR,F
	movfw LBA4
	movwf INDF
	incf FSR,F

	INDF_BANK_3				; neprime adresovani na banku 3 (buffer 1)	
	movlw 0x94				; 90h (buffer1) + 4 (pozice kde je ulozen identifikator souboroveho systemu prvniho zaznamu BR)
	movwf FSR
	movfw INDF
	sublw h'0C'				; Pokud se FileSystem <> 0Ch...
	btfss STATUS,Z
	sublw .1				; ...ani 0Bh...
	btfss STATUS,Z
	goto SCAN_MBR__HLEDEJ_ROZSIRENY_ODDIL	; ...tak hledej rozsireny oddil.

	; pokud jsme v teto casti programu, tak prvni zaznam MBR/BR obsahuje oddil FAT32, s reprezentaci adres stylem LBA
	; Tady pozor, v MBR/BR neni zapsana LBA adresa oddilu, ale relativni vzdalenost (offset) od MBR/BR.
	; To znamena, ze k adrese v (M)BR musime pricist offset oddilu.
	BANK_1
	movlw 0x98				; offset prvniho zaznamu 
	movwf FSR
	movfw INDF
	movwf OPERAND_X1
	incf FSR,F
	movfw INDF
	movwf OPERAND_X2
	incf FSR,F
	movfw INDF
	movwf OPERAND_X3
	incf FSR,F
	movfw INDF
	movwf OPERAND_X4
	BANK_0

	call SOUCET

	INDF_BANK_1				; neprime adresovani na banku 1 (aritmeticke operace)
	movlw 0xA8				; FSR na VYSLEDEK
	movwf FSR	
	movfw INDF
	movwf LBA1
	incf FSR,F
	movfw INDF
	movwf LBA2
	incf FSR,F
	movfw INDF
	movwf LBA3
	incf FSR,F
	movfw INDF
	movwf LBA4
	incf FSR,F

	call ZKONTROLUJ_ODDIL_FAT32	; pokud skutecne adresa v LBA1-4 ukazuje na zacatek oddilu s FAT32, tak da do bufferu2 jmenovku a adresu oddilu
	INDF_BANK_3
	movlw 0xA4					; 90h (buffer 1) + 16 (velikost 1. zaznamu) + 4 (identifikator souboroveho systemu 2. zaznamu)
	movwf FSR
SCAN_MBR__HLEDEJ_ROZSIRENY_ODDIL		; jdem v zaznamech MBR/BR hledat rozsireny oddil
	; pokud byl v prvnim zaznamu oddil typu FAT32, tak nam  tad FSR ukazuje na FileSystem 2. zaznamu...
	; ...pokud 1. zaznam nebyl typu FAT32, tak nam FSR ukazuje na FileSystem 1. zaznamu.
	; Kazdopadne se ted podivame na dalsi zaznam a pokud obsahuje rozsireny oddil, skocime na jeho adresu a dame goto SCAN_BR ...
	movfw INDF
	sublw h'05'				; Pokud se FileSystem <> 05h (rozsireny oddil CHS)...
	btfss STATUS,Z
	sublw h'0A'				; ...ani se <> 0Fh (5+A=F) (rozsireny oddil LBA)...
	btfss STATUS,Z
	goto SCAN_MBR__KONEC	; ...tak koncime...

	movfw FSR				; ...pokud tu ale mame rozsireny oddil,...
	addlw .4				; ...tak se jdem podivat na jeho adresu.
	movwf FSR

	BANK_1
	INDF_BANK_3
	movfw INDF
	movwf OPERAND_X1
	incf FSR,F
	movfw INDF
	movwf OPERAND_X2
	incf FSR,F
	movfw INDF
	movwf OPERAND_X3
	incf FSR,F
	movfw INDF
	movwf OPERAND_X4
	BANK_0

	call SOUCET

	INDF_BANK_1				; neprime adresovani na banku 1 (aritmeticke operace)
	movlw 0xA8				; FSR na VYSLEDEK
	movwf FSR	
	movfw INDF
	movwf LBA1
	incf FSR,F
	movfw INDF
	movwf LBA2
	incf FSR,F
	movfw INDF
	movwf LBA3
	incf FSR,F
	movfw INDF
	movwf LBA4
	incf FSR,F
	
	goto SCAN_BR			; S rozirenym oddilem provedeme totez co s MBR
SCAN_MBR__KONEC
	return
;**************************************************************************
ZKONTROLUJ_ODDIL_FAT32
	; tak ted bychom mely mit v LBA 1-4 adresu spousteciho zaznamu oddilu s FAT32, tak to jdem overit...
	; ...a pokud tam doopravdy spousteci zaznam je, tak dame jmenovku a informace do bufferu 2 na pozici jaka je v rag. POZICE
	INDF_BANK_2
	movfw POZICE
	movwf TEMP1
	bcf STATUS,C
	rlf TEMP1,F
	rlf TEMP1,F
	rlf TEMP1,F
	rlf TEMP1,F				; TEMP1 := POZICE *16
	movfw TEMP1
	addlw 0x11				; TEMP1 + pozice bufferu 2 + 1 (pozice kam budeme do bufferu 2 davat adresu oddilu)
	movwf FSR

	movfw LBA1
	movwf INDF
	incf FSR,F
	movfw LBA2
	movwf INDF
	incf FSR,F
	movfw LBA3
	movwf INDF
	incf FSR,F
	movfw LBA4
	movwf INDF
	incf FSR,F				; adresa oddilu je ulozena do bufferu 2, ted tam jdem davat jmenovku oddilu

	movlw .1
	movwf SECTOR_C
	call READ_SECTOR
	movlw h'23'
	movwf TEMP1
	call PRESKOC			; informace o FATce co nas ted zrovna moc nezejimaji
	; na offsetu 47 je ulozena jmenovka oddilu (11znaku), ted jsme na offsetu 46

	call READ_DATA
	movfw DATA_H
	movwf INDF				; 1. znak ze jmenovky svazku
	incf FSR,F

	movlw .5				; dalsich 10 bytu je zbytek jmenovky
	movwf TEMP1
ZKONTROLUJ_ODDIL_FAT32__JMENOVKA
	call READ_DATA
	movfw DATA_L
	movwf INDF
	incf FSR,F
	movfw DATA_H
	movwf INDF
	incf FSR,F
	decfsz TEMP1,F
	goto ZKONTROLUJ_ODDIL_FAT32__JMENOVKA
	movlw .16
	subwf FSR,F					; aby fsr ukazoval na priznak o pravdivosti (FSR := FSR - 16)

	call READ_DATA
	movfw DATA_L
	sublw 'F'		
	btfss STATUS,Z
	goto ZKONTROLUJ_ODDIL_FAT32__KONEC
	movfw DATA_H
	sublw 'A'		
	btfss STATUS,Z
	goto ZKONTROLUJ_ODDIL_FAT32__KONEC

	call READ_DATA
	movfw DATA_L
	sublw 'T'		
	btfss STATUS,Z
	goto ZKONTROLUJ_ODDIL_FAT32__KONEC
	movfw DATA_H
	sublw '3'		
	btfss STATUS,Z
	goto ZKONTROLUJ_ODDIL_FAT32__KONEC

	call READ_DATA
	movfw DATA_L
	sublw '2'
	btfss STATUS,Z
	goto ZKONTROLUJ_ODDIL_FAT32__KONEC
	; tak, ted uz opravdu vime, ze na tomto sektoru se nachazi spousteci zaznam svazku se souborovym systemem FAT32

	movlw h'FF'
	movwf INDF
	incf POZICE,F				; sektor skutecne obsahoval spousteci zaznam svazku...
ZKONTROLUJ_ODDIL_FAT32__KONEC
	return
;**************************************************************************
NACTI_FAT32
	; V LBA1-4 bychom meli dostat adresu prvniho sektoru FAT32 oddilu, kde by se mely nalezat informace o fatce
	; pokud je FATka pro nas pouzitelna (Clustery nejsou moc velke, sektor = 512B ...) nastavime bit FAT32_LOAD v ATA_ATTRIBUTES
	bcf ATA_ATTRIBUTES,FAT32_LOAD
	clrf POCATEK_DAT1
	clrf POCATEK_DAT2
	clrf POCATEK_DAT3
	clrf POCATEK_DAT4
	clrf POCATEK_FAT1
	clrf POCATEK_FAT2
	clrf POCATEK_FAT3
	clrf POCATEK_FAT4
	clrf ROOT_DIR_CL1
	clrf ROOT_DIR_CL2
	clrf ROOT_DIR_CL3
	clrf ROOT_DIR_CL4


	clrf FEATURES
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR

	movlw .5
	movwf TEMP1
	call PRESKOC

	call READ_DATA				; 10 bytu precteno
	movfw DATA_H				; 11,12 byte - velikost sektoru (tady by melo byt 512, ale co kdyby ne...)
	andlw h'FF'
	btfss STATUS,Z
	goto NACTI_FAT32__KONEC		; pokud 11 byte neni nula, koncime (velikost sektoru se nerovna 512)

	call READ_DATA				; ctu 12. a 13. byte
	movfw DATA_L
	sublw h'02'
	btfss STATUS,Z
	goto NACTI_FAT32__KONEC		; pokud 12 byte neni 2, koncime (velikost sektoru se nerovna 512)

	movfw DATA_H				; byte 13. SectorsPerCluster
	movwf CLUSTER_SIZE
	sublw .32					; nas program neumi vic jak 32 (Velikost clusteru = 16KB)
	btfss STATUS,C
	goto NACTI_FAT32__KONEC		; pokud mame clustery vetsi jak 16KB, tak koncime

	call READ_DATA				; ctu 14. a 15. byte
	movfw DATA_L
	movwf POCATEK_FAT1			; tady se nachazi pocet rezervovanych sektoru, pak k ZACATEK_FAT pricteme adresu zacatku sektoru a mame zacatek fat...
	movfw DATA_H
	movwf POCATEK_FAT2
	
	call READ_DATA				; ctu 16. a 17. byte
	movfw DATA_L				; Pocet FAT. byva temer vzdy 2, kdyby ale ne, tak by nam to delalo docela bordel...
	sublw .2
	btfss STATUS,Z
	goto NACTI_FAT32__KONEC

	movlw .9
	movwf TEMP1
	call PRESKOC				; 18 - 35

	call READ_DATA				; 36,37 -> velikost FAT (pocet sektoru)
	movfw DATA_L
	movwf POCATEK_DAT1
	movfw DATA_H
	movwf POCATEK_DAT2	
	call READ_DATA				; 38,39 -> velikost FAT (pocet sektoru)
	movfw DATA_L
	movwf POCATEK_DAT3
	movfw DATA_H
	movwf POCATEK_DAT4

	call READ_DATA				; 40,41
	call READ_DATA				; 42,43

	call READ_DATA				; 44,45
	movfw DATA_L
	movwf ROOT_DIR_CL1
	movfw DATA_H
	movwf ROOT_DIR_CL2
	call READ_DATA				; 46,47
	movfw DATA_L
	movwf ROOT_DIR_CL3
	movfw DATA_H
	movwf ROOT_DIR_CL4

	movlw .17
	movwf TEMP1
	call PRESKOC				; 48 - 81

	; ted jeste takova mala kontrola...
	call READ_DATA
	movfw DATA_L
	sublw 'F'		
	btfss STATUS,Z
	goto NACTI_FAT32__KONEC
	movfw DATA_H
	sublw 'A'		
	btfss STATUS,Z
	goto NACTI_FAT32__KONEC
	call READ_DATA
	movfw DATA_L
	sublw 'T'		
	btfss STATUS,Z
	goto NACTI_FAT32__KONEC
	movfw DATA_H
	sublw '3'		
	btfss STATUS,Z
	goto NACTI_FAT32__KONEC
	call READ_DATA
	movfw DATA_L
	sublw '2'
	btfss STATUS,Z
	goto NACTI_FAT32__KONEC
	; tak, ted uz opravdu vime, ze na tomto sektoru se nachazi spousteci zaznam svazku se souborovym systemem FAT32...
	; tak ted jdem vypocitat ty nejdulezitejsi cisla pro praci s FATkou...

	INDF_BANK_1					; aritmeto/logicke operace
	movlw 0xA0					; OPERAND_X
	movwf FSR
	movfw POCATEK_FAT1
	movwf INDF
	incf FSR,F
	movfw POCATEK_FAT2
	movwf INDF
	incf FSR,F
	movfw POCATEK_FAT3
	movwf INDF
	incf FSR,F
	movfw POCATEK_FAT4
	movwf INDF
	incf FSR,F
	movfw LBA1					; OPERAND_Y
	movwf INDF
	incf FSR,F
	movfw LBA2
	movwf INDF
	incf FSR,F
	movfw LBA3
	movwf INDF
	incf FSR,F
	movfw LBA4
	movwf INDF
	incf FSR,F
	call SOUCET					; pricteme k zacatku oddilu pocet rezervovanych sektoru (obvykle 32) a mame z toho POCATEK_FAT
	movfw INDF
	movwf POCATEK_FAT1
	incf FSR,F
	movfw INDF
	movwf POCATEK_FAT2
	incf FSR,F
	movfw INDF
	movwf POCATEK_FAT3
	incf FSR,F
	movfw INDF
	movwf POCATEK_FAT4
	incf FSR,F

	; v POCATEK_DAT ted mame hodnotu "velikost fat", tu vynasobime 2 a pricteme POCATEK_FAT. Tak ziskame POCATEK_DAT
	movlw 0xA0					; OPERAND_X
	movwf FSR
	movfw POCATEK_DAT1
	movwf INDF
	incf FSR,F
	movfw POCATEK_DAT2
	movwf INDF
	incf FSR,F
	movfw POCATEK_DAT3
	movwf INDF
	incf FSR,F
	movfw POCATEK_DAT4
	movwf INDF
	incf FSR,F
	call POSUNDOLEVA_1			; X := X * 2 -> POCATEK_DAT := 2 * "velikost fat"
								; ted jeste staci pricist POCATEK_FAT
	movfw POCATEK_FAT1
	movwf INDF
	incf FSR,F
	movfw POCATEK_FAT2
	movwf INDF
	incf FSR,F
	movfw POCATEK_FAT3
	movwf INDF
	incf FSR,F
	movfw POCATEK_FAT4
	movwf INDF
	incf FSR,F
	call SOUCET

	;   tady je pro me jedna zcela nepochopitelna vlastnost FATky, a to to, ze prvni dva zaznamy (nulty a prvni)
	;   ve FAT tabulce jsou obsazeny nejakyma srotama (identifikator FATky), coz by nebylo to nejhorsi, ale data na disku
	;   zacinaji jiz na nultym clusteru. (POCATEK_DAT) Dochazi tedy k tomu, ze nulty cluster na disku je reprezentovan na druhe
	;   pozici ve fatce a to cislem dve!!! Od udaje ve fatce bychom musime tedy vzdy odecist hodnotu 2
	;   a ziskali bychom skutecnou polohu dat na disku.... (Je to pekne na vyliz!!!!!!!!)
	;   Ja to tady resim tak, ze zacatek dat posunu o 2 clustery niz (POCATEK_DAT := POCATEK_DAT - 2*VELIKOST_CLUSTERU),
	;   aby udaje souhlasily a my nemuseli nic prepocitavat. 
	;   Pak tu nastava jeste jeden problem, ROOT adresar byva adresovan jako by byl na clusteru 0, proto pokazdy kdyz je 
	;   nekde cislo clusteru 0, tak skocime na prvni cluster root adresare. (Vetsinou 2. cluster)
	;   O tomto jevu jsem nikde necetl, ale proste to tak je. Z toho vyplyva, ze zadny soubor nemuze byt na slusteru 1...
	
	; Tak ted mame v POCATEK_DAT = POCATEK_FAT + (velikostFat * 2)
	; a ted jeste musime odecist 2 * velikost_clusteru

	rlf CLUSTER_SIZE,W		; W := CLUSTER_SIZE * 2
	BANK_1
	movwf OPERAND_Y1
	clrf OPERAND_Y2
	clrf OPERAND_Y3
	clrf OPERAND_Y4
	movfw VYSLEDEK1
	movwf OPERAND_X1
	movfw VYSLEDEK2
	movwf OPERAND_X2
	movfw VYSLEDEK3
	movwf OPERAND_X3
	movfw VYSLEDEK4
	movwf OPERAND_X4
	BANK_0
	call ROZDIL				; VYSLEDEK := POCATEK_FAT + (2 * velikostFat) - (2 * CLUSTER_SIZE)
	movfw INDF
	movwf POCATEK_DAT1
	incf FSR,F
	movfw INDF
	movwf POCATEK_DAT2
	incf FSR,F
	movfw INDF
	movwf POCATEK_DAT3
	incf FSR,F
	movfw INDF
	movwf POCATEK_DAT4
	incf FSR,F
	
	; Tak ted uz to konecne mame, muzeme se pustit do prohlizeni adresaru a souboru...

	bsf ATA_ATTRIBUTES,FAT32_LOAD	
NACTI_FAT32__KONEC
	return	
;**************************************************************************
CLUSTER_TO_LBA
	; vezme hodnoty v CLUSTER[1-4] a POZICE (sektor v clusteru) a do LBA 1-4 vypocita skutecnou pozici na disku
	; pro spravnou funkci musi byt POZICE < CLUSTER_SIZE (POZICE muze byt v rozsahu 0 .. CLUSTER_SIZE - 1)
	; LBA := POCATEK_DAT + (CLUSTER * CLUSTER_SIZE) + POZICE
	INDF_BANK_1 				; neprime adresovani do banku1
	movlw 0xA0					; OPERAND_X
	movwf FSR
	movfw CLUSTER1
	movwf INDF
	incf FSR,F
	movfw CLUSTER2
	movwf INDF
	incf FSR,F
	movfw CLUSTER3
	movwf INDF
	incf FSR,F
	movfw CLUSTER4
	movwf INDF
	incf FSR,F

	; Nejdriv se koukneme zda-li CLUSTER se nerovna 0, to bychom pak vratily 
	; pozici na prvnim clusteru root adresare...
	call NULA						; if (X =  0) then PRETECENI := 0 else PRETECENI := 1
	BANK_1
	btfsc PRETECENI,0
	goto CLUSTER_TO_LBA_NO_ROOT
	BANK_0
	movlw 0xA0					; OPERAND_X
	movwf FSR
	movfw ROOT_DIR_CL1
	movwf INDF
	incf FSR,F
	movfw ROOT_DIR_CL2
	movwf INDF
	incf FSR,F
	movfw ROOT_DIR_CL3
	movwf INDF
	incf FSR,F
	movfw ROOT_DIR_CL4
	movwf INDF
	incf FSR,F
		
CLUSTER_TO_LBA_NO_ROOT
	BANK_0
	; CLUSTER_SIZE je vzdy exponentem 2 (1,2,4,8,16,32,64,128), proto tento jednoduchy zapis
	btfsc CLUSTER_SIZE,1		; 2
	call POSUNDOLEVA_1			; X := X * 2
	btfsc CLUSTER_SIZE,2		; 4
	call POSUNDOLEVA_2			; X := X * 4
	btfsc CLUSTER_SIZE,3		; 8
	call POSUNDOLEVA_3			; X := X * 8
	btfsc CLUSTER_SIZE,4		; 16
	call POSUNDOLEVA_4			; X := X * 4
	btfsc CLUSTER_SIZE,5		; 32
	call POSUNDOLEVA_5			; X := X * 32
	btfsc CLUSTER_SIZE,6		; 64
	call POSUNDOLEVA_6			; X := X * 64
	btfsc CLUSTER_SIZE,7		; 128
	call POSUNDOLEVA_7			; X := X * 128
	
	movfw POCATEK_DAT1
	movwf INDF					; OPERAND_Y
	incf FSR,F
	movfw POCATEK_DAT2
	movwf INDF
	incf FSR,F
	movfw POCATEK_DAT3
	movwf INDF
	incf FSR,F
	movfw POCATEK_DAT4
	movwf INDF
	incf FSR,F

	call SOUCET					; VYSLEDEK := POCATEK_DAT + (CLUSTER * CLUSTER_SIZE)

	; zbyva tedy k vysledku pricist POZICE a dat nasledny vysledek do LBA	 
	movfw POZICE
	BANK_1
	movwf OPERAND_Y1
	clrf OPERAND_Y2
	clrf OPERAND_Y3
	clrf OPERAND_Y4
	movfw VYSLEDEK1
	movwf OPERAND_X1
	movfw VYSLEDEK2
	movwf OPERAND_X2
	movfw VYSLEDEK3
	movwf OPERAND_X3
	movfw VYSLEDEK4
	movwf OPERAND_X4	
	BANK_0
	call SOUCET

	INDF_BANK_1 				; neprime adresovani do banku1
	movlw 0xA8					; VYSLEDEK
	movwf FSR
	movfw INDF
	movwf LBA1
	incf FSR,F
	movfw INDF
	movwf LBA2
	incf FSR,F
	movfw INDF
	movwf LBA3
	incf FSR,F
	movfw INDF
	movwf LBA4
	incf FSR,F
	
	return
;**************************************************************************
NEXT_CLUSTER
	; V CLUSTER prijme cislo clusteru, podiva se do FATky na disku a v CLUSTER vrati 
	; hodnotu clustru, ktery nasleduje v retezu clusteru.
	; Pokud pozadovany cluster byl posledni v retezu vrati v reg. POZICE konstantu FFh
	; Pokud soucasny cluster je prazdny (coz by se stat nemelo) vrati taky v POZICE FFh
	; Jinak, pokud s vse povede, dame do POZICE 0

	; ! PODPROGRAM NETESTUJE ZDA NEBYLO ZADANO VETSI CISLO NEZ JE POCET CLUSTERU !!!
	
	clrf POZICE
	; LBA := [(CLUSTER * 4) / 512 ] + POCATEK_FAT
	; LBA := ( CLUSTER / 128 ) + POCATEK_FAT
	; offset := CLUSTER mod 128 
	INDF_BANK_1 				; neprime adresovani do banku1
	movlw 0xA0					; OPERAND_X
	movwf FSR
	movfw CLUSTER1
	movwf INDF
	incf FSR,F
	movfw CLUSTER2
	movwf INDF
	incf FSR,F
	movfw CLUSTER3
	movwf INDF
	incf FSR,F
	movfw CLUSTER4
	movwf INDF

	; Nejdriv se koukneme zda-li CLUSTER se nerovna 0, to pak musime jako cluster brat prvni cluster ROOT adr.
	call NULA						; if (X =  0) then PRETECENI := 0 else PRETECENI := 1
	BANK_1
	btfsc PRETECENI,0
	goto NEXT_CLUSTER_NO_ROOT
	BANK_0
	movlw 0xA0					; OPERAND_X
	movwf FSR
	movfw ROOT_DIR_CL1
	movwf INDF
	incf FSR,F
	movfw ROOT_DIR_CL2
	movwf INDF
	incf FSR,F
	movfw ROOT_DIR_CL3
	movwf INDF
	incf FSR,F
	movfw ROOT_DIR_CL4
	movwf INDF
	incf FSR,F
		
NEXT_CLUSTER_NO_ROOT
	BANK_0
	
	call POSUNDOPRAVA_7	; X := X div 128  ; PRETECENI := X mod 128
	movlw 0xAC					; PRETECENI
	movwf FSR
	movfw INDF
	movwf TEMP1

	movlw 0xA4					; OPERAND_Y
	movwf FSR
	movfw POCATEK_FAT1
	movwf INDF
	incf FSR,F
	movfw POCATEK_FAT2
	movwf INDF
	incf FSR,F
	movfw POCATEK_FAT3
	movwf INDF
	incf FSR,F
	movfw POCATEK_FAT4
	movwf INDF
	incf FSR,F

	call SOUCET
	
	movfw INDF					; FSR ukazuje na VYSLEDEK
	movwf LBA1
	incf FSR,F
	movfw INDF
	movwf LBA2
	incf FSR,F
	movfw INDF
	movwf LBA3
	incf FSR,F
	movfw INDF
	movwf LBA4
	incf FSR,F
	
	clrf FEATURES
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR

	bcf STATUS,C				; TEMP1 := CLUSTER mod 128 (TEMP1 je v intervalu 0..127)
	rlf TEMP1,W					; W := TEMP1 * 2
	movwf TEMP1
	andlw h'FF'
	btfss STATUS,Z
	call PRESKOC				; pokud je zaznam o clusteru na nulte pozici v sektoru, nic preskakovat nebudem...


	movlw 0xA0					; OPERAND_X
	movwf FSR		
	call READ_DATA	
	movfw DATA_L
	movwf INDF
	movwf CLUSTER1
	incf FSR,F
	movfw DATA_H
	movwf INDF
	movwf CLUSTER2
	incf FSR,F	
	call READ_DATA	
	movfw DATA_L
	movwf INDF
	movwf CLUSTER3
	incf FSR,F
	movfw DATA_H
	movwf INDF
	movwf CLUSTER4
	incf FSR,F

	; ted mame hodnotu clusteru ktery nam byl na pocatku predan v reg. CLUSTER, podivame se zda nebyl nasledkem 
	; nejake chyby prazdny, nebo zda neni posledni v alokacnim retezu
	call NULA						; if (OPERAND_X =  0) then PRETECENI := 0 else PRETECENI := 1
	BANK_1
	btfsc PRETECENI,0
	goto NEXT_CLUSTER_NEPRAZDNY
	BANK_0
	movlw h'FF'
	movwf POZICE
	goto NEXT_CLUSTER_KONEC			; Nevim sice jak by se toto mohlo stat, ale cluster byl prazdny, proto neni jiz co resit..
NEXT_CLUSTER_NEPRAZDNY
	BANK_0
	; Ted se podivame zda cluster nebyl posledni v alokacnim retezu -> cluster >= 0x0FFFFFF7
	movlw 0xF7
	movwf INDF
	incf FSR,F
	movlw 0xFF
	movwf INDF
	incf FSR,F
	movlw 0xFF
	movwf INDF
	incf FSR,F
	movlw 0x0F
	movwf INDF
	incf FSR,F
	
	call ROZDIL						; VYSLEDEK := X - Y 
									; pri podteceni PRETECENI = 1 ( VYSLEDEK < 0 => PRETECENI = 1 )
	BANK_1
	btfsc PRETECENI,0
	goto NEXT_CLUSTER_KONEC
	BANK_0
	movlw h'FF'
	movwf POZICE
NEXT_CLUSTER_KONEC
	BANK_0
	return
;**************************************************************************
