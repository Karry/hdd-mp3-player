;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; DEFINICE PORTU
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;**********************************************************
; ZAPOJENI PORTU:
;       portA - MP3 dekoder vs1001g (alespon doufam ze sezenem tenhle typ, je totiz naprosto spickovej!!!)
;				5      4     3   2     1         0
;				BSYNC  DREQ  CS  SCLK  SI/SDATA  SO
;		portB - ATA datova sbernice (dolnich 8 bitu)
;               7   .. 0
;               DD7 .. DD0
;		portD - ATA datova sbernice (hornich 8 bitu)
;               15   .. 8
;               DD15 .. DD8 
;		portC - adresove signaly ATA, ERROR_LED, a USART
; 				7          6         5     4     3          2    1    0
; 				USART out  USART in  CS1-  CS0-  ERROR_LED  DA2  DA1  DA0  
;				(signaly se znaminkem minus jsou aktivni v logicke 0 !!!)
;		portE - ridici signaly ATA
;				2       1      0
;				DIOR-	DIOW-  RESET-
;				(signaly se znaminkem minus jsou aktivni v logicke 0 !!!)
;**********************************************************
MP3_PORT		equ PORTA
MP3_PORT_TRIS	equ TRISA
; BITY MP3_PORT
#define MP3_SO		MP3_PORT,0	; serial output - tady dostavame z dekoderu data
#define MP3_SI		MP3_PORT,1	; serial input  - pokud MP3_CS=1, tak posilame mp3 data, pokud =0, tak posilame prikaz
#define MP3_SCLK	MP3_PORT,2	; clock - nabezna hrana urcuje platnost dat pri seriovem prenosu
#define MP3_CS		MP3_PORT,3	; cable select  - pokud MP3_CS=1, tak po SI posilame mp3 data, pokud =0, tak posilame prikaz
#define MP3_DREQ	MP3_PORT,4	; data request  - pokud =1, tak dekoder pozaduje dalsi mp3 data
#define MP3_BSYNC	MP3_PORT,5	; pro synchronizaci - ma byt nastaven pri prvnim prenasenem bitu kazdeho bytu
;**********************************************************
; pokud jsem dobre pochopil dataSheat dekoderu vs1001, tak staci do nej jen cpat data, a kdyz skonci mp3, tak odeslat 1024 nulovych bytu,
; softwarove resetovat a posilat dalsi mp3...
;
; popis registru obvodu vs1001 najdete na strane 22 dataSheatu 
; v jeho registrech jsou k dispozici data z hlavicky mp3, zdali mp3 ma spravny format, 
; ovladani hlasitosti a dalsi spousty uzitecnych informaci
;**********************************************************
; PORTY DISKU
ATA_ADDRESS 		equ PORTC
ATA_CONTROL 		equ PORTE
DATA_PORT_LOW 		equ PORTB
DATA_PORT_HIGH 		equ PORTD


ATA_ADDRESS_TRIS 	equ TRISC
ATA_CONTROL_TRIS	equ TRISE
DATA_PORT_LOW_TRIS 	equ TRISB
DATA_PORT_HIGH_TRIS	equ TRISD

; bity ATA_ADDRESS portu
#define ERROR_LED	ATA_ADDRESS,3
; bity ATA_CONTROL portu
#define ATA_RESET_N	ATA_CONTROL,0
#define ATA_DIOW_N	ATA_CONTROL,1
#define ATA_DIOR_N	ATA_CONTROL,2

;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; DEFINICE KONSTANT
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; ADRESY ATA REGISTRU:
;                                                                       / CHS adressing
;   +-----------+--------------+-------------------+-----------------+
;   | CS0- CS1- |  DA2 DA1 DA0 | READ              | WRITE           |   
;   +-----------+--------------+-------------------+-----------------+
;   | 1    1    |  x   x   x   | data bush h.imped (validace prikazu)|
;   +-----------+--------------+-------------------+-----------------+
;   | 1    0    |  1   1   0   | alternate status  | device control  |
;   +-----------+--------------+-------------------+-----------------+
;   | 0    1    |  0   0   0   | data              | data            |
;   | 0    1    |  0   0   1   | error             | features        |
;   | 0    1    |  0   1   0   |             sector count            |
;   | 0    1    |  0   1   1   |             LBA bits 0-7            |  sector number
;   | 0    1    |  1   0   0   |             LBA bits 8-15           |  cilinder LOW 
;   | 0    1    |  1   0   1   |             LBA bits 16-23          |  cilinder HIGH
;   | 0    1    |  1   1   0   |         device / LBA bits 24-27*    |  device, head
;   | 0    1    |  1   1   1   | status            | command         |
;   +-----------+--------------+-------------------+-----------------+
;   | 0    0    |  0   0   0   | invalid addres    | invalid addres  |
;   +-----------+--------------+-------------------+-----------------+
;
;   * 7 6 5 4   3     2     1     0 
;     1 L 1 DEV LBA27 LBA26 LBA25 LBA24
;  L=1 -> aresa je LBA , L=0 -> adresa je CHS
;  DEV=0 -> master , DEV=1 -> SLAVE
;
;  pokud disk podporuje LBA 48, tak je zadavani adresy trochu odlisne od LBA27
;**********************************************************
; toto jsou definice adres ATA registru. Staci udat jejich adresu na ATA_ADDRESS port a dat prikaz ke cteni ci zapisu (DIOR- / DIOW-)
D_STATUS_A    equ b'00010110'
D_DEVICE_C    equ D_STATUS_A
D_DATA_R      equ b'00100000'
D_FEATURES    equ b'00100001'
D_ERROR       equ D_FEATURES
D_SECTOR_C    equ b'00100010'
D_LBA1        equ b'00100011'	; LBA low
D_LBA2        equ b'00100100'	; LBA middle
D_LBA3        equ b'00100101'	; LBA high
D_DEVICE      equ b'00100110'
D_STATUS      equ b'00100111'
D_COMMAND     equ D_STATUS
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; DEFINICE PROMENNYCH
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; MAPA PAMETI: (368 bytu)
; 	BANK 0: 	0x000 - 0x01F = specialni registry,
;				0x020 - 0x07F = misto (96bytu) pro nase registry:
;				0x020 - 0x034 -> 21bytu pro registry a parametry HDD
;				0x035 - 0x03a -> 6bytu pro parametry podprogramu (musime zajistit, abychom nepouzivali registry, ktere pouzivaji i podprogramy!!!)
;				0x03B - 0x07F -> 69bytu rezervovano pro parametry oddilu, pozici v mp3 a dalsi blbosti
;
; 	BANK 1: 	0x080 - 0x09F = specialni registry,
;				0x0A0 - 0x0EF = volne misto (80bytu)
;				0x0A0 - 0x0AC -> parametry a navratove hodnoty z aritmeto/logickych podprogramu
;				0x0AD - 0x0EF -> 67bytu nepouzito
;
; 	BANK 2: 	0x100 - 0x10F = specialni registry,
;				0x110 - 0x16F = misto (96bytu) pro nase registry:
;				0x110 - 0x14F -> 64bytu BUFFER_2 pro dlouhe nazvy souboru, tabulku oddilu, a treba pro cast fatky
;				0x150 - 0x16F -> 32bytu nepouzito
;
; 	BANK 3: 	0x180 - 0x18F = specialni registry,
;				0x190 - 0x1EF = misto (96bytu) pro nase registry:
; 				0x190 - 0x1CF -> 64bytu BUFFER_1 pro ruzna data pri cteni...
; 				0x1D0 - 0x1DF -> 16bytu bufferu pro data prikazu (smi zapisovat z preruseni)
;				0x1E0		  -> vlajka prikazu if (vlajka > 0): buffer obsahuje prikaz dlouhy "vlajka" bytu
;				0x1E1 - 0x1EF -> 15bytu nepouzito

; prectena ci zapisovana data
DATA_L 			equ 0x020 ; res 1
DATA_H 			equ 0x021
; HODNOTY ATA REGISTRU 
ATA_STATUS_A	equ 0x022
DEVICE_C 		equ 0x023
FEATURES 		equ 0x024
ATA_ERROR		equ 0x025
SECTOR_C 		equ 0x026
LBA1			equ 0x027	; alias  SECTOR_N
LBA2			equ 0x028	; alias  CILINDER_L
LBA3			equ 0x029	; alias  CILINDER_H
LBA4			equ 0x02a	; toto neni registr ATA, ale pouze posledni cast aktualni adresy
DEVICE			equ 0x02b	; alias  DEVICE_H
ATA_STATUS		equ 0x02c
COMMAND 		equ 0x02d
;**********************************************************
; BITY ATA REGISTRU
         ; ATA_STATUS register
BSY				equ 7	; = 1 -> disk je zaneprazdneny, ostatni registry nemusi obsahovat pravdivou informaci
DRDY			equ 6	; = 1 -> disk ready (pripraven k praci)
DRQ				equ 3	; = 1 -> signalizuje, ze jsou pripravena data ke cteni 
ERR				equ 0	; = 1 -> pri provadeni posledniho prikazu doslo k chybe
         ; ATA_ERROR register
ABRT			equ 2	; = 1 -> prikaz aborted (spatny optkode prikazu)
         ; DEVICE_C (control) register
SRST			equ 2	; nastavime-li, provedeme soft. reset disku
nEIN			equ 1	; zakazuje preruseni disku (signal INTRQ)
HOB				equ 7	; tento bit DEVICE CONTROL se nastavuje pouze pokud disk podporuje LBA 48 a cteme horni cast adresy LBA...
;**********************************************************
ATA_ATTRIBUTES 	equ 0x02e 	; Parametry hardisku. 
;Bity maji nasledujici vyznam:
ATA_OK			equ 0	; 0. bit = 1 -> disk je pritomen, zapnuty a funkcni :-)
LBA_SUPPORT		equ 1	; 1. bit = 1 -> podpora LBA (pokud neni nastaven bit2, tak pouze LBA28 -> disk do 120GB)
LBA48_SUPPORT	equ 2	; 2. bit = 1 -> podpora LBA 48 (disk je zrejme vetsi jak 120GB)
BIG_SECTOR		equ 3	; 3. bit = 1 -> velikost sektoru je vetsi nez 256 !!! (s takovym diskem zatim tento program neumi)
						; 4. bit  -> nepouzit
						; 5. bit  -> nepouzit
						; 6. bit  -> nepouzit (tyto tri bity treba pouziju pro vlastnosti FATky)
APPLICABLE		equ 7	; 7. bit = 1 -> disk je pro nas pouzitelny (LBA, sektor o 512B)


PARAM_MAX_LBA1	equ 0x02f		; [4B] maximalni hodnota LBA (velikost disku)	
PARAM_MAX_LBA2	equ 0x030		; tady pozor, disky mohou byt adresovany az LBA 48, MBR je ale omezen na LBA 32 (2TB)
PARAM_MAX_LBA3	equ 0x031		; tak by nemelo smysl vsech 48b kdyz by se nevyuzily. (Navic jsem disk vetsi nez 2TB nevidel :)
PARAM_MAX_LBA4	equ 0x032		; (registr s indexem 1 ma nejnizsi vahu)

PARAM_SLOV_V_SEKTORU1	equ 0x33 ; [2B] disky mohou mit velikost sektoru vetsi nez 512 (256sl) 
PARAM_SLOV_V_SEKTORU2	equ 0x34 
; pokud je to zapsano takto, nejvyznamejsi bity jsou niz v paneti (PARAM_MAX_LBA + X)
; pokud je zapsano jako skupina LBA1, LBA2, LBA3, LBA4, tak nejvyznamejsi bity jsou v LBA4
;**********************************************************
; pomocne registry pouzivane v podprogramech 
; !!! MUSIME ZAJISTIT ABY NEBYLY POUZIVANY VE VNORENYCH PODPROGRAMECH !!!
TEMPW			equ 0x035
TEMP1			equ 0x036
TEMP2			equ 0x037
TEMP3			equ 0x038
TEMP4			equ 0x039
TEMP5			equ 0x03a

; !!! pomocne promenne pro spozdovaci smycky jsou na stejnych mistech
; pouzito pro synchronizaci s prog. picdelay
TMP1			equ 0x036
TMP2			equ 0x037
TMP0			equ 0x038
;**********************************************************
; BANK_1	s touto bankou pracuji procedury provadejici 32 bitove 
; 			aritmeto/logicke operace
OPERAND_X1		equ 0x0A0
OPERAND_X2		equ 0x0A1
OPERAND_X3		equ 0x0A2
OPERAND_X4		equ 0x0A3

OPERAND_Y1		equ 0x0A4
OPERAND_Y2		equ 0x0A5
OPERAND_Y3		equ 0x0A6
OPERAND_Y4		equ 0x0A7

VYSLEDEK1		equ 0x0A8
VYSLEDEK2		equ 0x0A9
VYSLEDEK3		equ 0x0AA
VYSLEDEK4		equ 0x0AB

PRETECENI		equ 0x0AC
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
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
