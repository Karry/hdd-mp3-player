////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void CekejNaLCD(void){
// porad dokola cte z lcd stavove slovo, a ceka, nez se vinuluje priznak 
	TRISD=0xFF;		// vstup (cteme)
	do{
		LCDRW=1;			// R/W na RB1 je 1 - cteni
		LCDRS=0;			// RS na  RB2 je 0 - instrukce
		Nop();
		Nop();				// Tas min 140ns
		LCDE=1;

		Delay10TCYx( 2 );	// dvacet instrukci pockame
											// ENABLE slespon 450ns v log1

		WREG=LCDData;
		Nop();
		Nop();
		LCDE=0;
		LCDRW=0;			// R/W na RB1 je 0 - zapis

		_asm
		andlw 0x90
		_endasm

	}while(WREG!=0x00);
	TRISD=0;			// vystup
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void ZapisD(unsigned char Dato){
	// krystal 20MHz => instrukce = 200ns
	if (sloupec<128){
		sloupec++;
		CekejNaLCD();

		LCDRS=1;			// RS na  RB2 je 1 - DATA
		LCDRW=0;			// R/W na RB1 je 0 - zapis
		Nop();
		Nop();				// Tas min 140ns
		LCDData=Dato;
		Delay10TCYx( 1 );	// deset instrukci pockame
		LCDE=1;

		Delay10TCYx( 2 );	// dvacet instrukci pockame
											// ENABLE slespon 450ns v log1

		LCDE=0;
		Nop();
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void ZapisI(unsigned char Instrukce){
	// krystal 20MHz => instrukce = 200ns
	CekejNaLCD();

	LCDRS=0;			// RS na  RB2 je 0 - instrukce
	LCDRW=0;			// R/W na RB1 je 0 - zapis
	Nop();
	Nop();				// Tas min 140ns
	LCDData=Instrukce;
	Delay10TCYx( 1 );	// deset instrukci pockame
	LCDE=1;

	Nop();
	Nop();
	Nop();
	Nop();
	Nop();				// ENABLE slespon 450ns v log1
	LCDE=0;
	Nop();
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void NastavPozici(void){
	unsigned char x=0;
	// radek, sloupec
	if (sloupec>63){
		LCDCS2=1;
		LCDCS1=0;			// prava pulka
		x=sloupec-64;
	}else{
		LCDCS2=0;
		LCDCS1=1;			// leva pulka
		x=sloupec;
	}
	WREG=radek;
	_asm
	iorlw 0xB8	
	_endasm
 	ZapisI(WREG);	// nastaveni stranky

	WREG=x;
	_asm
	iorlw 0x40	
	_endasm
 	ZapisI(WREG);	// nastaví pozici X 
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void SmazPulLcd(void){
	unsigned char Stranka=0;
	unsigned char i=0;
	ZapisI(0x40);	// nastaví pozici v X na 0
	ZapisI(0xC0);	// nastaví vertikální pozici horního řádku (stranky)
	for (Stranka=0;Stranka<8;Stranka++){
		WREG=Stranka;
		_asm
		iorlw 0xB8	
		_endasm
  	ZapisI(WREG);	// nastaveni stranky
		sloupec=0;
		for (i=0;i<64;i++){
			ZapisD(0x00);
		}	
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void SmazLcd(void){
	LCDCS2=0;
	LCDCS1=1;			// leva pulka
	
	SmazPulLcd();

	LCDCS2=1;
	LCDCS1=0;			// prava pulka

	SmazPulLcd();		
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void InitLCD(void){
	LCDCS2=0;
	LCDCS1=1;			// ted komunikujeme s levou pulkou
	LCDReset=0;		// reset

	Nop();
	Nop();
	Nop();
	Nop();
	Nop();				// chvili pockame
	LCDReset=1;		// konec resetu
  Delay10KTCYx( 10 );		// dame mu trochu casu... (20ms)


	CekejNaLCD();
	ZapisI(0x3F);	// zapni LCD

	LCDCS2=1;
	LCDCS1=0;			// ted komunikujeme s pravou pulkou
	CekejNaLCD();
	ZapisI(0x3F);	// zapni LCD

	LCDCS2=0;
	LCDCS1=1;			// leva pulka

	SmazLcd();
	radek=0;
	sloupec=0;
	NastavPozici();
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void SmazRadek(void){
	unsigned char ZalohaSloupec;
	unsigned char i;
	ZalohaSloupec=sloupec;
	sloupec=0;
	NastavPozici();
	for (i=0; i<64; i++)	{
  	ZapisD(0);	
	}	
	NastavPozici();
	for (i=0; i<64; i++)	{
  	ZapisD(0);	
	}	
	sloupec=ZalohaSloupec;
	NastavPozici();
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void ZapisMalyZnak(unsigned char Znak,unsigned char Pozadi,unsigned char Nadtrzeni){
	unsigned char Dato;
	unsigned int Pozice;
	unsigned char i;
	Pozice=Znak;
	Pozice=Pozice * 6;
	for (i=0; i<6; i++){
		if (sloupec==64){
 			NastavPozici();
		}
		Dato=FontMaly[Pozice];
		if (Nadtrzeni==1){
			WREG=Dato;
			_asm
			iorlw 0x01
			_endasm
			Dato=WREG;
		}
		if (Pozadi==1){
			WREG=Dato;
			_asm
			xorlw 0xFF
			_endasm
			Dato=WREG;
		}
  	ZapisD(Dato);
		Pozice++;
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void PisMale(const char * Co,unsigned char Pozadi,unsigned char Nadtrzeni){
	unsigned char Znaku,i,dato;
	Znaku=strlen(Co);
	NastavPozici();
	for (i=0; i<Znaku; i++){
		ZapisMalyZnak(Co[i],Pozadi,Nadtrzeni);
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void PisMaleConst(const static char rom *src,unsigned char Pozadi,unsigned char Nadtrzeni){
//	char ram StringBuffer[21]
	static char dest[21];
	unsigned char Znaku,i,dato;
	i=0;
	while (*src != '\0'){
		dest[i] = *src;
		*src++;
		i++;
	}
	dest[i]=0;

	Znaku=strlen(dest);
	NastavPozici();
	for (i=0; i<Znaku; i++){
		//dato=Co[i];
		ZapisMalyZnak(dest[i],Pozadi,Nadtrzeni);
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void ZapisVelkyZnak(unsigned char Znak,unsigned char Pozadi,unsigned char Nadtrzeni,unsigned char Podtrzeni){
	unsigned char Dato;
	unsigned int Pozice;
	unsigned char i,ZalohaRadek,ZalohaSloupec;
	ZalohaRadek=radek;
	ZalohaSloupec=sloupec;

	Pozice=Znak;
	Pozice=Pozice * 16;

	for (i=0; i<8; i++){
		if (sloupec==64){
 			NastavPozici();
		}
		Dato=FontVelky[Pozice];
		if (Nadtrzeni==1){
			WREG=Dato;
			_asm
			iorlw 0x01
			_endasm
			Dato=WREG;
		}
		if (Pozadi==1){
			WREG=Dato;
			_asm
			xorlw 0xFF
			_endasm
			Dato=WREG;
		}
  	ZapisD(Dato);
		Pozice++;
	}

	sloupec=ZalohaSloupec;
	radek++;
	NastavPozici();

	for (i=0; i<8; i++){
		if (sloupec==64){
 			NastavPozici();
		}
		Dato=FontVelky[Pozice];
		if (Podtrzeni==1){
			WREG=Dato;
			_asm
			iorlw 0x80
			_endasm
			Dato=WREG;
		}
		if (Pozadi==1){
			WREG=Dato;
			_asm
			xorlw 0xFF
			_endasm
			Dato=WREG;
		}
  	ZapisD(Dato);
		Pozice++;
	}
	radek=ZalohaRadek;
	NastavPozici();
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void PisVelke(const char * Co,unsigned char Pozadi,unsigned char Nadtrzeni,unsigned char Podtrzeni){
	unsigned char Znaku,i,dato;
	Znaku=strlen(Co);
	NastavPozici();
	for (i=0; i<Znaku; i++){
		ZapisVelkyZnak(Co[i],Pozadi,Nadtrzeni,Podtrzeni);
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void PisVelkeConst(const static char rom *src,unsigned char Pozadi,unsigned char Nadtrzeni,unsigned char Podtrzeni){
	static char dest[21];
	unsigned char Znaku,i,dato;
	i=0;
	while (*src != '\0'){
		dest[i] = *src;
		*src++;
		i++;
	}
	dest[i]=0;

	Znaku=strlen(dest);
	NastavPozici();
	for (i=0; i<Znaku; i++){
		//ZapisMalyZnak(dest[i],Pozadi,Nadtrzeni);
		ZapisVelkyZnak(dest[i],Pozadi,Nadtrzeni,Podtrzeni);
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void PisHexa(unsigned char hodnota){
	unsigned char dato,i,x;
	unsigned char pole[]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
	str2ram (StringBuffer, "0x00");
	dato=hodnota & 0xF0;
	x=0x10;
	for (i=0x01; i<0x10; i++){
		if (dato==x){
			StringBuffer[2]=pole[i];
			break;
		}
		x=x+0x10;
	}
	dato=hodnota & 0x0F;
	for (i=0x01; i<0x10; i++){
		if (dato==i){
			StringBuffer[3]=pole[i];
			break;
		}
	}
	PisMale(StringBuffer,0,0);					
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

