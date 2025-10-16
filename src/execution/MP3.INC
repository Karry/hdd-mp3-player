;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; DEFINICE PORTU
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;**********************************************************
; ZAPOJENI PORTU:
;       portA - adresove signaly ATA, ERROR_LED, a USART
; 				5     4     3          2    1    0
; 				CS1-  CS0-  ERROR_LED  DA2  DA1  DA0  
;				(signaly se znaminkem minus jsou aktivni v logicke 0 !!!)
;		portB - ATA datova sbernice (dolnich 8 bitu)
;               7   .. 0
;               DD7 .. DD0
;		portD - ATA datova sbernice (hornich 8 bitu)
;               15   .. 8
;               DD15 .. DD8 
;		portC - MP3 dekoder vs1001g
; 				7          6        5  4  3    2     1  0
; 				USART out  USART in SI SO SCLK BSYNC CS DREQ
;		portE - ridici signaly ATA
;				2       1      0
;				DIOR-	DIOW-  RESET-
;				(signaly se znaminkem minus jsou aktivni v logicke 0 !!!)
;**********************************************************
MP3_PORT		equ PORTC
MP3_PORT_TRIS	equ TRISC
; BITY MP3_PORT
#define MP3_SO		MP3_PORT,4	; serial output - tady dostavame z dekoderu data
#define MP3_SI		MP3_PORT,5	; serial input  - pokud MP3_CS=1, tak posilame mp3 data, pokud =0, tak posilame prikaz
#define MP3_SCLK	MP3_PORT,3	; clock - nabezna hrana urcuje platnost dat pri seriovem prenosu
#define MP3_CS		MP3_PORT,1	; cable select  - pokud MP3_CS=1, tak po SI posilame mp3 data, pokud =0, tak posilame prikaz
#define MP3_DREQ	MP3_PORT,0	; data request  - pokud =1, tak dekoder pozaduje dalsi mp3 data
#define MP3_BSYNC	MP3_PORT,2	; pro synchronizaci - ma byt nastaven pri prvnim prenasenem bitu kazdeho bytu
;**********************************************************
; pokud jsem dobre pochopil dataSheat dekoderu vs1001, tak staci do nej jen cpat data, a kdyz skonci mp3, tak odeslat 1024 nulovych bytu,
; softwarove resetovat a posilat dalsi mp3...
;
; popis registru obvodu vs1001 najdete na strane 22 dataSheatu 
; v jeho registrech jsou k dispozici data z hlavicky mp3, zdali mp3 ma spravny format, 
; ovladani hlasitosti a dalsi spousty uzitecnych informaci
;**********************************************************
; PORTY DISKU
ATA_ADDRESS 		equ PORTA
ATA_CONTROL 		equ PORTE
DATA_PORT_LOW 		equ PORTB
DATA_PORT_HIGH 		equ PORTD

ATA_ADDRESS_TRIS 	equ TRISA
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
; ROZLOZENI PAMETI PROGRAMU
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;	page 0	0x0000 - 0x07FF
;				- mp3.asm (hlavni smycka)
;				- ata.asm
;				- fat32.asm
;				- aritmetic.asm
;	page 1	0x0800 - 0x0FFF
;				- vs1001.asm
;				- commands.asm
;	page 2	0x1000 - 0x17FF
;	page 3	0x1800 - 0x1FFF
;
; Vsechny podprogramy by mely nechat nastaven PCLATH na hodnotu jak se do nich vstoupilo...
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; DEFINICE PROMENNYCH
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; MAPA PAMETI: (368 bytu)
; 	BANK 0: 	0x000 - 0x01F = specialni registry,
;				0x020 - 0x07F = misto (96bytu) pro nase registry:
;					0x020 - 0x034 -> 21bytu pro registry a parametry HDD
;					0x035 - 0x03a -> 6bytu pro parametry podprogramu (musime zajistit, abychom nepouzivali registry, ktere pouzivaji i podprogramy!!!)
;					0x03B - 0x04C -> parametry FATky
;					0x04D - 0x050 -> registry pro praci s VS1001
;					0x051 - 0xXXX -> ---------------------------
;					0x05F - 0x06F -> informace potrebne pro prehravani
;				0x070 - 0x07F -> registry pro potreby preruseni (dostupne z kterekoliv banky)
;					0x070 - 0x072 -> 3 registry slouzici k zalohovani W, STATUS, FSR
;					0x073 - 0x076 -> registry pro prikazy a preruseni + zaloha pro PCLATH
;					0x077         -> ---------------------------
;					0x078 - 0x07F -> 8 bytu zasobniku prikazu (obsahujici data prikazu prisla po USARTU)
;
; 	BANK 1: 	0x080 - 0x09F = specialni registry,
;				0x0A0 - 0x0EF = volne misto (80bytu)
;					0x0A0 - 0x0AC -> parametry a navratove hodnoty z aritmeto/logickych podprogramu
;					0x0AD - 0x0EF -> --------------------------- (67bytu)
;
; 	BANK 2: 	0x100 - 0x10F = specialni registry,
;				0x110 - 0x16F = misto (96bytu) pro nase registry:
;					0x110 - 0x14F -> 64bytu BUFFER_2 (pro dlouhe nazvy souboru, tabulku oddilu, a treba pro cast fatky)
;					0x150         -> pri cteni dlouheho jmena potrebuju v bufferu2 65 bytu... (ten 65 je tady)
;					0x151 - 0x16F -> --------------------------- (31bytu)
;
; 	BANK 3: 	0x180 - 0x18F = specialni registry,
;				0x190 - 0x1EF = misto (96bytu) pro nase registry:
; 					0x190 - 0x1CF -> 64bytu BUFFER_1 (pro ruzna data pri cteni...)
;					0x1D0 - 0x1EF -> --------------------------- (32 bytu)

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
FAT32_LOAD		equ 4	; 4. bit = 1 -> FATka byla uspesne analyzovana a udaje o ni jsou pravdive
						; 5. bit  -> nepouzit
						; 6. bit  -> nepouzit (tyto tri bity treba pouziju pro vlastnosti FATky)
APPLICABLE		equ 7	; 7. bit = 1 -> disk je pro nas pouzitelny (LBA, sektor o 512B)


PARAM_MAX_LBA1	equ 0x02F		; [4B] maximalni hodnota LBA (velikost disku)	
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
TEMP5			equ 0x03A

; !!! pomocne promenne pro spozdovaci smycky jsou na stejnych mistech
; pouzito pro synchronizaci s prog. picdelay
TMP1			equ 0x036
TMP2			equ 0x037
TMP0			equ 0x038
;**********************************************************
; registry pro praci s FATkou
POZICE			equ 0x03B		; na ukladani aktualni pozice v slusteru, pripadne jine kokotiny
CLUSTER1		equ 0x03C
CLUSTER2		equ 0x03D
CLUSTER3		equ 0x03E
CLUSTER4		equ 0x03F

POCATEK_DAT1	equ 0x040
POCATEK_DAT2	equ 0x041
POCATEK_DAT3	equ 0x042
POCATEK_DAT4	equ 0x043

POCATEK_FAT1	equ 0x044
POCATEK_FAT2	equ 0x045
POCATEK_FAT3	equ 0x046
POCATEK_FAT4	equ 0x047

ROOT_DIR_CL1	equ 0x048
ROOT_DIR_CL2	equ 0x049
ROOT_DIR_CL3	equ 0x04A
ROOT_DIR_CL4	equ 0x04B

CLUSTER_SIZE	equ 0x04C		; velikost clusteru (pocet sektoru na cluster)
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; DEFINICE PROMENNYCH a KONSTANT PRO PRACI S VS1001
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; adresy registru VS1001
VSADDR_MODE			equ .0		; nastaveni VS1001
VSADDR_STATUS		equ .1		; slouzi pouze pro zapnuti / vypnuti analogove casti (MUTE)
VSADDR_CLOCKF		equ .3		; informuje dekoder o jeho krystalu. !! je nutne pro spravne dekodovani !!
VSADDR_DECODE_TIME	equ .4		; obsahuje cas dekodovani aktualni MP3 !! neaktualizuje se pri skocich (previjeni)
VSADDR_AUDATA		equ .5		; obsahuje informace o datovem toku a vzorkovaci frekvenci MP3
	; bit 15 = 1 => STEREO; = 0 => MONO
	; bity 12-9 obsahuji vzorkovaci frekvenci v Hz
	;	0000 -> neznama vzorkovaci frekvence
	;	0001 -> 44 100
	;	0010 -> 48 000
	;	0011 -> 32 000
	;	0100 -> 22 050
	;	0101 -> 24 000 
	;	0110 -> 16 000
	;	0111 -> 11 025
	;	1000 -> 12 000
	;	1001 ->  8 000
	; bity 8-0 obsahuji bitrate v kbps 

VSADDR_WRAM		equ .6			; Slouzi k zapisovani uzivatelskeho programu, dato se zapise na adresu v WRAMADDR
VSADDR_WRAMADDR	equ .7			; Adresuje uzivatelskou pamet dekoderu
VSADDR_HDAT0	equ .8			; Obsahuje informace ziskane z hlavicky MP3
VSADDR_HDAT1	equ .9			; Obsahuje informace ziskane z hlavicky MP3
VSADDR_AIADDR	equ .10			; Start uzivatelskeho programu (vis. datasheet)
VSADDR_VOL		equ .11			; ovladani hlasitosti (pro oba kanaly) Horni byte je levy kanal, dolni byte je pravy kanal
								; (hodnota 0000h znamena hlasitost na max., FF00h hraje pouze pravy kanal, FFFFh je ticho)
VSADDR_AICTRL0	equ .13			; Registr pro ovladani uzivatelskeho programu
VSADDR_AICTRL1	equ .14			; Registr pro ovladani uzivatelskeho programu
;**********************************************************
; registry pro praci s VS1001	
; dekoder VS1001 ma vsechny registry 16bitove, proto za jmeno pisu _L /_H (u nekterych registru potrebuji pouze jednu cast)
VSREG_MODE_L	equ 0x04D
VSREG_STATUS_L	equ 0x04E
VSREG_VOL_L		equ 0x04F		; pravy kanal
VSREG_VOL_H		equ 0x050		; levy kanal
;**********************************************************
FRAGMENT1		equ 0x051
FRAGMENT2		equ 0x052
;**********************************************************
PREH_D_FRAGMENT1	equ 0x053
PREH_D_FRAGMENT2	equ 0x054	; 16bit cislo, ktere udava kolik clusteru mp3 dat po sobe je na disku nefragmentovano
		; pokazde kdyz prehrajeme cluster, tak toto cislo dekrementujeme. Kdyz dosahneme 0, tak zjistime dalsi 
		; cluster a pocet nefragmentovanych clusteru. (jak dlouha je rada po sobe jdoucich clusteru)
;				equ 0x055
;				equ 0x056
;				equ 0x057
;				equ 0x058
;**********************************************************
; registry pro ukladani nastaveni hledani
HL_PARAMETRY	equ 0x059
;		0. bit = 0 > pokud hledáme soubory, tak pouze MP3
;				 1 > pokud hledáme soubory, vrací všechny soubory
;		1. bit = 0 > hledáme klasicky (nejdríve adresáre, poté soubory
;				 1 > hledáme pouze adresáre, nebo soubory
;		2. bit = 0 > je-li nastaven 1. bit, hledáme pouze adresáøe
;				 1 > je-li nastaven 1. bit, hledáme pouze soubory
;		3. bit = 0 > hledáme podle cisla zaznamu bud následující ci predchozi zaznam
;				 1 > hledáme první záznam v adresáøi
;		4. bit = 0 > hledáme NÁSLEDUJÍCÍ záznam
;				 1 > hledáme PØEDCHOZÍ záznam
;		7. bit - tento bit nelze nastavit uzivatelem
;				= 0 > adresar je ROOT
;				= 1 > adresar neni ROOT

HL_ADR_CL1		equ 0x05A
HL_ADR_CL2		equ 0x05B
HL_ADR_CL3		equ 0x05C
HL_ADR_CL4		equ 0x05D	; v jakem adresari momentalne vyhledavame

ZAZNAMU_vBUFFERU_DISKU	equ 0x05E	; sem nam procedura SKOC_NA_ZAZNAM vraci kolik po sobe
			; jdoucich zaznamu nam nechala pripravenych v bufferu na disku
			; (znacne totiz zrychluje praci, protoze pokud chceme cist nasledujici zaznam a mame ho jiz 
			; v bufferu, memusime znova volat SKOC_NA_ZAZNAM ale rovnou FILE_INFO)
;XXXXXXXXX		equ 0x05F
;**********************************************************
; registry pro praci procedur v filesystem (dalsi registry pozivane proceduramy v filesystem jsou CLUSTER a POZICE)
ZAZNAM1			equ 0x060
ZAZNAM2			equ 0x061	; poradi zaznamu v adresari
;**********************************************************
; informace potrebne pro prehravani
PREH_ADR_CL1		equ 0x062
PREH_ADR_CL2		equ 0x063
PREH_ADR_CL3		equ 0x064
PREH_ADR_CL4		equ 0x065	; prni cluster adresare, ktery se prave prehrava...

PREH_ZAZNAM1		equ 0x066
PREH_ZAZNAM2		equ 0x067	; poradi zaznamu v adresari ktery se zrovna prehrava (soubor mp3)

PREH_CITAC_PREV		equ 0x068	; pokud je mp3 previjena pomalu, sem se zapisuje kolik sektoru se jiz previnulo. 
								; (Pøi pomalém pøevíjení je pomìr pøehraných sektorù ku pøeskoèeným 5:20.)

PREH_DATA_CL1		equ 0x069
PREH_DATA_CL2		equ 0x06A
PREH_DATA_CL3		equ 0x06B
PREH_DATA_CL4		equ 0x06C	; aktualni cluster, ktery se prehrava
PREH_DATA_POZICE	equ 0x06D	; sektor v clusteru, ktery se prehrava

PREH_STAV0			equ 0x06E	; registr obsahuje informace o stavu aktualniho prehravani
				; 0. bit = 	0 => stop nebo pausa (nic nehraje)
				;			1 => play            (nejaky soubor je prehravan)
				; 1. bit = 	0 => neni zadny soubor k prehravani (nastaveni bitu play nema zadny ucinek)
				;			1 => je soubor pripraven k prehravani (muze byt ale pauza - nic nehraje)
				; 2. bit = 	1 => je nastaven, kdyz se zmeni prehravany soubor (bez volani prikazu) do doby, nez prijde prikaz na dotaz STAVU... (81h)
				; 3. bit = 	0 => po skonceni souboru se pokracuje v prehravani (zavisi na nastaveni repeatu)
				; 			1 => po skonceni prehravani souboru se nic neprehrava (ceka se na prijeti prikazu k prehravani)
				; 4. bit = 	0 => repeat off
				;			1 => repeat on
				; 5. bit =	0 => repeat adresare (prvni cluster adresare musi byt nastaven v PREH_ADDR_ZACATEK_CL[1-4] )
				;			1 => repeat souboru (po skonceni prehravani souboru se ten samy soubor zacne prehravat znova)
				; 6. bit =	0 => 
				;			1 => rezervovano (pro nahodny vyber, nebo jiny rezim prehravani...)
				; 7. bit =  0 => 
				;			1 => rezervovano
PREH_STAV1			equ 0x06F
				; 0. bit =  0 => normalni prehravani
				;			1 => previjeni mp3 dopredu
				; 1. bit =  0 => 
				;			1 => rezervovano (pro previjeni dozadu)
				; 2. bit =	zpusob previjeni,	0 => previji se rychle, potichu
				;								1 => previji se pomalu, vzdy se po nejake dobe kratky usek souboru prehraje
				; 3. bit =	0 => normalni nastaveni zvuku
				;			1 => zvyrazneni basu a vysek (moznost dekoderu vs1001 "bass/treble enhancer")
				; 4. bit =	0 => NO MUTE
				;			1 => MUTE
				; 5., 6., 7. bit 
				;			=> rezervovano
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
; registry pro potreby preruseni + prace s prikazy (jsou totiz dostupne odkudkoliv)
TEMP_WORKING	equ 0x070
TEMP_STATUS		equ 0x071
TEMP_FSR		equ 0x072
PRIJATYCH_DAT	equ 0x073		; ukazuje kolik je platnych dat v zasobniku prikazu (0 -> zasobnik je prazdny)
PRIJATE_DATO	equ 0x074		; pomocna promenna v preruseni
STAV_PRIKAZU	equ 0x075		; pomocny registr signalizujici stav prikazu umisteneho v zasobniku prikazu
								; pokud zadna procedura nenastavi do 1, je prikaz v tuto chvili neplatny
								; pokud prikaz je pro proceduru ale nama zatim dost parametru, muji tento byt nastavit take do 1
TEMP_PCLATH		equ 0x076
; 0x078 - 0x07F		-> zasobnik prikazu (data prisla po USARTU)
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
