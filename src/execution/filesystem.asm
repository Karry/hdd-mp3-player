;**********************************************************
;**********************************************************
;**********************************************************
; podprogramy pro praci s adresari a setrideni obsahu adresaru
;**********************************************************
;**********************************************************
;**********************************************************

;**************************************************************************
PRVNI_CL_ADRESARE
	; V CLUSTER[1-4] prijme cislo clusteru. Zkontroluje, zda zadany sluster obsahuje zacatek adresare
	; V POZICE vrati 00h, pokud cluster je prvni cluster nejakeho adresare, FFh, pokud neobsahuje adresar
	clrf POZICE

	movfw CLUSTER1
	iorwf CLUSTER2,W
	iorwf CLUSTER3,W
	iorwf CLUSTER4,W
	btfsc STATUS,Z
	return				; pokud CLUSTER[1-4]=0, tak se jedna o 1. cluster ROOT adr., proto nemusime dale resit co tam je...
	
	PROG_PAGE_0
	call CLUSTER_TO_LBA
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR	; precteme udajny prvni sektor z prvniho clusteru adresare	
	PROG_PAGE_1

	; Tady vychazime z toho, ze kazdy adresar krome ROOTu ma jako prvni zaznam ukazatel na sebe (jako jmeno je jedna tecka)
	; Mohlo by se sice stat, ze bychom narazili na soubor, ktery zacina retezcem ".          " to bych ale neresil...
	movlw h'FF'
	movwf POZICE

	PROG_PAGE_0
	call READ_DATA
	PROG_PAGE_1
	movfw DATA_L
	sublw '.'		; 1. znak
	btfss STATUS,Z
	goto PRVNI_CL_ADRESARE_KONEC
	movfw DATA_H
	sublw h'20'		; 2. znak
	btfss STATUS,Z
	goto PRVNI_CL_ADRESARE_KONEC

	movlw .4		; dalsich 8 znaku maji byt mezery
	movwf TEMP1
	
PRVNI_CL_ADRESARE_MEZERY
	PROG_PAGE_0
	call READ_DATA
	PROG_PAGE_1
	movfw DATA_L
	sublw h'20'
	btfss STATUS,Z
	goto PRVNI_CL_ADRESARE_KONEC
	movfw DATA_H
	sublw h'20'
	btfss STATUS,Z
	goto PRVNI_CL_ADRESARE_KONEC
	decfsz TEMP1,f
	goto PRVNI_CL_ADRESARE_MEZERY

	PROG_PAGE_0
	call READ_DATA
	PROG_PAGE_1
	movfw DATA_L
	sublw h'20'
	btfss STATUS,Z
	goto PRVNI_CL_ADRESARE_KONEC

	clrf POZICE	
PRVNI_CL_ADRESARE_KONEC
	return
;**************************************************************************
SKOC_NA_ZAZNAM
	; !!!! pozor, tato procedura potrebuje min. 5 mist ve STACKu (vcetne sama sebe)

	; V CLUSTER[1-4] prijme cislo clusteru na kterem se nachazi zacatek adresare
	; V ZAZNAM[1-2] prijme cislo zaznamu 
	; - pokud ZAZNAM[1-2] ukazuji mimo adresar, vrati v POZICE FFh (jinak 00h)
	; - pokud byl zaznam nalezen,
	; 	da disku prikaz k jeho precteni a skoci az k zaznamu...
	; 	...v bufferu disku budeme mit teda 32bytu dat ktere prezentuji jeden zaznam ve slozce
	movfw ZAZNAM1
	BANK_1
	movwf OPERAND_X1
	BANK_0
	movfw ZAZNAM2
	BANK_1
	movwf OPERAND_X2
	clrf OPERAND_X3
	clrf OPERAND_X4
	BANK_0					; OPERAND_X := ZAZNAM
	
	PROG_PAGE_0
	call POSUNDOPRAVA_4		; OPERAND_X := OPERAND_X div 16
	; tady mame v PRETECENI kolikaty zaznam v sektoru chceme
	BANK_1
	movfw PRETECENI
	BANK_0
	movwf TEMP5
	BANK_1
	clrf PRETECENI				; pokud CLUSTER_SIZE = 1 tak preteceni := 0 a X zustane stejne
	BANK_0

	btfsc CLUSTER_SIZE,1		; 2
	call POSUNDOPRAVA_1			; X := X div 2
	btfsc CLUSTER_SIZE,2		; 4
	call POSUNDOPRAVA_2			; X := X div 4
	btfsc CLUSTER_SIZE,3		; 8
	call POSUNDOPRAVA_3			; X := X div 8
	btfsc CLUSTER_SIZE,4		; 16
	call POSUNDOPRAVA_4			; X := X div 4
	btfsc CLUSTER_SIZE,5		; 32
	call POSUNDOPRAVA_5			; X := X div 32
	btfsc CLUSTER_SIZE,6		; 64
	call POSUNDOPRAVA_6			; X := X div 64
	btfsc CLUSTER_SIZE,7		; 128
	call POSUNDOPRAVA_7			; X := X div 128
	; tady mame v PRETECENI na kolikatem sektoru v clusteru je hledany zaznam
	BANK_1
	movfw PRETECENI
	BANK_0
	movwf TEMP4

	; OPERAND_X := (ZAZNAM div 16) div CLUSTER_SIZE
	; ted v OPERAND_X mame hodnotu kolik clusteru mame od zacatku adresare preskocit...
SKOC_NA_ZAZNAM_PRESKOC_CL
	PROG_PAGE_0
	call NULA
	PROG_PAGE_1
	BANK_1
	btfss PRETECENI,0
	goto SKOC_NA_ZAZNAM_MAME_CL	
	BANK_0

	INDF_BANK_1
	movlw 0xA0
	movwf FSR
	movfw INDF
	movwf TEMP2
	incf FSR,F
	movfw INDF
	movwf TEMP3

	PROG_PAGE_0
	call NEXT_CLUSTER
	PROG_PAGE_1
	btfsc POZICE,0		; pokud s vse povedlo, mame v POZICE 0
	goto SKOC_NA_ZAZNAM_MIMO_ROZSAH

	INDF_BANK_1
	movlw 0xA0
	movwf FSR
	movfw TEMP2
	movwf INDF
	incf FSR,F
	movfw TEMP3
	movwf INDF
	BANK_1
	clrf OPERAND_X3
	clrf OPERAND_X4
	BANK_0	

	PROG_PAGE_0
	call DEKREMENTUJ	; X := X - 1
	PROG_PAGE_1

	goto SKOC_NA_ZAZNAM_PRESKOC_CL

SKOC_NA_ZAZNAM_MAME_CL
	BANK_0

	movfw TEMP4					; v kolikatem sektoru v clusteru je hledany zaznam
	movwf POZICE 
	PROG_PAGE_0
	call CLUSTER_TO_LBA			; zjistime si skutecnou polohu zaznamu na disku
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR			; dame prikaz precist sektor
	PROG_PAGE_1

	movlw .16
	movwf ZAZNAMU_vBUFFERU_DISKU
	movfw TEMP5
	subwf ZAZNAMU_vBUFFERU_DISKU,f		; ZAZNAMU_vBUFFERU_DISKU := 16 - TEMP5

	movfw TEMP5					; kolikaty zaznam v casti adersare (sektoru) mame precist [0..15]
	andlw b'00001111'
	movwf TEMP1					; rozsah by mel byt spravne, pro jistotu jej ale orizneme [0..15]
	andlw h'FF'
	btfsc STATUS,Z				; pokud chceme prvni zaznam ze sektoru...
	goto SKOC_NA_ZAZNAM_MAME_ZAZNAM 	; ...koncime

	swapf TEMP1,F				; protoze kazdy zaznam o souboru ma 32B=16slov, tak musime TEMP1 vynasobit 16...
	PROG_PAGE_0
	call PRESKOC				; a tolik slov preskocit (tolik slov je pro nas nepotrebnych)
	PROG_PAGE_1

SKOC_NA_ZAZNAM_MAME_ZAZNAM
	movlw h'00'
	movwf POZICE 
	goto SKOC_NA_ZAZNAM_KONEC
SKOC_NA_ZAZNAM_MIMO_ROZSAH
	movlw h'FF'
	movwf POZICE 
SKOC_NA_ZAZNAM_KONEC
	return
;**************************************************************************
FILE_INFO
	; z disku nam ted ma prijit 32bytu dat, ktere reprezentuji jeden zaznam ve slozce
	; tato procedura zaznam precte, analyzuje, a do bufferu 2 da nasledujici informace:
	;		1.     byte -> 	= 00h -> zaznam je prazdny; 
	;						= 01h -> zaznam je adresar; 
	;						= 02h -> zaznam je soubor; 
	;						= 06h -> zaznam je soubor s priponou MP3
	;		2..9   byte -> 8 znaku dlouhe jmeno ("DOSovsky" tvar - napr. slouzka "dokumenty" = "DOKUME~1" )
	;		10..12 byte -> u souboru tri znaky pripony (u adresaru vetsinou mezery - 20h 20h 20h)
	;		13..16 byte -> 1. cluster souboru
	; Pokud se jedna o adresar, a zaznam o pripone se nerovna 0x202020 (tri mezery), tak skutecne jmeno adresare je : ADRESAR.PRI
	INDF_BANK_2
	movlw 0x10					; 1. byte bufferu 2
	movwf FSR
	movlw .0					; zatim nevime co zaznam obsahuje, tak ho oznacime jako prazdny
	movwf INDF
	incf FSR,F	

	movlw .5					; 5 slov = 10 bytu -> 8 znaku jmena souboru/slozky + 2 znaky pripony
	movwf TEMP1
FILE_INFO__READ_NAME
	PROG_PAGE_0
	call READ_DATA				; 2 znaky jmena souboru/slozky, nebo pripony souboru
	PROG_PAGE_1
	movfw DATA_L
	movwf INDF
	incf FSR,F
	movfw DATA_H
	movwf INDF
	incf FSR,F
	decf TEMP1,F
	btfss STATUS,Z
	goto FILE_INFO__READ_NAME	

	PROG_PAGE_0
	call READ_DATA				; posledni znak pripony a byt s atributy souboru
	PROG_PAGE_1
	movfw DATA_L
	movwf INDF

	movlw 0x11					; 2. byte bufferu 2 -> 1. znak jmena souboru
	movwf FSR
	movfw INDF					; ted ve W mame 1. znak jmena souboru/slozky
	andlw h'FF'
	btfsc STATUS,Z
	goto FILE_INFO__CTI20_KONEC		; pokud 1. znak jmena souboru = 00h, je zaznam prazdny
	sublw h'E5'
	btfsc STATUS,Z
	goto FILE_INFO__CTI20_KONEC		; pokud 1. znak jmena souboru = E5h, je zaznam prazdny
	
	; pokud jsme tady, tak zaznam obsahuje soubor, adresar, dlouhe jmeno souboru, nebo jmenovku disku 
	; (jsou dva zpusoby jak zapsat jmenovku svazku, bud do spousteciho zaznamu, nebo jako polozku ROOT adresare)
	movfw DATA_H				; byt s atributy souboru
	andlw h'0F'
	sublw h'0F'					; if (atributy and 0Fh) = 0Fh -> zaznam s dlouhym nazvem souboru
	btfsc STATUS,Z
	goto FILE_INFO__CTI20_KONEC		; pokud zaznam je dlouhy nazav souboru, koncime
	btfsc DATA_H,3
	goto FILE_INFO__CTI20_KONEC		; if (atributy and 08h) = 08h -> jmenovka disku
	btfsc DATA_H,4				; if (atributy and 10h) = 10h -> adresar
	goto FILE_INFO__DIR

	movlw h'02'					; zaznam je soubor
	movwf TEMP1
	; tady vime, ze zaznam je soubor, tak se podivame, zda to neni mp3
	movlw 0x19					; 10. byt bufferu 2 -> 1. znak pripony souboru
	movwf FSR

	movfw INDF
	sublw 'M'					; (jmena souboru v "DOSovskem" tvaru maji vzdy velka pismena)
	btfss STATUS,Z
	goto FILE_INFO__FILE
	incf FSR,F
	movfw INDF
	sublw 'P'
	btfss STATUS,Z
	goto FILE_INFO__FILE
	incf FSR,F
	movfw INDF
	sublw '3'
	btfss STATUS,Z
	goto FILE_INFO__FILE

	movlw h'06'					; ted je jasne, ze soubor je mp3
	movwf TEMP1
	goto FILE_INFO__FILE

FILE_INFO__DIR
	movlw h'01'					; zaznam je adresar
	movwf TEMP1

FILE_INFO__FILE
	; tady mame v TEMP 1 jednu z nasledujicich hodnot:
	; 01h -> zaznam je adresar; 02h -> zaznam je soubor; 06h -> zaznam je soubor s priponou MP3
	movlw 0x10					; 1. byt bufferu 2 -> identifikace zaznamu
	movwf FSR
	movfw TEMP1
	movwf INDF

	movlw .4
	movwf TEMP1
	PROG_PAGE_0
	call PRESKOC				; nasledujicich 8 bytu ze zaznamu je pro nas k nicemu (obsahuji cas posledni upravy, otevreni a buh vi co jeste...)
	PROG_PAGE_1

	movlw 0x1E					; 15. byt bufferu 2 -> 2. byt prvniho clusteru
	movwf FSR
	PROG_PAGE_0
	call READ_DATA				; jedno slovo -> horni cast cisla prvniho clusteru
	PROG_PAGE_1
	movfw DATA_L
	movwf INDF
	incf FSR,F
	movfw DATA_H
	movwf INDF

	PROG_PAGE_0
	call READ_DATA				; cas vytvoreni   (1 word)
	call READ_DATA				; datum vytvoreni (1 word)

	movlw 0x1C					; 13. byt bufferu 2 -> 0. byt prvniho clusteru
	movwf FSR
	call READ_DATA				; jedno slovo -> dolni cast cisla prvniho clusteru
	PROG_PAGE_1
	movfw DATA_L
	movwf INDF
	incf FSR,F
	movfw DATA_H
	movwf INDF
	
	; Pak jsou v zaznamu jeste 4 byty, ktere obsahuji velikost souboru. Ty mi sice nepotrebujeme,
	; musime je ale precist, aby jsme precetli vsech 32 bytu zaznamu
	movlw .2
	movwf TEMP1
	PROG_PAGE_0
	call PRESKOC
	PROG_PAGE_1
	return
FILE_INFO__CTI20_KONEC
	movlw .10
	movwf TEMP1
	PROG_PAGE_0
	call PRESKOC
	PROG_PAGE_1
	return
;**************************************************************************
FILE_SIZE
	; z disku nam ted ma prijit 32bytu dat, ktere reprezentuji jeden zaznam ve slozce
	; Zaznam by mel byt soubor, podprogram toto nekontroluje (zda zaznam neni adresar)
	; Na zacatek bufferu 1 da 4 byty obsahujici velikost zaznamu
	movlw .14					; my ted potrebujeme jen posledni 4 byty ze zaznamu, tam se nachazi velikost souboru
	movwf TEMP1
	PROG_PAGE_0
	call PRESKOC
	PROG_PAGE_1

	INDF_BANK_2
	movlw 0x10					; 1. byte bufferu 1
	movwf FSR

	PROG_PAGE_0
	call READ_DATA
	movfw DATA_L
	movwf INDF
	incf FSR,F
	movfw DATA_H
	movwf INDF
	incf FSR,F

	call READ_DATA
	PROG_PAGE_1
	movfw DATA_L
	movwf INDF
	incf FSR,F
	movfw DATA_H
	movwf INDF
	incf FSR,F

	return
;**************************************************************************
HLEDEJ
; !!!! pozor, tato procedura potrebuje min. 6 mist ve STACKu (vcetne sama sebe)

; mocna procedura, ktera nam podle zadanych parametru vyhleda pozadovany zaznam 
; a umisti jej do bufferu2 na offset 32 (do horni poloviny bufferu)

; ZAZNAM V DRUHE POLOVINE BUFFERU2 MA NASLEDUJICI STRUKTURU:
;	1. byte:	= 00h -> zadny vyhovujici zaznam nebyl nalezen
;				= 01h -> zaznam je adresar
;				= 02h -> zaznam je soubor; 
;				= 06h -> zaznam je soubor s priponou MP3
;	2..9   byte -> 8 znaku dlouhe jmeno ("DOSovsky" tvar - napr. slouzka "dokumenty" = "DOKUME~1" )
;	10..12 byte -> u souboru tri znaky pripony (u adresaru vetsinou mezery - 20h 20h 20h)
;	13..16 byte -> 1. cluster souboru / adresare
;	17..18 byte -> cislo zaznamu v adresari

; 	HL_PARAMETRY 	-- parametry hledani
;	HL_ADR_CL[1-4]	-- prnvi cluster prohledavaneho adresare
;	ZAZNAM[1-2]		-- zaznam od ktereho hledame

; Filozofie je takova, ze v bufferu 1 mame ulozen zaznam vuci kteremu vyhledavame (ZAZ_REF),
; v dolni polovine bufferu 2 mame ulozen zaznam, ktery jsme prave precetli (ZAZ_A)
; a v hodni polovine bufferu 2 zaznam, ktery zatim byl nejblize k pozadovanemu zaznamu (ZAZ_N).

; Hruby vyvojak by pak mohl vypadat takto:
;******************************************************************************************************
; if ((HL_PARAMETRY = [prvni]):
;	if (CLUSTER = ROOT):
;		HL_PARAMETRY := [dalsi]
;		ZAZ_REF := 0x0000000.....
;		goto hledej_hledani
;	elseif (HL_PARAMETRY != [vracet '..']):
;		ZAZ_REF := zaznam 1
;		HL_PARAMETRY := [dalsi]
;	else
;		ZAZ_N naplnit daty ze zaznamu 1 // prvni polozkou vsech adresaru krome ROOTu jsou ".."
;		goto hledej_konec
;	endif;
; endif;

; if ((CLUSTER != ROOT) and (ZAZNAM<2)):
;		if (HL_PARAMETRY = [dalsi]):
;			ZAZ_REF := 0x0000000.....
;			goto hledej_hledani
;		else:
;			goto hledej_konec
;		endif;
; endif;
;
; ZAZ_REF naplnit daty ze zaznamu ZAZNAM
; ZAZNAM := 0
; if (CLUSTER != ROOT):
;		ZAZNAM :=2
; end;
;
; repeat
;	nacti_zaznam
;	IF     (hledame dalsi zaznam)     AND (ZAZ_A > ZAZ_REF) AND ((ZAZ_A < ZAZ_N) OR (ZAZ_N is empty)):
;			ZAZ_N := ZAZ_A
;	ELSEIF (hledame predchozi zaznam) AND (ZAZ_A < ZAZ_REF) AND (ZAZ_A > ZAZ_N):
;			ZAZ_N := ZAZ_A
;	ENDIF
;	zaznam++
; until (byl zaznam posledni)
;
; if (HL_PARAMETRY = [predchozi]) and (ZAZ_N = 00000) and (!ROOT) and (HL_PARAMETRY = [vracet '..']):
;	ZAZ_N naplnit daty ze zaznamu 1
; endif;
; KONEC
;******************************************************************************************************
	PROG_PAGE_0
	call CLEAR_BUFFER2		; vymazeme si buffer2, abychom tam nemeli bordel
	PROG_PAGE_1
	call CLEAR_BUFFER1		; vymazeme si buffer1, abychom tam nemeli bordel

	movfw HL_ADR_CL1
	movwf CLUSTER1
	movfw HL_ADR_CL2
	movwf CLUSTER2
	movfw HL_ADR_CL3
	movwf CLUSTER3
	movfw HL_ADR_CL4
	movwf CLUSTER4

	; protoze to budeme v nasledujicim kodu potrebova, nastavime si 7. bit HL_PARAMETRY podle toho, 
	; zda predany adresar je ROOT ci nikoliv
	;		7. bit - tento bit nelze nastavit uzivatelem
	;			= 0 > adresar je ROOT
	;			= 1 > adresar neni ROOT
	bcf HL_PARAMETRY,7
	movlw h'FF'	
	andwf CLUSTER1,F
	btfss STATUS,Z
		bsf HL_PARAMETRY,7
	andwf CLUSTER2,F
	btfss STATUS,Z
		bsf HL_PARAMETRY,7
	andwf CLUSTER3,F
	btfss STATUS,Z
		bsf HL_PARAMETRY,7
	andwf CLUSTER4,F
	btfss STATUS,Z
		bsf HL_PARAMETRY,7

; if ((HL_PARAMETRY = [prvni]):
;	if (CLUSTER = ROOT):
;		HL_PARAMETRY := [dalsi]
;		ZAZ_REF := 0x0000000.....
;		goto hledej_hledani
;	elseif (HL_PARAMETRY != [vracet '..']):
;		ZAZ_REF := zaznam 1
;		HL_PARAMETRY := [dalsi]
;	else
;		ZAZ_N naplnit daty ze zaznamu 1 // prvni polozkou vsech adresaru krome ROOTu jsou ".."
;		goto hledej_konec
;	endif;
; endif;

	btfss HL_PARAMETRY,3			; if ((HL_PARAMETRY = [prvni]):
	goto HLEDEJ_NEHLEDAME_PRVNI
	btfsc HL_PARAMETRY,7			; 		IF (CLUSTER = ROOT):
	goto HLEDEJ_ELSEIF1
	bcf HL_PARAMETRY,4
	goto HLEDEJ_HLEDANI
HLEDEJ_ELSEIF1						; 		elseif (HL_PARAMETRY = [vracet '..']):
	btfss HL_PARAMETRY,5
	goto HLEDEJ_ELSE1
	movlw .1
	movwf ZAZNAM1
	clrf ZAZNAM2					; 			ZAZ_REF := zaznam 1
	bcf HL_PARAMETRY,4
	goto HLEDEJ_NEHLEDAME_PRVNI
HLEDEJ_ELSE1
	movlw .1
	movwf ZAZNAM1
	clrf ZAZNAM2
	call SKOC_NA_ZAZNAM	
	call FILE_INFO
	call ZAPIS_C_ZAZNAMU
	call BUF2_LOW_TO_HIGH
	goto HLEDEJ_KONEC				;		ENDIF;
HLEDEJ_NEHLEDAME_PRVNI				; ENDIF 

	btfss HL_PARAMETRY,7
	goto HLEDEJ_IF2_ENDIF
	movfw ZAZNAM2 
	andlw h'FF'
	btfss STATUS,Z
	goto HLEDEJ_IF2_ENDIF
	movfw ZAZNAM1
	andlw h'FF'
	btfsc STATUS,Z
	goto IF2
	sublw .1
	btfss STATUS,Z
	goto HLEDEJ_IF2_ENDIF			; if ((CLUSTER != ROOT) and (ZAZNAM < 2)):
IF2
	btfsc HL_PARAMETRY,4			;		if (HL_PARAMETRY = [predchozi]):
	goto HLEDEJ_KONEC				;		... else:
	goto HLEDEJ_HLEDANI				;		... endif;
HLEDEJ_IF2_ENDIF					; endif

	call SKOC_NA_ZAZNAM		; - pokud ZAZNAM[1-2] ukazuji mimo adresar, vrati v POZICE FFh (jinak 00h)
	btfsc POZICE,0
	goto HLEDEJ_KONEC	
	call FILE_INFO
	call ZAPIS_C_ZAZNAMU	
	call BUF2_TO_BUF1

HLEDEJ_HLEDANI	
	clrf ZAZNAM1
	clrf ZAZNAM2
	btfsc HL_PARAMETRY,7
	bsf ZAZNAM1,1			; if (!ROOT): ZAZNAM = 2; endif;
	clrf ZAZNAMU_vBUFFERU_DISKU
HLEDEJ_REPEAT
	movfw HL_ADR_CL1
	movwf CLUSTER1
	movfw HL_ADR_CL2
	movwf CLUSTER2
	movfw HL_ADR_CL3
	movwf CLUSTER3
	movfw HL_ADR_CL4
	movwf CLUSTER4


	clrf POZICE
	movfw ZAZNAMU_vBUFFERU_DISKU
	andlw h'FF'
	btfsc STATUS,Z			; pokud jeste nejake po sobe jdouci zaznamy jsou pripraveny v bufferu disku, tak nemusime volat SKOC_NA_ZAZNAM
	call SKOC_NA_ZAZNAM		; - pokud ZAZNAM[1-2] ukazuji mimo adresar, vrati v POZICE FFh (jinak 00h)
	btfsc POZICE,0
	goto HLEDEJ_END_REPEAT

	decf ZAZNAMU_vBUFFERU_DISKU,f	; ted jeden zaznam precteme, proto jich bude v bufferu disku o jeden min
	call FILE_INFO
	call ZAPIS_C_ZAZNAMU

	incf ZAZNAM1,f
	btfsc STATUS,Z
	incf ZAZNAM2,f

	call VYHOVUJE_ZAZNAM
	btfss TEMP1,0
	goto HLEDEJ_REPEAT
	
;	movlw .16
;	movwf TEMP1
;	PROG_PAGE_0
;	call ODESLI_BUFFER2			; odesleme si zaznam o souboru	
;	call DELAY_500ms    
;	PROG_PAGE_1

;	IF     (hledame dalsi zaznam)
;		IF (ZAZ_A > ZAZ_REF) AND ((ZAZ_A < ZAZ_N) OR (ZAZ_N is empty)):
;			ZAZ_N := ZAZ_A
;		ENDIF
;	ELSEIF (hledame predchozi zaznam)
;		IF (ZAZ_A < ZAZ_REF) AND (ZAZ_A > ZAZ_N):
;			ZAZ_N := ZAZ_A
;		ENDIF
;	ENDIF
	call COMPARE_BUFF1_BUFF2
	; porovna nazvy souboru na zacatku bufferu1 s bufferem2
	; pokud v abecede je driv nazev v bufferu1 da to TEMP1 0x01
	; pokud v abecede je driv nazev v bufferu2 da to TEMP1 0x02
	; pokud se nazvy shoduji da do TEMP1 0x00
	btfsc HL_PARAMETRY,4		;	IF     (hledame dalsi zaznam)
	goto HLEDEJ_ELSE3
	btfss TEMP1,0				;		IF (ZAZ_A > ZAZ_REF)
	goto HLEDEJ_ENDIF3

	BANK_2
	movfw 0x30
	BANK_0
	andlw h'FF'
	btfsc STATUS,Z
	goto HLEDEJ_IF4

	call COMPARE_BUFF2_L_H
	; porovna nazvy souboru na zacatku bufferu2 a na konci bufferu2
	; pokud v abecede je driv nazev v horni polovine buff2 da to TEMP1 0x01
	; pokud v abecede je driv nazev v dolni polovine buff2 da to TEMP1 0x02
	; pokud se nazvy shoduji da do TEMP1 0x00
	btfss TEMP1,1
	goto HLEDEJ_ENDIF3
HLEDEJ_IF4						; 		AND ((ZAZ_A < ZAZ_N) OR (ZAZ_N is empty)):
	call BUF2_LOW_TO_HIGH		;				ZAZ_N := ZAZ_A
	goto HLEDEJ_ENDIF3			;		ENDIF
HLEDEJ_ELSE3					;	ELSEIF (hledame predchozi zaznam)
	btfss TEMP1,1				;		IF (ZAZ_A < ZAZ_REF)
	goto HLEDEJ_ENDIF3
	call COMPARE_BUFF2_L_H
	btfss TEMP1,0				;		AND (ZAZ_A > ZAZ_N):
	goto HLEDEJ_ENDIF3
	call BUF2_LOW_TO_HIGH		;				ZAZ_N := ZAZ_A
HLEDEJ_ENDIF3					;	ENDIF
	
	goto HLEDEJ_REPEAT
HLEDEJ_END_REPEAT

; if (HL_PARAMETRY = [predchozi]) and (ZAZ_N = 00000) and (!ROOT) and (HL_PARAMETRY = [vracet '..']):
;	ZAZ_N naplnit daty ze zaznamu 1
; endif;
	btfss HL_PARAMETRY,4		; if (HL_PARAMETRY = [predchozi])
	goto HLEDEJ_KONEC
	btfss HL_PARAMETRY,7		; 	and (!ROOT)
	goto HLEDEJ_KONEC
	BANK_2
	movfw 0x30
	BANK_0
	andlw h'FF'
	btfss STATUS,Z				; 	and (ZAZ_N is empty):
	goto HLEDEJ_KONEC
	btfsc HL_PARAMETRY,5		; and (HL_PARAMETRY = [vracet '..'])
	goto HLEDEJ_KONEC

	movfw HL_ADR_CL1
	movwf CLUSTER1
	movfw HL_ADR_CL2
	movwf CLUSTER2
	movfw HL_ADR_CL3
	movwf CLUSTER3
	movfw HL_ADR_CL4
	movwf CLUSTER4
	movlw .1
	movwf ZAZNAM1
	clrf ZAZNAM2
	call SKOC_NA_ZAZNAM	
	call FILE_INFO
	call ZAPIS_C_ZAZNAMU
	call BUF2_LOW_TO_HIGH

HLEDEJ_KONEC					; endif;

	return
;**************************************************************************
ZAPIS_C_ZAZNAMU
	; podprogram FILE_INFO nam dava vsechny mozny informace o souboru, krome cisla zaznamu, 
	; proto si toto cislo musime zapsat sami do bufferu2
	movfw ZAZNAM1
	BANK_2
	movwf 0x120
	BANK_0
	movfw ZAZNAM2
	BANK_2
	movwf 0x121
	BANK_0
	return
;**************************************************************************
VYHOVUJE_ZAZNAM
	; pokud zaznam ZAZ_A v bufferu2 vyhovuje hledani, nastavi bit TEMP1,0
	clrf TEMP1
	BANK_2
	movfw 0x110
	BANK_0
	;		1.     byte -> 	= 00h -> zaznam je prazdny; 
	;						= 01h -> zaznam je adresar; 
	;						= 02h -> zaznam je soubor; 
	;						= 06h -> zaznam je soubor s priponou MP3
	movwf TEMP2
	andlw h'FF'
	btfsc STATUS,Z
	return				; pokud je zaznam prazdny, tak jej proste neberem
;HL_PARAMETRY	equ 0x059
;		0. bit = 0 > pokud hledáme soubory, tak pouze MP3
;				 1 > pokud hledáme soubory, vrací všechny soubory
;		1. bit = 0 > hledáme klasicky (nejdříve adresáře, poté soubory
;				 1 > hledáme pouze adresáře, nebo soubory
;		2. bit = 0 > je-li nastaven 1. bit, hledáme pouze adresáře
;				 1 > je-li nastaven 1. bit, hledáme pouze soubory
	btfss HL_PARAMETRY,1
	goto VYHOV_ZAZ_SOUBiADR
	btfss HL_PARAMETRY,2
	goto VYHOV_ZAZ_ONLY_ADR
	btfss HL_PARAMETRY,0
	goto VYHOV_ZAZ_ONLY_MP3
VYHOV_ZAZ_ALL_FILES
	btfss TEMP2,0
	bsf TEMP1,0
	return		
VYHOV_ZAZ_ONLY_MP3
	btfsc TEMP2,2
	bsf TEMP1,0
	return
VYHOV_ZAZ_ONLY_ADR
	btfsc TEMP2,0
	bsf TEMP1,0
	return
VYHOV_ZAZ_SOUBiADR
	btfss HL_PARAMETRY,0
	goto VYHOV_ZAZ_SOUBiADR_MP3
	bsf TEMP1,0
	return
VYHOV_ZAZ_SOUBiADR_MP3
	btfsc TEMP2,0
	bsf TEMP1,0
	btfsc TEMP2,2
	bsf TEMP1,0
	return
;**************************************************************************
COMPARE_BUFF2_L_H
; porovna nazvy souboru na zacatku bufferu2 a na konci bufferu2
; pokud v abecede je driv nazev v horni polovine buff2 da to TEMP1 0x01
; pokud v abecede je driv nazev v dolni polovine buff2 da to TEMP1 0x02
; pokud se nazvy shoduji da do TEMP1 0x00
	clrf TEMP1
	INDF_BANK_2			; stejne jako INDF_BANK_2
	BANK_0
	movlw 0x10
	movwf FSR
	movfw INDF
	andlw h'03'			; ted nerozlisuji mezi souborem mp3 a ostatnimi soubory
	movwf TEMP2

	movlw 0x30
	movwf FSR
	movfw INDF
	andlw h'03'			; ted nerozlisuji mezi souborem mp3 a ostatnimi soubory	
	subwf TEMP2,W		; prni byte z bufferu 2 - prvni byte z bufferu 1

	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT2		; prvni byt signalizujici typ byl shodny, pokracujeme bytem druhym (prvni byt nazvu)
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1
; tato procedura je temer shodna s tou nasledujici, proto jen zadame jinou hodnotu do FSR
; (misto pro buffer1 na horni pulku bufferu2) a nechame probehnout stejny kus kodu...
;**************************************************************************
COMPARE_BUFF1_BUFF2
; porovna nazvy souboru na zacatku bufferu1 s bufferem2
; pokud v abecede je driv nazev v bufferu1 da to TEMP1 0x01
; pokud v abecede je driv nazev v bufferu2 da to TEMP1 0x02
; pokud se nazvy shoduji da do TEMP1 0x00

; zaznamy v obou bufferech vypadaji nasledovne:
;		1.     byte -> 	= 00h -> zaznam je prazdny; 
;						= 01h -> zaznam je adresar; 
;						= 02h -> zaznam je soubor; 
;						= 06h -> zaznam je soubor s priponou MP3
;		2..9   byte -> 8 znaku dlouhe jmeno ("DOSovsky" tvar - napr. slouzka "dokumenty" = "DOKUME~1" )
;		10..12 byte -> u souboru tri znaky pripony (u adresaru vetsinou mezery - 20h 20h 20h)
;		13..16 byte -> 1. cluster souboru
	clrf TEMP1
	INDF_BANK_3			; stejne jako INDF_BANK_2
	BANK_0
	movlw 0x10
	movwf FSR
	movfw INDF
	andlw h'03'			; ted nerozlisuji mezi souborem mp3 a ostatnimi soubory
	movwf TEMP2

	movlw 0x90
	movwf FSR
	movfw INDF
	andlw h'03'			; ted nerozlisuji mezi souborem mp3 a ostatnimi soubory	
	subwf TEMP2,W		; prni byte z bufferu 2 - prvni byte z bufferu 1

	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT2	; prvni byt signalizujici typ byl shodny, pokracujeme bytem druhym (prvni byt nazvu)
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT2
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x111,W				; 2. byte z bufferu 2 - 2. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT3
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT3
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x112,W				; 3. byte z bufferu 2 - 3. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT4
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT4
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x113,W				; 4. byte z bufferu 2 - 4. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT5
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT5
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x114,W				; 5. byte z bufferu 2 - 5. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT6
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT6
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x115,W				; 6. byte z bufferu 2 - 6. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT7
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT7
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x116,W				; 7. byte z bufferu 2 - 7. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT8
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT8
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x117,W				; 8. byte z bufferu 2 - 8. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT9
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT9
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x118,W				; 9. byte z bufferu 2 - 9. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT10
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT10
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x119,W				; 10. byte z bufferu 2 - 10. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT11
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT11
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x11A,W				; 11. byte z bufferu 2 - 11. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_BYT12
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_BYT12
	BANK_2
	incf FSR,F
	movfw INDF
	subwf 0x11B,W				; 12. byte z bufferu 2 - 12. byte z bufferu 1
	btfsc STATUS,Z
	goto COMPARE_B1_B2_SHODNE
	btfss STATUS,C
	goto COMPARE_B1_B2_BUFF2	; hodnota v bufferu 1 byla vetsi, proto je v abecede dal...
	goto COMPARE_B1_B2_BUFF1

COMPARE_B1_B2_SHODNE
	BANK_0
	movlw h'00'
	movwf TEMP1	
	return
COMPARE_B1_B2_BUFF1
	BANK_0
	movlw h'01'
	movwf TEMP1	
	return
COMPARE_B1_B2_BUFF2
	BANK_0
	movlw h'02'
	movwf TEMP1
	return
;**************************************************************************
CLEAR_BUFFER1		; BUFFER1 je 64bytu dat v bance 3 na adrese 0x190 - 0x1CF
					; pouziva TEMP1
	movlw .64
	movwf TEMP1
	INDF_BANK_3		; neprime adresovani na banku 3
	movlw 0x90
	movwf FSR
	movlw .0

CLEAR_BEFFER1__CLEAR
	movwf INDF
	incf FSR,F
	decfsz TEMP1,F
	goto CLEAR_BEFFER1__CLEAR

	INDF_BANK_0		; neprime adresovani na banku 0
	return
;**************************************************************************
BUF2_TO_BUF1
	; hodi 18 dat z dolni pulky bufferu 2 do dolni pulky bufferu 1
	; 0x110 -> 0x190
	INDF_BANK_3
	BANK_2
	movlw 0x90
	movwf FSR

	movfw 0x110
	movwf INDF
	incf FSR,F
	movfw 0x111
	movwf INDF
	incf FSR,F
	movfw 0x112
	movwf INDF
	incf FSR,F
	movfw 0x113
	movwf INDF
	incf FSR,F
	movfw 0x114
	movwf INDF
	incf FSR,F
	movfw 0x115
	movwf INDF
	incf FSR,F
	movfw 0x116
	movwf INDF
	incf FSR,F
	movfw 0x117
	movwf INDF
	incf FSR,F
	movfw 0x118
	movwf INDF
	incf FSR,F
	movfw 0x119
	movwf INDF
	incf FSR,F
	movfw 0x11A
	movwf INDF
	incf FSR,F
	movfw 0x11B
	movwf INDF
	incf FSR,F
	movfw 0x11C
	movwf INDF
	incf FSR,F
	movfw 0x11D
	movwf INDF
	incf FSR,F
	movfw 0x11E
	movwf INDF
	incf FSR,F
	movfw 0x11F
	movwf INDF
	incf FSR,F

	movfw 0x120
	movwf INDF
	incf FSR,F
	movfw 0x121
	movwf INDF
	incf FSR,F
	BANK_0
	return
;**************************************************************************
BUF2_LOW_TO_HIGH
	; hodi 18 dat z dolni pulky bufferu 2 do horni pulky bufferu 2
	; 0x110 - 0x121 -> 0x130 - 0x141
	BANK_2
	movfw 0x110
	movwf 0x130
	movfw 0x111
	movwf 0x131
	movfw 0x112
	movwf 0x132
	movfw 0x113
	movwf 0x133
	movfw 0x114
	movwf 0x134
	movfw 0x115
	movwf 0x135
	movfw 0x116
	movwf 0x136
	movfw 0x117
	movwf 0x137
	movfw 0x118
	movwf 0x138
	movfw 0x119
	movwf 0x139
	movfw 0x11A
	movwf 0x13A
	movfw 0x11B
	movwf 0x13B
	movfw 0x11C
	movwf 0x13C
	movfw 0x11D
	movwf 0x13D
	movfw 0x11E
	movwf 0x13E
	movfw 0x11F
	movwf 0x13F

	movfw 0x120
	movwf 0x140
	movfw 0x121
	movwf 0x141
	BANK_0
	return
;**************************************************************************
LONG_NAME
; Tato procedura prevezme v HL_ADR_CL[1-4] cislo prvniho clusteru adresare a v ZAZNAM[1-2] cislo zaznamu 
; od kteremu se pokusi najit dlouhe jmeno. Toto dlouhe jmeno umisti do bufferu 2
; Dlouhe jmeno je ukonceno nulovym bytem. Pokud v bufferu 2 se nulovy byt nevyskytuje, je delka dlouheho
; jmena delsi ci rovna 65.
; V POZICE vraci 00h pri nenalezeni dlouheho jmena a 01h pri pravdepodobnem nalezeni dlouheho jmena.

; 65 znaku neni moc, neco se tam ale vejde "1-3. G & D - Purify (Gabriel & Dresden Remix) featuring Balligom"   (ingo.mp3)
; vyvojak:
;
; CLEAR_BUFFER2
;
; ZAZNAMU_vBUFFERU_DISKU := 0
; IF (ZAZNAM < 5):					// zaznamy cislujeme od 0, 
;	HL_PARAMETRY := ZAZNAM;
;	ZAZNAM := 0
; else:
; 	ZAZNAM := ZAZNAM - 5 			// protoze chceme prohledat 5 predchozich
;	HL_PARAMETRY := 5
; endif
;
; while (HL_PARAMETRY <> 0)
;	if (ZAZNAMU_vBUFFERU_DISKU = 0):
;		SKOC_NA_ZAZNAM
;	endif;

;////////////////////
; if (BUFF1[0] != 0) and (BUFF1[0] != E5h) and (BUFF1[11] = 0Fh):
;		// v bufferu1 mame zaznam obsahujici dlouhe jmeno 
;		FSR := (HL_PARAMETRY * 13) + 3
;		INDF := BUFF1[1]
;		inc FSR
;		INDF := BUFF1[3]
;		inc FSR
;		...
; else:
; 		CLEAR_BUFFER2	// zaznam neobsahuje dlouhe jmeno, proto jsou vsechny predchozi zaznamy k nicemu
; endif;
;////////////////////

;	HL_PARAMETRY --
;	ZAZNAM ++
;	ZAZNAMU_vBUFFERU_DISKU --
; endwhile
	PROG_PAGE_0
	call CLEAR_BUFFER2				; 		CLEAR_BUFFER2	// zaznam neobsahuje dlouhe jmeno, proto jsou vsechny predchozi zaznamy k nicemu
	PROG_PAGE_1

	clrf ZAZNAMU_vBUFFERU_DISKU		; ZAZNAMU_vBUFFERU_DISKU := 0
	clrf POZICE
	movfw ZAZNAM1
	sublw .4
	btfss STATUS,C
	goto LONG_NAME_ELSE1
	movfw ZAZNAM2
	andlw h'FF'
	btfss STATUS,Z					; IF (ZAZNAM < 5):					// zaznamy cislujeme od 0, 
	goto LONG_NAME_ELSE1

	movfw ZAZNAM1
	movwf HL_PARAMETRY				;	HL_PARAMETRY := ZAZNAM;
	clrf ZAZNAM1					;	ZAZNAM := 0
	goto LONG_NAME_ENDIF1
LONG_NAME_ELSE1						; else:
	movlw .5
	subwf ZAZNAM1,F					; 	ZAZNAM := ZAZNAM - 5 			// protoze chceme prohledat 5 predchozich
	btfss STATUS,C
	decf ZAZNAM2,F
	movlw .5
	movwf HL_PARAMETRY				;	HL_PARAMETRY := 5
LONG_NAME_ENDIF1					; endif

LONG_NAME_WHILE						; while (HL_PARAMETRY <> 0)
	movfw HL_PARAMETRY
	andlw h'FF'
	btfsc STATUS,Z
	goto LONG_NAME_ENDWHILE
	
	movfw HL_ADR_CL1
	movwf CLUSTER1
	movfw HL_ADR_CL2
	movwf CLUSTER2
	movfw HL_ADR_CL3
	movwf CLUSTER3
	movfw HL_ADR_CL4
	movwf CLUSTER4

	movfw ZAZNAMU_vBUFFERU_DISKU
	andlw h'FF'
	btfsc STATUS,Z					;	if (ZAZNAMU_vBUFFERU_DISKU = 0):
	call SKOC_NA_ZAZNAM 			;		SKOC_NA_ZAZNAM	endif;
	
	btfsc POZICE,0		; SKOC_NA_ZAZNAM - pokud ZAZNAM[1-2] ukazuji mimo adresar, vrati v POZICE FFh (jinak 00h)
	goto LONG_NAME_MIMO_ROZSAH

;////////////////////////////////
;	//tady probehne cteni zaznamu, zjisteni, zda jde o dlouhe jmeno a jeho cteni;	
	movlw .16
	movwf TEMP1
	PROG_PAGE_0
	call ZAPIS_DO_BUFFERU_1			; kazdy zaznam v adresari ma 32 bytu
	PROG_PAGE_1

	BANK_3
	movfw 0x190
	andlw h'FF'
	btfsc STATUS,Z
	goto LONG_NAME_ELSE2
	sublw h'E5'
	btfsc STATUS,Z
	goto LONG_NAME_ELSE2
	movfw 0x19B
	sublw h'0F'
	btfss STATUS,Z
	goto LONG_NAME_ELSE2
LONG_NAME_IF2						; if (BUFF1[0] != 0) and (BUFF1[0] != E5h) and (BUFF1[11] = 0Fh):
	BANK_0							;		// v bufferu1 mame zaznam obsahujici dlouhe jmeno 
	movfw HL_PARAMETRY
	movwf TEMP1
	movlw .0
LONG_NAME_NASOBENI
	addlw .13
	decfsz TEMP1,f
	goto LONG_NAME_NASOBENI
	addlw .3	
	movwf FSR						;		FSR := (HL_PARAMETRY * 13) + 3

	BANK_3
	INDF_BANK_2
	movfw 0x190+.1
	movwf INDF
	incf FSR,F
	movfw 0x190+.3
	movwf INDF
	incf FSR,F
	movfw 0x190+.5
	movwf INDF
	incf FSR,F
	movfw 0x190+.7
	movwf INDF
	incf FSR,F
	movfw 0x190+.9
	movwf INDF
	incf FSR,F
	movfw 0x190+.14
	movwf INDF
	incf FSR,F
	movfw 0x190+.16
	movwf INDF
	incf FSR,F
	movfw 0x190+.18
	movwf INDF
	incf FSR,F
	movfw 0x190+.20
	movwf INDF
	incf FSR,F
	movfw 0x190+.22
	movwf INDF
	incf FSR,F
	movfw 0x190+.24
	movwf INDF
	incf FSR,F
	movfw 0x190+.28
	movwf INDF
	incf FSR,F
	movfw 0x190+.30
	movwf INDF
	incf FSR,F
	INDF_BANK_0
	BANK_0
	goto LONG_NAME_ENDIF2
LONG_NAME_ELSE2						; else:
	BANK_0
	PROG_PAGE_0
	call CLEAR_BUFFER2				; 		CLEAR_BUFFER2	// zaznam neobsahuje dlouhe jmeno, proto jsou vsechny predchozi zaznamy k nicemu
	PROG_PAGE_1
LONG_NAME_ENDIF2					; endif;
;////////////////////////////////

	incf ZAZNAM1,F
	btfsc STATUS,Z
	incf ZAZNAM2,F					;	ZAZNAM ++
	decf HL_PARAMETRY,F				;	HL_PARAMETRY --
	decf ZAZNAMU_vBUFFERU_DISKU,F	;	ZAZNAMU_vBUFFERU_DISKU --
	goto LONG_NAME_WHILE
LONG_NAME_ENDWHILE					; endwhile
	movlw .1
	movwf POZICE
	return
LONG_NAME_MIMO_ROZSAH
	movlw .0
	movwf POZICE
	return
;**************************************************************************
HLEDEJ_V_NADRAZENEM
; v CLUSTER prijme prvni cluster adresare

; v nadrazenem adresari se pokusi najit zaznam odkazujici na tento adresar
; na zacatek BUFFERU 1 da cislo clusteru se zacatkem nadrazeneho adresare, 
; do HL_ADR_CL da prvni cluster predaneho adresare a v ZAZNAM vratime cislo 
; zaznamu odkazujici na HL_ADR_CL
	movfw CLUSTER1
	movwf HL_ADR_CL1
	movfw CLUSTER2
	movwf HL_ADR_CL2
	movfw CLUSTER3
	movwf HL_ADR_CL3
	movfw CLUSTER4
	movwf HL_ADR_CL4

	clrf POZICE
	PROG_PAGE_0
	call CLUSTER_TO_LBA
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR	; precteme prvni sektor z prvniho clusteru adresare	
	movlw .26			; prvnich 26 slov je ted nepotrebnych
	movwf TEMP1
	call PRESKOC

	call READ_DATA
	movfw DATA_L
	movwf CLUSTER3
	movfw DATA_H
	movwf CLUSTER4

	movlw .2			; dalsi 4 byty jsou ted nepotrebne
	movwf TEMP1
	call PRESKOC

	call READ_DATA
	movfw DATA_L
	movwf CLUSTER1
	movfw DATA_H
	movwf CLUSTER2
	PROG_PAGE_1

	; v CLUSTER ted mame cislo prvniho clusteru nadrazeneho adresare. Umistime jej na zacatek BUFFERU 1
	INDF_BANK_3
	movlw h'90'
	movwf FSR
	movfw CLUSTER1
	movwf INDF
	incf FSR,f
	movfw CLUSTER2
	movwf INDF
	incf FSR,f
	movfw CLUSTER3
	movwf INDF
	incf FSR,f
	movfw CLUSTER4
	movwf INDF
	incf FSR,f
	
	clrf ZAZNAM1
	clrf ZAZNAM2
HLEDEJVNAD_CLUSTER
	clrf POZICE
HLEDEJVNAD_SECTOR
	PROG_PAGE_0
	call CLUSTER_TO_LBA
	movlw .1
	movwf SECTOR_C
	call READ_SECTOR
	PROG_PAGE_1

	movlw .16
	movwf TEMP2
HLEDEJVNAD_ZAZNAM
	clrf TEMP3					; pokud bude zaznam vyhovovat, bude TEMP3 0
	PROG_PAGE_0
	call READ_DATA
	movfw DATA_L
	andlw h'FF'
	btfsc STATUS,Z				; pokud 1. znak jmena souboru = 00h, je zaznam prazdny
	bsf TEMP3,0

	movfw DATA_L
	sublw h'E5'
	btfsc STATUS,Z				; pokud 1. znak jmena souboru = E5h, je zaznam prazdny
	bsf TEMP3,0

	movlw .4
	movwf TEMP1
	call PRESKOC				; jmeno (8) a priponu (3) ted nepotrebujeme

	call READ_DATA
	movfw DATA_H
	andlw h'10'
	sublw h'10'
	btfss STATUS,Z				; if (atributy and 10h) = 10h -> adresar
	bsf TEMP3,0

	movlw .4
	movwf TEMP1
	call PRESKOC				; dalsich 8 bytu je nam k nicemu

	call READ_DATA
	movfw DATA_L
	subwf HL_ADR_CL3,w
	btfss STATUS,Z
	bsf TEMP3,0
	movfw DATA_H
	subwf HL_ADR_CL4,w
	btfss STATUS,Z
	bsf TEMP3,0

	movlw .2					; dalsi 4 byty jsou ted nepotrebne
	movwf TEMP1
	call PRESKOC

	call READ_DATA
	movfw DATA_L
	subwf HL_ADR_CL1,w
	btfss STATUS,Z
	bsf TEMP3,0
	movfw DATA_H
	subwf HL_ADR_CL2,w
	btfss STATUS,Z
	bsf TEMP3,0

	movlw .2					; musime precist i posledni 4 byty ze zaznamu
	movwf TEMP1
	call PRESKOC
	PROG_PAGE_1
	
	movfw TEMP3
	andlw h'FF'
	btfsc STATUS,Z
	goto HLEDEJVNAD_KONEC		; pokud se cluster shodoval, koncime

	incf ZAZNAM1,f
	btfsc STATUS,Z
	incf ZAZNAM2,f				; ZAZNAM ++

	decfsz TEMP2,f
	goto HLEDEJVNAD_ZAZNAM

	incf POZICE,f
	movfw POZICE
	subwf CLUSTER_SIZE,w
	btfss STATUS,Z
	goto HLEDEJVNAD_SECTOR

	PROG_PAGE_0
	call NEXT_CLUSTER
	PROG_PAGE_1
	movfw POZICE
	andlw h'FF'
	btfsc STATUS,Z
	goto HLEDEJVNAD_CLUSTER

HLEDEJVNAD_KONEC
	return
;**************************************************************************
