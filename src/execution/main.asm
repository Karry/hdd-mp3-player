;   HLAVNI SOUBOR 
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;  MP3 PREPRCAVAC
; ================
; 
; Program mp3 prehravace pouzivajici jako zdroj dat ATA disk.
; 
; Umi identifikovat disk, precist libovolny sektor, v MBR  najit oddily se systemem souboru FAT32, 
; nacist spousteci zaznam FAT32, praci s FAT32, komunikaci s vs1001 a prehravani mp3 pres vs1001.
;
;
; dodelat:
;	- podporu ID3v1
;	- pak uz jen vychytavky...	(napr. do vs1001 naprogramovat ekvalizer a nejak ho ovladat...)
;	- najit a zabit chyby
;
; chyby o kterych vim:
;
; vyreseen chyby:
;	- Pri cteni SCI (registru VS1001k) dochazi k praskani na vystupu a obcas k resetovani dekoderu
;		...vyreseno postavenim konecne faze hardwaru
;	- pri cteni nekterych clusteru jsou precteny clustery jine
;		...tato chyba byla zpusobena chybnym scitanim (MPLAB SIM se chova jinak nez PIC - decf u picu nemeni priznak Carry!!!)
;	- Obcas se nechce vs1001k resetovat. Snad tomu pomuze mala hardwarova uprava.
;		...opravdu tomu znacne pomohlo pridani kondiku a odporu na reset jako u PICu (v datasheetu je tato uprava zminovana jen u vs1002.(?))
;
; srpen 2005 - brezen 2006 Karry - lukas.karas@centrum.cz
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


;**********************************************************
;   VERZE 1.1
;**********************************************************
; !!!!!!!! VSECHNY CASOVE SMYCKY JSOU POCITANY NA Fosc=20MHz !!!!!
; !!!!!!!! NASTAVENI USARTu TAKY !!!!!!!
	LIST		p=PIC16F877A,C=132,n=60
	__CONFIG	_WDT_OFF & _HS_OSC & _PWRTE_OFF & _BODEN_OFF & _LVP_OFF 
			; LVP_OFF = RB3 jako digitalni I/O
	errorlevel -302		; vypnuti Message [302]: Register in operand not in bank 0.
	errorlevel -306		; vypnuti Message[306] : Crossing page boundary -- ensure page bits are set.
						; ! zjednoduseni vypisu, ale riziko prehlednuti chyby
;**********************************************************

	include "P16F877A.inc" 	; definice blbosti kolem procesoru
	include "mp3.inc" 		; definice promennych, konstant a portu

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; PROGRAM
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;**********************************************************
 org 0x0000					; PAGE 0
  	goto START
 org 0x0004					; PAGE 0
	movwf TEMP_WORKING
	movfw STATUS
	movwf TEMP_STATUS
	movfw FSR
	movwf TEMP_FSR
	movfw PCLATH
	movwf TEMP_PCLATH
	clrf PCLATH
	BANK_0
	INDF_BANK_0
	goto INTERRUPT
;**********************************************************
 org 0x0010					; PAGE 0
	include "mp3.asm" 		; hlavni programova smycka
	include "ata.asm" 		; podprogramy na ovladani ATA disku
	include "fat32.asm" 	; podprogramy na nacteni a praci s FAT32
	include "aritmetic.asm"	; podprogramy vykonavajici zakladni aritmetologicke operace
 
 org 0x0800					; PAGE 1
;#IF VS1001==1
	include "vs1001.asm"	; podprogramy na ovladani mp3 decoderu
;#ENDIF
	include "commands.asm"	; podprogramy na obsluhu prikazu (od ridiciho procesoru)
	include "filesystem.asm"; podprogramy pro praci s adresari a setrideni obsahu adresaru
 org 0x1000					; PAGE 2
	nop						; (aby nas prekladac varoval, az dosahneme teto stranky)
 org 0x1800					; PAGE 3
	nop						; (aby nas prekladac varoval, az dosahneme teto stranky)
;**********************************************************
	END
