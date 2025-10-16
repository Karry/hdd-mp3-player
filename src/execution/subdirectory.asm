; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; Tady ta èást kódu má jeden jediný smysl. A to aby nalezla další adresáø, který se má pøehrávat pokud v aktuálním 
; adresáøi již není žádná MP3, která nebyla pøehrána. 
; 
; máme-li následující adresáøovou strukruru:
; ROOT
;  | skladba_01.mp3
;  | skladba_02.mp3
;  +- DIRECTORY_1
;  |  | skladba_03.mp3
;  |  | skladba_04.mp3
;  |  +- DIRECTORY_1_1
;  |     | skladba_05.mp3
;  |
;  +- DIRECTORY_2
;     | skladba_06.mp3
;
; Tak sou mp3 pøehrávany v poøadí, jak je zobrazeno. Nejdøíve všechny mp3 v ROOT (skladba_01,02) poté DIRECTORY_1...
; XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

; function  HLEDEJ_ADRESAR(){
;  if (PREH_ADR_CL == ROOT){
;	HL_PARAMETRY = [hledej 1. adresar]
;  }else{
;	HL_PARAMETRY = [hledej nasledujici adresar] //po ".."
;  }
;  HL_ADR_CL=PREH_ADR_CL
;  HL_ZAZNAM = 1
;  hledej();
;  if (nalezeno){
;	goto HLEDEJ_ADR_NALEZEN
;  }else{
;	HLEDEJ_ADR_OADR_VIS
;	if (PREH_ADR_CL == ROOT){
;		PREH_STAV0=[stop]
;		exit
;	}else{
;		HLEDEJ_ADR_OADR_VIS_NOROOT
;		najdi odkaz na PREH_ADR_CL v nadrazenem adresari		
;		hledej dalsi adresar v nadrazenem adresari po PREH_ADR_CL
;		PREH_ADR_CL = nadrazeny adresar
;		if (nalezeno){
;			goto HLEDEJ_ADR_NALEZEN
;		}else{
;			goto HLEDEJ_ADR_OADR_VIS
;		}
;	}
;  }
;
;  HLEDEJ_ADR_NALEZEN
;  hledej 1. mp3 v nalezenem adresari
;  pokud byla mp3 nalezena, nastav ji jako prehravanou
; }

HLEDEJ_ADRESAR

	movfw PREH_ADR_CL1
	iorwf PREH_ADR_CL2,w
	iorwf PREH_ADR_CL3,w
	iorwf PREH_ADR_CL4,w
	movlw b'00001010'			; PREH_ADR je ROOT, tak hledame 1. adresar
	btfss STATUS,Z
	movlw b'00000010'			; PREH_ADR neni ROOT, tak hledame nasledujici adresar po adresari 1 ('..')
	movwf HL_PARAMETRY
	movlw .1
	movwf ZAZNAM1
	clrf ZAZNAM2
	movfw PREH_ADR_CL1
	movwf HL_ADR_CL1
	movfw PREH_ADR_CL2
	movwf HL_ADR_CL2
	movfw PREH_ADR_CL3
	movwf HL_ADR_CL3
	movfw PREH_ADR_CL4
	movwf HL_ADR_CL4
	PROG_PAGE_1
	call HLEDEJ
	PROG_PAGE_2
	BANK_2
	movfw 0x130
;	1. byte:	= 00h -> zadny vyhovujici zaznam nebyl nalezen
;				= 01h -> zaznam je adresar
;				= 02h -> zaznam je soubor; 
;				= 06h -> zaznam je soubor s priponou MP3
	BANK_0
	andlw h'FF'
	btfss STATUS,Z
	goto HLEDEJ_ADR_NALEZEN
;HLEDEJ_ADR_NENALEZEN
HLEDEJ_ADR_OADR_VIS
;	HLEDEJ_ADR_OADR_VIS
;	if (PREH_ADR_CL == ROOT){
;		PREH_STAV0=[stop]
;		exit
;	}else{
;		HLEDEJ_ADR_OADR_VIS_NOROOT		
;		najdi odkaz na PREH_ADR_CL v nadrazenem adresari		
;		hledej dalsi adresar v nadrazenem adresari po PREH_ADR_CL
;		PREH_ADR_CL = nadrazeny adresar
;		if (nalezeno){
;			goto HLEDEJ_ADR_NALEZEN
;		}else{
;			goto HLEDEJ_ADR_OADR_VIS
;		}
;	}
	movfw PREH_ADR_CL1
	iorwf PREH_ADR_CL2,w
	iorwf PREH_ADR_CL3,w
	iorwf PREH_ADR_CL4,w
	btfss STATUS,Z	
	goto HLEDEJ_ADR_OADR_VIS_NOROOT

	bcf PREH_STAV0,0	; 0. bit = 	0 => stop nebo pausa (nic nehraje)

	goto HLEDEJ_ADRESAR_KONEC

HLEDEJ_ADR_OADR_VIS_NOROOT	
	movfw PREH_ADR_CL1
	movwf CLUSTER1
	movfw PREH_ADR_CL2
	movwf CLUSTER2
	movfw PREH_ADR_CL3
	movwf CLUSTER3
	movfw PREH_ADR_CL4
	movwf CLUSTER4
	
	PROG_PAGE_1
	call HLEDEJ_V_NADRAZENEM	; najdi odkaz na PREH_ADR_CL v nadrazenem adresari
	PROG_PAGE_2

	INDF_BANK_3
	movlw h'90'
	movwf FSR
	movfw INDF
	movwf PREH_ADR_CL1
	movwf HL_ADR_CL1
	incf FSR,f
	movfw INDF
	movwf PREH_ADR_CL2
	movwf HL_ADR_CL2
	incf FSR,f
	movfw INDF
	movwf PREH_ADR_CL3
	movwf HL_ADR_CL3
	incf FSR,f
	movfw INDF
	movwf PREH_ADR_CL4			; PREH_ADR_CL = nadrazeny adresar
	movwf HL_ADR_CL4

	movlw b'00000010'			; hledame nasledujici adresar
	PROG_PAGE_1
	call HLEDEJ
	PROG_PAGE_2					; hledej dalsi adresar v nadrazenem adresari po PREH_ADR_CL
;		if (nalezeno){
;			goto HLEDEJ_ADR_NALEZEN
;		}else{
;			goto HLEDEJ_ADR_OADR_VIS
;		}
	BANK_2
	movfw 0x30
	BANK_0
	sublw h'01'			; = 01h -> zaznam je adresar
	btfss STATUS,Z
	goto HLEDEJ_ADR_OADR_VIS
	goto HLEDEJ_ADR_NALEZEN



HLEDEJ_ADR_NALEZEN
	INDF_BANK_2
	movlw 0x3C
	movwf FSR

	movfw INDF
	movwf PREH_ADR_CL1
	movwf HL_ADR_CL1
	incf FSR,f
	movfw INDF
	movwf PREH_ADR_CL2
	movwf HL_ADR_CL2
	incf FSR,f
	movfw INDF
	movwf PREH_ADR_CL3
	movwf HL_ADR_CL3
	incf FSR,f
	movfw INDF
	movwf PREH_ADR_CL4
	movwf HL_ADR_CL4

	movlw b'00101110'			; hledej 1. mp3
	movwf HL_PARAMETRY

	bsf PREH_STAV0,2			; byl automaticky zmenen prehravany soubor/adresar

	PROG_PAGE_1
	call HLEDEJ
	PROG_PAGE_2

	BANK_2
	movfw 0x30
	BANK_0
	sublw h'06'			; = 06h -> zaznam je soubor s priponou MP3
	btfss STATUS,Z
	goto HLEDEJ_ADRESAR_KONEC

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; byl nalezen soubor v podadresari, nastavime jej jako prehravany...
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
	bsf PREH_STAV0,2			; byl automaticky zmenen prehravany soubor/adresar

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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HLEDEJ_ADRESAR_KONEC
	PROG_PAGE_0
	goto HLEDEJ_ADRESAR_RETURN
