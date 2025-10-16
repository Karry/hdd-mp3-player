// signaly k LCD
#define	LCDReset	PORTAbits.RA0		// reset modulu (RST=0 - reset, RST=1 - normalní funkce)
#define	LCDCS2		PORTAbits.RA1		// výbìr øadièe pro pravou èást LCD (CS2=1 - vybráno)
#define	LCDCS1		PORTAbits.RA2		// výbìr øadièe pro levou èást LCD (CS1=1 - vybráno)
#define	LCDE			PORTAbits.RA3		// hodinový signál
#define	LCDRW			PORTAbits.RA4		// volba mezi: RW=0 - zápisem, RW=1 - ètením
#define	LCDRS			PORTAbits.RA5		// volba mezi: RS=0 - instrukcí, RS=1 - daty

#define	LCDData		PORTD

//tlacitka
#define	ATlVolUp	PORTEbits.RE1
#define	ATlVolDown	PORTEbits.RE0
#define	ATlUp			PORTBbits.RB7
#define	ATlDown		PORTBbits.RB6

#define	ATlLeft		PORTBbits.RB5
#define	ATlPlay		PORTBbits.RB4
#define	ATlStop		PORTBbits.RB3
#define	ATlRight	PORTBbits.RB2
#define	ATlMenu		PORTBbits.RB1
#define	IR				PORTBbits.RB0		// do budoucna pripraveno na pripojeni IR cidla...

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
#pragma udata cast1
// nastaveni
unsigned char Ekvalizer=0;
unsigned char RezimPrehravani=0;		// 0=prohledávání, hrát porád dál; 1=pøehrát složku; 2=repeat složky; 3=pøehrát jednu; 4=repeat souboru
unsigned int PodsvetleniLCD=64;								// 0..1023
unsigned int AktualniPodsvetleniLCD=0;				// 0..1023
unsigned int PodsvetleniTlacitek=512;					// 0..1023
unsigned int AktualniPodsvetleniTlacitek=512;	// 0..1023
unsigned char VypinatDisk=1;	// po jaké dobì neèinosti (minuty) se má vypínat disk        (5, 10, 15, 30,60,nikdy)
unsigned char ZtlumitPodsvetleni=5;	// po jaké dobì bez stisku klávesy ztlumit podsvìtlení (5s,10s,30s,1M,5M,nikdy)

unsigned int Odpocet=0xFFFF;	// do této promìnné se pøi stisku klávesy umístí konstanta v závislosti na ZtlumitPodsvetleni
															// každých 5ms (pøerušení) se od této promìnné jednotka odeète (pokud není ZtlumitPodsvetleni==5)
															// pokud se rovná nule, tak se odeèítá od AktualniPodsvetleniXXX než dosáhne min. hodnoty...
unsigned char PocetOddilu;
unsigned char Hlasitost;
union{
 struct{
	unsigned Low:8;
	unsigned High:8;
 };
 unsigned int Odehrany;
}Cas;
unsigned int ZobrazenyCas;
unsigned char TrvaniPomalehoPrevijeni;

// behove prommene
unsigned char radek, sloupec;	// aktuální pomyslný kurzor. radek mùže být 0..7, sloupec 0..127

unsigned char Obrazovka;			// horni bity urcuji na ktere borazovce se nachazime, dolni podobrazovku 
unsigned char PolozkaMenu=0;	// urcuje, ktera polozka nejakeho menu je aktivni

char ram StringBuffer[21],StringBuffer2[21];

// pomocne
signed char i,k;


// stav pøehrávaèe
union
{
  struct
  {
    unsigned Timeout:1;         //flag to indicate a TMR0 timeout
    unsigned TlVolUp:1;
    unsigned TlVolDown:1;
    unsigned TlUp:1;
    unsigned TlDown:1;
    unsigned TlLeft:1;
    unsigned TlPlay:1;
    unsigned TlStop:1;

    unsigned TlRight:1;
    unsigned TlMenu:1;
    unsigned ZmenaObrazovky:1;
    unsigned ZmenaHlasitosti:1;
		unsigned NactenOddil:1;
		unsigned Rolovat:1;
		unsigned ZobrazitCas:1;
		unsigned Stop:1;
  } Bit;
  unsigned int Byte;
} Flags=0;

union
{
  struct
  {
    unsigned ZmenenAdresar:1;
    unsigned ZmenenVybZaznam:1;	// vlajky pro pruzkumnika
    unsigned PlayPredStandBy:1;	// pro standby
    unsigned BylNactenyOddil:1;
  } Bit;
  unsigned char Byte;
}Flags2=0;

// promenne pro pruzkumnika

unsigned char PrvniZobrazeny,Vybrany;
unsigned char LbaAktualnihoAdresare[4];
char ram AktualniAdresar[16];
unsigned char OznacitZaznam[2]; // pokud se zmenil adresar, tak dame tento zaznm jako oznaceny...

// stav pøehrávaèe
union
{
  struct
  {
    unsigned TlVolUp:1;
    unsigned TlVolDown:1;
    unsigned TlUp:1;
    unsigned TlDown:1;
    unsigned TlLeft:1;
    unsigned TlPlay:1;
    unsigned TlStop:1;
    unsigned TlRight:1;
    unsigned TlMenu:1;
  } Bit;
  unsigned int Byte;
} TLPred;

union
{
  struct
  {
    unsigned Play:1;
    unsigned JeSoubor:1;
    unsigned ZmenenSoubor:1;
    unsigned NeprehravatDal:1;
    unsigned Repeat:1;
    unsigned RepeatSouboru:1;
    unsigned ProhledavatAdresare:1;
    unsigned PrehravatPoSpusteni:1;
  } Bit;
  unsigned char Byte;
} PREHSTAV0=0;

union
{
  struct
  {
    unsigned PrevijetMp3:1;
    unsigned Rezervovano1:1;
    unsigned PrevijetPomalu:1;
    unsigned ZvyraznitBasy:1;
    unsigned Mute:1;
    unsigned Rezervovano5:1;
    unsigned Rezervovano6:1;
    unsigned Rezervovano7:1;
  } Bit;
  unsigned char Byte;
} PREHSTAV1=0;

unsigned char AUDATA[2];
unsigned int bitrate;
unsigned char HDAT0[2];
unsigned char HDAT1[2];
unsigned char LbaPrehrAdresare[4];
unsigned char ZazPrehrSouboru[2];
unsigned char CitacRolovani=0, PoziceSouboru,PoziceAdresare;
const char RychlostRolovani=120;	// prodleva = RychlostRolovani * 5ms

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

#pragma udata cast2
#define BufferSize 13
char ram BufferSouboru[BufferSize][19];

#pragma udata cast3
char ram AdresySouboru[BufferSize][7]; 
		// prvni byte urcuje typ zaznamu, pote je prvni cluster [4] a pote zaznam [2]

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

#pragma udata cast4
char ram PrehravanySoubor[66];
char ram PrehravanyAdresar[66];
