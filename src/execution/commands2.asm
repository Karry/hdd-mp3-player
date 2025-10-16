; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; tady jsou procedury resici jednotlive prikazy
; Pokud je v zasobniku prikaz pro nejakou proceduru, musi tato procedura nastavit byt STAV_PRIKAZU do 1 (i kdyz treba nema vsechny parametry)
; Pokud procedura najde svuj prikaz a jsou prijate vsechny parametry, musi odeslat nejakou odpoved po USARTu a smazat reg. PRIJATYCH_DAT!!!
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; CAST 2 
PRIKAZ_0Bh						; 0Bh – zjisti velikost fragmentu
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
PRIKAZ_0Ch						; 0Ch – najdi záznam o tomto adresáøi v nadøazeném adresáøi
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
PRIKAZ_0Dh						; 0Dh – nastav dobu, po ktere se disk prepne do STANDBY
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

;	movfw KONST_NECINNOSTI1
;	call WR_USART
;	movfw KONST_NECINNOSTI2
;	call WR_USART
;	movfw CITAC_NECINNOSTI1
;	call WR_USART
;	movfw CITAC_NECINNOSTI2
;	call WR_USART
	PROG_PAGE_2

	clrf PRIJATYCH_DAT			; vyprazdnime zasobnik
	return
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PRIKAZ_85h						; 85h – nastav pøedvolený „ekvalizér“
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
