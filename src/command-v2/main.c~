/* Compile options:  -ml (Large code model) */

#pragma config WDT = OFF
#pragma config PWRT = ON
#pragma config MCLRE = ON
#pragma config LPT1OSC = OFF
#pragma config PBADEN = OFF
#pragma config LVP = OFF
#pragma config OSC = HS
#pragma config CPD = OFF
#pragma config WRTD = OFF

////////////////////////////////////////////////////////////////////////
void InterruptHandlerHigh (void);
void NastartujOdpocet (void);
void str2ram(static char *dest, const static char rom *src);
void WrUsart(unsigned char dato);
unsigned char RdUsart(void);
void VyprazdniBufferSouboru(void);
void NastavStavPrehravani(void);
void CtiStavPrehravani(void);
void PisHexa(unsigned char hodnota);
unsigned char EEPROMRead(unsigned char Adresa);
void EEPROMWrite(unsigned char Adresa,unsigned char Dato);
void UlozKonfiguraci(void);


#include <delays.h>
#include <pwm.h>
#include <timers.h>
#include <string.h>
#include <usart.h>
#include "promenne.h"
#include "font-maly.h"
#include "font-velky.h"
#include "lcd.c"
#include "menu.c"
#include "standby.c"
#include "nastaveni.c"
#include "moznosti.c"
#include "uvod.c"
#include "vyberoddilu.c"
#include "prehravani.c"
#include "pruzkumnik.c"


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

#pragma code InterruptVectorHigh = 0x08
void
InterruptVectorHigh (void)
{
  _asm
    goto InterruptHandlerHigh //jump to interrupt routine
  _endasm
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
// High priority interrupt routine

#pragma code
#pragma interrupt InterruptHandlerHigh

void InterruptHandlerHigh (){
  if (INTCONbits.TMR0IF){				//check for TMR0 overflow
		TMR0L=0x67;
		TMR0H=0x9e;		//; 5ms

    INTCONbits.TMR0IF = 0;		//clear interrupt flag
    Flags.Bit.Timeout = 1;		//indicate timeout
		
		// poku dpri predchozim testovani bylo tlacitko v nule a ted je v jednicce, 
		// tak nastavime priznak stisku...
		if ((TLPred.Bit.TlVolUp==0) 	&& (ATlVolUp==1))		{Flags.Bit.TlVolUp=1;}
		if ((TLPred.Bit.TlVolDown==0) && (ATlVolDown==1))	{Flags.Bit.TlVolDown=1;}
		if ((TLPred.Bit.TlUp==0) 			&& (ATlUp==1))			{Flags.Bit.TlUp=1;}
		if ((TLPred.Bit.TlDown==0) 		&& (ATlDown==1))		{Flags.Bit.TlDown=1;}
		if ((TLPred.Bit.TlLeft==0) 		&& (ATlLeft==1))		{Flags.Bit.TlLeft=1;}
		if ((TLPred.Bit.TlPlay==0) 		&& (ATlPlay==1))		{Flags.Bit.TlPlay=1;}
		if ((TLPred.Bit.TlStop==0) 		&& (ATlStop==1))		{Flags.Bit.TlStop=1;}
		if ((TLPred.Bit.TlRight==0) 	&& (ATlRight==1))		{Flags.Bit.TlRight=1;}
		if ((TLPred.Bit.TlMenu==0) 		&& (ATlMenu==1))		{Flags.Bit.TlMenu=1;}

		TLPred.Bit.TlVolUp		=ATlVolUp;
		TLPred.Bit.TlVolDown	=ATlVolDown;
		TLPred.Bit.TlUp				=ATlUp;
		TLPred.Bit.TlDown			=ATlDown;
		TLPred.Bit.TlLeft			=ATlLeft;
		TLPred.Bit.TlPlay			=ATlPlay;
		TLPred.Bit.TlStop			=ATlStop;
		TLPred.Bit.TlRight		=ATlRight;
		TLPred.Bit.TlMenu			=ATlMenu;

		if (ATlVolUp 
			|| ATlVolDown
			|| ATlUp
			|| ATlDown
			|| ATlLeft
			|| ATlPlay
			|| ATlStop
			|| ATlRight
			|| ATlMenu
		){
			NastartujOdpocet();
		}

		if (CitacRolovani==0){
			CitacRolovani=RychlostRolovani;
			Flags.Bit.Rolovat=1;
			Flags.Bit.ZobrazitCas=!Flags.Bit.ZobrazitCas;
		}else{
			CitacRolovani--;
		}

		if (Odpocet==0){
			if (AktualniPodsvetleniTlacitek>2){AktualniPodsvetleniTlacitek--;}
			if (AktualniPodsvetleniLCD>2){AktualniPodsvetleniLCD--;}
		}else{
			if (ZtlumitPodsvetleni!=5) {
				Odpocet--;
			}
		}
  }
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void NastartujOdpocet (void){
//unsigned char ZtlumitPodsvetleni=5;	// po jaké dobì bez stisku klávesy ztlumit podsvìtlení 
// (5s,10s,30s,1M,5M,nikdy)
// Odpocet
		//if (ZtlumitPodsvetleni==0){
			Odpocet=1000;	// 5s
		//}
		if (ZtlumitPodsvetleni==1){
			Odpocet=2000;	// 10s
		}
		if (ZtlumitPodsvetleni==2){
			Odpocet=6000;	// 30s
		}
		if (ZtlumitPodsvetleni==3){
			Odpocet=12000;	// 1M
		}
		if (ZtlumitPodsvetleni==4){
			Odpocet=60000;	// 5M
		}
	AktualniPodsvetleniTlacitek = PodsvetleniTlacitek;
	AktualniPodsvetleniLCD = PodsvetleniLCD;
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void WrUsart(unsigned char dato){
//	Delay10KTCYx(25);				// abychom moc nechvatali...
	while(!TXSTAbits.TRMT);
	TXREG = dato; 
//	RdUsart();
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
unsigned char RdUsart(void){
	while( !DataRdyUSART() );
	return RCREG;
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void NastavStavPrehravani(void){
	WrUsart(0x84);
	WrUsart(PREHSTAV0.Byte);
	WrUsart(PREHSTAV1.Byte);
	RdUsart();
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void CtiStavPrehravani(void){
	WrUsart(0x81);
	PREHSTAV0.Byte=RdUsart();
	PREHSTAV1.Byte=RdUsart();
	Cas.Low=RdUsart();
	Cas.High=RdUsart();
	
	if (PREHSTAV0.Bit.NeprehravatDal){
		RezimPrehravani=3;
	}else{
		if (PREHSTAV0.Bit.Repeat){
			if (PREHSTAV0.Bit.RepeatSouboru){RezimPrehravani=4;}
			else{RezimPrehravani=2;}
		}else{
			if (PREHSTAV0.Bit.ProhledavatAdresare){RezimPrehravani=0;}
			else{RezimPrehravani=1;}
		}		
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

void Init(void){
	unsigned int pomocna;
	// konfigurace portu C
	TRISC = 0xF9 ; // b'1111 1001';
	// TRISC = 0xB9 ; // b'1011 1001';

	// konfigurace portu A
	PORTA=0x00;
	LATA=0x00;
	ADCON1=0x0F;		// jako digitální (A/D)
	CMCON=0x07;			// jako digitální (komparátory)
	CVRCON=0x00;
	TRISA=0x00;			// nastavit všechno jako výstupy

	// konfigurace portu D
	PORTD=0;
	LATD=0;
	TRISD=0;	

	// nactani nastaveni z pameti EEPROM	
	Ekvalizer = EEPROMRead(0x00);
	if (Ekvalizer > 12){Ekvalizer=0;}
	VypinatDisk = EEPROMRead(0x01);
	if (VypinatDisk > 5){VypinatDisk=1;}
	ZtlumitPodsvetleni = EEPROMRead(0x02);
	if (ZtlumitPodsvetleni > 5){ZtlumitPodsvetleni=5;}
	
	pomocna=EEPROMRead(0x04);
	PodsvetleniLCD=(pomocna << 8) | EEPROMRead(0x03);
	if (PodsvetleniLCD > 1023){PodsvetleniLCD=64;}
	
	pomocna=EEPROMRead(0x06);
	PodsvetleniTlacitek=(pomocna << 8) | EEPROMRead(0x05);
	if (PodsvetleniTlacitek>1023){PodsvetleniTlacitek=512;}

	// konfigurace PWMky puzivane k regulaci podsvetleni
	OpenPWM2(10);				// Setup Timer2, CCP1 to provide
	OpenPWM1(10);				// Setup Timer2, CCP1 to provide
	// 15 - 20,8kHz
	// 11 - 28,4kHz
	// 10 - 31kHz
	// 9  - 34,7kHz
	// frekvence PWM je neco okolo 31KHz, protoze kdyz byla mensi (1.5KHz) 
	// tak byla pri mensich hlasitostech slysitelna ve sluchatkach...
	OpenTimer2(T2_PS_1_16 & T2_POST_1_16 & TIMER_INT_ON);

	AktualniPodsvetleniTlacitek = PodsvetleniTlacitek;
	AktualniPodsvetleniLCD = PodsvetleniLCD;
	SetDCPWM2(AktualniPodsvetleniLCD);
	SetDCPWM1(AktualniPodsvetleniTlacitek);

	// konfigurace usartu
 	OpenUSART (USART_TX_INT_OFF &
             USART_RX_INT_OFF &
             USART_ASYNCH_MODE &
             USART_EIGHT_BIT &
             USART_CONT_RX &
             USART_BRGH_HIGH, 64);

	//konfigurace timeru0
	OpenTimer0(TIMER_INT_ON & T0_16BIT & T0_SOURCE_INT & T0_PS_1_1);
	INTCONbits.GIE=1;

	//nulovani priznaku tlacitek
	Flags.Byte=0x0000;
	TLPred.Byte=0x0000;
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void str2ram(static char *dest, const static char rom *src){
	while ((*dest++ = *src++) != '\0');
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
unsigned char EEPROMRead(unsigned char Adresa){
  /*
   * The first thing to do is to read
   * the start direction from data EEPROM.
   */
  EEADRH=0;
  EEADR = Adresa;
  EECON1bits.EEPGD = 0;
  EECON1bits.CFGS = 0;
  EECON1bits.RD = 1;
  return EEDATA;
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void EEPROMWrite(unsigned char Adresa,unsigned char Dato){
  EEADRH=0;
  EEADR = Adresa;
  EEDATA = Dato;
  EECON1bits.EEPGD = 0;	// Point to DATA memory
  EECON1bits.CFGS = 0;	// Access EEPROM
  EECON1bits.WREN = 1;	// Enable writes
  INTCONbits.GIE = 0;		// Disable Interrupts
  
  _asm
	movlw 0x55
	movwf EECON2,ACCESS
	movlw 0xAA
	movwf EECON2,ACCESS
	bsf EECON1,1,ACCESS		// Set WR bit to begin write
  _endasm
  
  INTCONbits.GIE = 1;		// Enable Interrupts
  EECON1bits.WREN = 0;	// Disable writes

	while (EECON1bits.WR);	// pockame, nez se dokonci zapis...
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void UlozKonfiguraci(void){
	unsigned char Dato;
	if (EEPROMRead(0x00)!=Ekvalizer){
		EEPROMWrite(0x00,Ekvalizer);
	}
	if (EEPROMRead(0x01)!=VypinatDisk){
		EEPROMWrite(0x01,VypinatDisk);
	}
	if (EEPROMRead(0x02)!=ZtlumitPodsvetleni){
		EEPROMWrite(0x02,ZtlumitPodsvetleni);
	}
	Dato=PodsvetleniLCD;
	if (EEPROMRead(0x03)!=Dato){
		EEPROMWrite(0x03,Dato);
	}
	Dato=PodsvetleniLCD >> 8;
	if (EEPROMRead(0x04)!=Dato){
		EEPROMWrite(0x04,Dato);
	}
	Dato=PodsvetleniTlacitek;
	if (EEPROMRead(0x05)!=Dato){
		EEPROMWrite(0x05,Dato);
	}
	Dato=PodsvetleniTlacitek >> 8;
	if (EEPROMRead(0x06)!=Dato){
		EEPROMWrite(0x06,Dato);
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void main (void)
{
	Init();
	InitLCD();

	Hlasitost=0xC0;
	Cas.Odehrany=0;

	Obrazovka=0x00;
	Flags.Bit.ZmenaObrazovky=1;
  while (1){
		SetDCPWM2(AktualniPodsvetleniLCD);
		SetDCPWM1(AktualniPodsvetleniTlacitek);

		// osetøení nastavení hlasitosti
		if (Flags.Bit.NactenOddil){
			CtiStavPrehravani();
		if (ATlVolUp && ATlVolDown){
			// mute
			PREHSTAV1.Bit.Mute=1;
			Flags.Bit.ZmenaHlasitosti=1;
			NastavStavPrehravani();
			Delay10KTCYx(40);	// 80ms = 400 000 instrukci
			// protoze se nikdy nepovede pustit tlacitka soucasne, proto tato prodleva
		}else{			
			if ((PREHSTAV1.Bit.Mute) && ((ATlVolUp) || (ATlVolDown))){
				Flags.Bit.ZmenaHlasitosti=1;
				PREHSTAV1.Bit.Mute=0;
				NastavStavPrehravani();
			}
			if (ATlVolUp && (Hlasitost<=(0xFF-4))){
				Hlasitost=Hlasitost+4;
				WrUsart(0x82);
				i=0xFF-Hlasitost;	// protoze v dekoderu je 00 maximalni a 255 minimalni
				WrUsart(i);
				WrUsart(i);
				Flags.Bit.ZmenaHlasitosti=1;

				Delay10KTCYx(20);	// 40ms = 200 000 instrukci
												// kdyz se neprehrava mp3 je odezva obsluzneho procesoru temer okamzita
												// proto tady cekame, aby zmena hlasitosti nebyla moc rychla (kdyz se neprehrava)
				RdUsart();				
			}
			if (ATlVolDown && (Hlasitost>=4)){
				Hlasitost=Hlasitost-4;
				WrUsart(0x82);
				i=0xFF-Hlasitost;	// protoze v dekoderu je 00 maximalni a 255 minimalni
				WrUsart(i);
				WrUsart(i);
				Flags.Bit.ZmenaHlasitosti=1;

				Delay10KTCYx(20);	// 40ms = 200 000 instrukci
												// kdyz se neprehrava mp3 je odezva obsluzneho procesoru temer okamzita
												// proto tady cekame, aby zmena hlasitosti nebyla moc rychla (kdyz se neprehrava)
				RdUsart();				
			}
		}
		}
		////////////////////////////////////////////////////////////////////////

		if (Obrazovka==0x00){
			//volat proceduru pro nacteni disku
			CekejNaDisk();
		}
		if (Obrazovka==0x01){
			//volat proceduru pro vyber oddilu
			VyberOddilu();
		}
		if(Obrazovka>=0x10 && Obrazovka<0x20){
			//volat procedururu pro prehravani
			Prehravani();
		}
		if(Obrazovka>=0x20 && Obrazovka<0x30){
			//volat procedururu pro prochazeni slozkami
			Pruzkumnik();
		}
		if(Obrazovka>=0x30 && Obrazovka<0x40){
			//volat procedururu pro menu
			Menu();
		}
		if(Obrazovka>=0x40 && Obrazovka<0x50){
			//volat procedururu pro moznosti prehravani
			moznosti();
		}
		if(Obrazovka>=0x50 && Obrazovka<0x60){
			//volat procedururu pro nastaveni prehravace
			nastaveni();
		}
		if(Obrazovka>=0x60 && Obrazovka<0xFF){
			//volat procedururu pro standby
			standby();
		}
	}
}
