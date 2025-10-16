; roznmisteni pameti:
;	0. banka -> funkcni promenne
;	1. banka -> nic
;	2. banka -> buffer2 (na dlouha jmena souboru pri prehravani)
;	3. banka -> buffer1 (na dlouha jmena adresaru pri prehravani,
;						jmena oddilu a jine veci...)
;XXXXXXXXXXXXXXXX DEFINICE VLASTNICH PROMENNYCH
; pomocne promenne (pro casove smycky a jine kokotiny...)
TMP0	equ 0X020
TMP1	equ 0X021
TMP2	equ 0X023
TMP3	equ 0X024
TMP4	equ 0X025
TMP5	equ 0X026
; stavove promenne (zda se neco prehrava, zda je nactena FATka a podobne...)
aktual_hlas equ 0x027	; aktualni hlasitost prehravace
STAV		equ 0x028
		; 7. bit = 1 => je nactena FATka
PREH_STAV0	equ 0x029
PREH_STAV1	equ 0x02A

PREH_ADR_CL1	equ 0X02B
PREH_ADR_CL2	equ 0X02C
PREH_ADR_CL3	equ 0X02D
PREH_ADR_CL4	equ 0X02E
PREH_SOUB_1		equ 0X02F
PREH_SOUB_2		equ 0X030
PREH_ZNAK		equ 0X031
VTERINY1		equ 0X032
VTERINY2		equ 0X033
MINUTY1			equ 0X034
MINUTY2			equ 0X035

COUNTER			equ 0X036
PRETECENI		equ 0X037
VYSLEDEK1		equ 0X038
VYSLEDEK2		equ 0X039
POMOCNA1		equ 0X040
POMOCNA2		equ 0X041		; REGISTRY PRO ARITMETICKE OPERACE

ZAC_ZOB_SOUB	equ 0x042
ZAC_ZOB_ADR		equ 0x043		; od kolikateho znaku se zobrazuji rolovane nazvy

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; registry pro potreby preruseni + prace s prikazy (jsou totiz dostupne odkudkoliv)
TEMP_WORKING	equ 0x070
TEMP_STATUS		equ 0x071
TEMP_FSR		equ 0x072
PRIJATE_DATO	equ 0x074		; pomocna promenna v preruseni
TEMP_PCLATH		equ 0x076
;XXXXXXXXXXXXXXXX;DEFINICE BITÙ K DISPLEJI
#DEFINE	LCD_RS		PORTB,2
#DEFINE	LCD_RW		PORTB,1
#DEFINE	LCD_ENABLE	PORTB,0
#DEFINE	LCD_PODSVICENI		PORTC,5
#DEFINE	TL_PODSVICENI		PORTC,4
#DEFINE	TL_PLAY		PORTA,1
#DEFINE	TL_STOP		PORTA,2
#DEFINE	TL_DOPREDU		PORTA,3
#DEFINE	TL_DOZADU		PORTA,0
#DEFINE	TL_VOLUME_UP	PORTA,4
#DEFINE	TL_VOLUME_DOWN	PORTA,5
#DEFINE	TL_MENU		PORTE,1
#DEFINE	TL_MENU_UP		PORTE,0
#DEFINE	TL_MENU_DOWN	PORTE,2
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; MAKRA
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
BANK_0	macro					; prepnuti do banky 0 v pameti dat
		bcf     STATUS,RP1		; BANK0  RP1:RP0 = 00
		bcf     STATUS,RP0    
		endm
BANK_1	macro					; prepnuti do banky 1 v pameti dat
		bcf     STATUS,RP1		; BANK1  RP1:RP0 = 01
		bsf     STATUS,RP0    
		endm
BANK_2	macro					; prepnuti do banky 2 v pameti dat
		bsf     STATUS,RP1		; BANK2  RP1:RP0 = 10
		bcf     STATUS,RP0    
		endm
BANK_3	macro					; prepnuti do banky 3 v pameti dat
		bsf     STATUS,RP1		; BANK3  RP1:RP0 = 11
		bsf     STATUS,RP0    
		endm
; INDF_BANK_x slouzi k prepinani bank pro neprime adresovani pomoci INDF a FSR
INDF_BANK_0	macro               
			bcf STATUS,IRP    
			endm
INDF_BANK_1	macro               
			bcf STATUS,IRP    
			endm
INDF_BANK_2	macro             
			bsf STATUS,IRP    
			endm
INDF_BANK_3	macro             
			bsf STATUS,IRP    
			endm
;**********************************************************
PROG_PAGE_0	macro             
			bcf PCLATH,3
			bcf PCLATH,4
			endm
PROG_PAGE_1	macro             
			bsf PCLATH,3
			bcf PCLATH,4
			endm
PROG_PAGE_2	macro             
			bcf PCLATH,3
			bsf PCLATH,4
			endm
PROG_PAGE_3	macro             
			bsf PCLATH,3
			bsf PCLATH,4
			endm
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
