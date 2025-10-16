TMP0	equ 0X020
TMP1	equ 0X021
TMP2	equ 0X023
TMP3	equ 0X024
TMP4	equ 0X025
TMP5	equ 0X026
;XXXXXXXXXXXXXXXX;DEFINICE BITÙ K DISPLEJI
#DEFINE	LCD_RS		PORTB,2
#DEFINE	LCD_RW		PORTB,1
#DEFINE	LCD_ENABLE	PORTB,0
#DEFINE	LCD_PODSVICENI		PORTC,5

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; registry pro potreby preruseni + prace s prikazy (jsou totiz dostupne odkudkoliv)
TEMP_WORKING	equ 0x070
TEMP_STATUS		equ 0x071
TEMP_FSR		equ 0x072
PRIJATE_DATO	equ 0x074		; pomocna promenna v preruseni
TEMP_PCLATH		equ 0x076
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
