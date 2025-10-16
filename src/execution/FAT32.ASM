;**********************************************************
;**********************************************************
;**********************************************************
; OBSLUZNE PODPROGRAMY PRO FAT32
;**********************************************************
;**********************************************************
;**********************************************************

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
ZJISTI_FRAGMENT
; v CLUSTER[1-4] prijme cislo clusteru a do FRAGMENT[1-2] umisti kolik clusteru 
; po tomto clusteru nasledujich tvori jeden fragment
; (pokud je retezec tvoren pouze z tohoto clusteru, je vraceno cislo 0)

; Pokud soucasny cluster je prazdny (coz by se stat nemelo) vrati v POZICE FFh
; Jinak, pokud s vse povede, dame do POZICE 0

; ! PODPROGRAM NENI POUZITELNY PRO CLUSTER 0 (prvni cluster ROOT adresare)
; ! PODPROGRAM NETESTUJE ZDA NEBYLO ZADANO VETSI CISLO NEZ JE POCET CLUSTERU !!!
	
	clrf POZICE
	clrf FRAGMENT2
	;movlw .1
	;movwf FRAGMENT1
	clrf FRAGMENT1
	; LBA := [(CLUSTER * 4) / 512 ] + POCATEK_FAT
	; LBA := ( CLUSTER / 128 ) + POCATEK_FAT
	; offset := CLUSTER mod 128 
	INDF_BANK_1 				; neprime adresovani do banku1
	movlw 0xA0					; OPERAND_X
	movwf FSR
	movfw CLUSTER1
	movwf HL_ADR_CL1			; v HL_ADR_CL[1-4] mam hodnotu clusteru na predchozim zaznamu, proto si prvni cluster dame sem
	movwf INDF
	incf FSR,F
	movfw CLUSTER2
	movwf HL_ADR_CL2
	movwf INDF
	incf FSR,F
	movfw CLUSTER3
	movwf HL_ADR_CL3
	movwf INDF
	incf FSR,F
	movfw CLUSTER4
	movwf HL_ADR_CL4
	movwf INDF

	call POSUNDOPRAVA_7			; X := X div 128  ; PRETECENI := X mod 128
	movlw 0xAC					; PRETECENI
	movwf FSR
	movfw INDF
	movwf TEMP5					; TEMP5 := CLUSTER mod 128 (TEMP5 je v intervalu 0..127)
;	bcf STATUS,C				
;	rlf TEMP2,W					; W := TEMP1 * 2

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

	bcf STATUS,C
	rlf TEMP5,w
	movwf TEMP1					; TEMP1 := TEMP5 * 2
	movfw TEMP5
	andlw h'FF'
	btfss STATUS,Z
	call PRESKOC				; pokud je zaznam o clusteru na nulte pozici v sektoru, nic preskakovat nebudem...
								; preskakujeme pouze na zacatku, pak jdou hezky za sebou
	goto ZJISTI_FRAGMENT_CLUSTER
ZJISTI_FRAGMENT_CTI_SECTOR

	clrf FEATURES
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR

ZJISTI_FRAGMENT_CLUSTER
	movlw 0xA0					; OPERAND_X
	movwf FSR		
	call READ_DATA	
	movfw DATA_L
	movwf INDF
	incf FSR,F
	movfw DATA_H
	movwf INDF
	incf FSR,F	
	call READ_DATA	
	movfw DATA_L
	movwf INDF
	incf FSR,F
	movfw DATA_H
	movwf INDF
	incf FSR,F


	; ted mame hodnotu clusteru v OPERAND_X. pokud je posledni v retezci, nebo je prazdny, tak koncime
	call NULA						; if (OPERAND_X =  0) then PRETECENI := 0 else PRETECENI := 1
	BANK_1
	btfsc PRETECENI,0
	goto ZJISTI_FRAGMENT_NEPRAZDNY
	BANK_0
	goto ZJISTI_FRAGMENT_KONEC			; Nevim sice jak by se toto mohlo stat, ale cluster byl prazdny, proto neni jiz co resit..
ZJISTI_FRAGMENT_NEPRAZDNY
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
	btfss PRETECENI,0				; pokud je vysledek zaporny, je neni cluster posledni a my pokracujeme...
	goto ZJISTI_FRAGMENT_KONEC
	BANK_0

	movlw 0xA4						; OPERAND_Y
	movwf FSR		
	movfw HL_ADR_CL1				; v HL_ADR_CL[1-4] mam hodnotu clusteru na predchozim zaznamu
	movwf INDF
	incf FSR,F
	movfw HL_ADR_CL2
	movwf INDF
	incf FSR,F
	movfw HL_ADR_CL3
	movwf INDF
	incf FSR,F
	movfw HL_ADR_CL4
	movwf INDF


	call ROZDIL						; VYSLEDEK := SOUCASNY_CL - PREDCHOZI_CL
									; vysledek se musi rovnat 1
	BANK_1
	movfw VYSLEDEK4
	iorwf VYSLEDEK3,W
	iorwf VYSLEDEK2,W
	btfss STATUS,Z
	goto ZJISTI_FRAGMENT_KONEC
	movfw VYSLEDEK1
	sublw .1
	btfss STATUS,Z
	goto ZJISTI_FRAGMENT_KONEC
	BANK_0

	; OK, ted vime, ze predchozi cluster byl o jednu mensi, nez soucasny...
	; podivame se zda neni FRAGMENT moc velky...
	btfsc FRAGMENT2,7
	goto ZJISTI_FRAGMENT_KONEC
	
	; FRAGMENT++
	incf FRAGMENT1,f
	btfsc STATUS,Z
	incf FRAGMENT2,f

	movlw 0xA0						; OPERAND_X
	movwf FSR		
	movfw INDF
	movwf HL_ADR_CL1				; v HL_ADR_CL[1-4] mam hodnotu clusteru na predchozim zaznamu
	incf FSR,F
	movfw INDF
	movwf HL_ADR_CL2
	incf FSR,F
	movfw INDF
	movwf HL_ADR_CL3
	incf FSR,F
	movfw INDF
	movwf HL_ADR_CL4


	incf TEMP5,f
	movfw TEMP5
	sublw .128
	btfss STATUS,Z
	goto ZJISTI_FRAGMENT_CLUSTER

	clrf TEMP5

	; LBA++
	movlw .1
	addwf LBA1,f
	btfss STATUS,C
	goto ZJISTI_FRAGMENT_INC_KONEC
	addwf LBA2,f
	btfss STATUS,C
	goto ZJISTI_FRAGMENT_INC_KONEC
	addwf LBA3,f
	btfss STATUS,C
	goto ZJISTI_FRAGMENT_INC_KONEC
	addwf LBA4,f
ZJISTI_FRAGMENT_INC_KONEC

	BANK_0
	goto ZJISTI_FRAGMENT_CTI_SECTOR

ZJISTI_FRAGMENT_KONEC
	BANK_0
	return
;**************************************************************************
