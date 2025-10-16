void ZobrazPosuvnik(unsigned int Hodnota,unsigned char Pozadi,unsigned char Nadtrzeni);
void NastavDobuDoStandBy(void);
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void nastaveni(void){
	#define OdecitatPodsvetleni 2;	
	unsigned char ZmenaPolozky;
	if (Flags.Bit.ZmenaObrazovky){
		SmazLcd();
		//if (PolozkaMenu>3){
		PolozkaMenu=0;
		//}
		Flags.Bit.ZmenaObrazovky=0;
		ZmenaPolozky=1;

		Flags.Bit.TlVolUp		=0;
		Flags.Bit.TlVolDown	=0;
		Flags.Bit.TlUp			=0;
		Flags.Bit.TlDown		=0;
		Flags.Bit.TlLeft		=0;
		Flags.Bit.TlPlay		=0;
		Flags.Bit.TlStop		=0;
		Flags.Bit.TlRight		=0;
		Flags.Bit.TlMenu		=0;

		radek=0;
		sloupec=8;
		str2ram (StringBuffer, "NASTAVENÍ:");
		PisVelke(StringBuffer,0,0,0);		

		// ted napissi nad tlacitky
		str2ram(StringBuffer, "\x11zpìt\x12   \x12   \x12 - \x12 + \x13");
		radek=7;
		sloupec=0;
		PisMale(StringBuffer,1,0);		
	}

	///////////////////////////////////////////////////
	if (Flags.Bit.TlUp){
		Flags.Bit.TlUp=0;
		if (PolozkaMenu!=0){
			PolozkaMenu--;
			ZmenaPolozky=1;
		} 
	}
	if (Flags.Bit.TlDown){
		Flags.Bit.TlDown=0;
		if (PolozkaMenu!=3){
			PolozkaMenu++;
			ZmenaPolozky=1;
		} 
	}	

	if (Flags.Bit.TlMenu){
		Flags.Bit.TlMenu=0;
		ZmenaPolozky=1;
		
		if (PolozkaMenu==0 && VypinatDisk!=5){
				VypinatDisk++;
				NastavDobuDoStandBy();
		}
		if (PolozkaMenu==1 && ATlMenu && PodsvetleniLCD<1022){
			PodsvetleniLCD=PodsvetleniLCD+OdecitatPodsvetleni;
			AktualniPodsvetleniLCD=PodsvetleniLCD;
			Flags.Bit.TlMenu=1;
		}
		if (PolozkaMenu==2 && ATlMenu && PodsvetleniTlacitek<1022){
			PodsvetleniTlacitek=PodsvetleniTlacitek+OdecitatPodsvetleni;
			AktualniPodsvetleniTlacitek=PodsvetleniTlacitek;
			Flags.Bit.TlMenu=1;
		}
		if (PolozkaMenu==3 && ZtlumitPodsvetleni!=5){
			ZtlumitPodsvetleni++;
			NastartujOdpocet();
		}
		
	}
	if (Flags.Bit.TlRight){
		Flags.Bit.TlRight=0;
		ZmenaPolozky=1;
		if (PolozkaMenu==0 && VypinatDisk!=0){
				VypinatDisk--;
				NastavDobuDoStandBy();
		}
		if (PolozkaMenu==1 && ATlRight && PodsvetleniLCD>1){
			PodsvetleniLCD=PodsvetleniLCD-OdecitatPodsvetleni;
			AktualniPodsvetleniLCD=PodsvetleniLCD;
			Flags.Bit.TlRight=1;
		}
		if (PolozkaMenu==2 && ATlRight && PodsvetleniTlacitek>1){
			PodsvetleniTlacitek=PodsvetleniTlacitek-OdecitatPodsvetleni;
			AktualniPodsvetleniTlacitek=PodsvetleniTlacitek;
			Flags.Bit.TlRight=1;
		}
		if (PolozkaMenu==3 && ZtlumitPodsvetleni!=0){
			ZtlumitPodsvetleni--;
			NastartujOdpocet();
		}
	}

	if (Flags.Bit.TlLeft){
		Flags.Bit.TlLeft=0;
		Flags.Bit.ZmenaObrazovky=1;
		Obrazovka=0x30;
		PolozkaMenu=2;
		UlozKonfiguraci();
	}
	///////////////////////////////////////////////////

	if (ZmenaPolozky==1){
		str2ram (StringBuffer, " vypínat HDD: ");
		// VypinatDisk => po jaké dobì neèinosti (minuty) se má vypínat disk
		// (5,10,15,30,60,nikdy)

		str2ram (StringBuffer2, "po 10M ");
		if (VypinatDisk==0){
			str2ram (StringBuffer2, "po 5M  ");
		}
		if (VypinatDisk==2){
			StringBuffer2[4]='5';
		}
		if (VypinatDisk==3){
			StringBuffer2[3]='3';
		}
		if (VypinatDisk==4){
			StringBuffer2[3]='6';
		}
		if (VypinatDisk==5){
			str2ram (StringBuffer2, "nikdy  ");
		}

		radek=2;
		sloupec=2;	
		if (PolozkaMenu==0){
				StringBuffer[0]=0x06;
				PisMale(StringBuffer,1,1);
				StringBuffer2[6]=0x07;
				PisMale(StringBuffer2,1,1);
		}else{
				PisMale(StringBuffer,0,0);
				PisMale(StringBuffer2,0,0);
		}

		radek=3;
		sloupec=2;		
		str2ram (StringBuffer, " podsvícení LCD      ");
		if (PolozkaMenu==1){
				StringBuffer[0]=0x06;
				StringBuffer[20]=0x07;
				PisMale(StringBuffer,1,1);
				ZobrazPosuvnik(PodsvetleniLCD,1,1);
		}else{
				PisMale(StringBuffer,0,0);
				ZobrazPosuvnik(PodsvetleniLCD,0,0);
		}


		radek=4;
		sloupec=2;		
		str2ram (StringBuffer, " podsvícení TL.      ");
		if (PolozkaMenu==2){
				StringBuffer[0]=0x06;
				StringBuffer[20]=0x07;
				PisMale(StringBuffer,1,1);
				ZobrazPosuvnik(PodsvetleniTlacitek,1,1);
		}else{
				PisMale(StringBuffer,0,0);
				ZobrazPosuvnik(PodsvetleniTlacitek,0,0);
		}

		// unsigned int ZtlumitPodsvetleni=5;	// po jaké dobì bez stisku klávesy ztlumit podsvìtlení 
		// (5s,10s,30s,1M,5M,nikdy)
		str2ram (StringBuffer, " zlumit pod.: ");

		str2ram (StringBuffer2, "po 10s ");
		if (ZtlumitPodsvetleni==0){
			str2ram (StringBuffer2, "po 5s  ");
		}
		if (ZtlumitPodsvetleni==2){
			StringBuffer2[3]='3';
		}
		if (ZtlumitPodsvetleni==3){
			StringBuffer2[4]='M';
			StringBuffer2[5]=' ';
		}
		if (ZtlumitPodsvetleni==4){
			StringBuffer2[3]='5';
			StringBuffer2[4]='M';
			StringBuffer2[5]=' ';
		}
		if (ZtlumitPodsvetleni==5){
			str2ram (StringBuffer2, "nikdy  ");
		}

		radek=5;
		sloupec=2;		
		if (PolozkaMenu==3){
				StringBuffer[0]=0x06;
				PisMale(StringBuffer,1,1);
				StringBuffer2[6]=0x07;
				PisMale(StringBuffer2,1,1);
		}else{
				PisMale(StringBuffer,0,0);
				PisMale(StringBuffer2,0,0);
		}
	}

	ZmenaPolozky=0;
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void ZobrazPosuvnik(unsigned int Hodnota,unsigned char Pozadi,unsigned char Nadtrzeni){
	// zobrazi maly posuvnik na pet znaku v rozsahu 0..1024 (hodnota)
	unsigned char Dato;
	unsigned char i;

/*
	sloupec=104;		//posuvnik ma vzdy stejnou horiz. polohu...
	str2ram (StringBuffer, "\x08   \x09");		
	PisMale(StringBuffer,Pozadi,Nadtrzeni);
*/
	sloupec=100;
	NastavPozici();

	for (i=0; i<20; i++){		
		if (i==0 || i==19)
			Dato=0x7C;
		else{
			if (Hodnota>56){
				Dato=0x7C;
				Hodnota=Hodnota-56;
			}else{
				Dato=0x44;
			}
		}

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
	}	
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void NastavDobuDoStandBy(void){
	// VypinatDisk - po jaké dobì neèinosti (minuty) se má vypínat disk (5,10,15,30,60,nikdy)
	unsigned char a,b;
	WrUsart(0x0D);
	
	if (VypinatDisk==0){a=0x0B;b=0xB8;}
	if (VypinatDisk==1){a=0x17;b=0x70;}
	if (VypinatDisk==2){a=0x23;b=0x28;}
	if (VypinatDisk==3){a=0x46;b=0x50;}
	if (VypinatDisk==4){a=0x8C;b=0xA0;}
	if (VypinatDisk==5){a=0xFF;b=0xFF;}
		
	WrUsart(b);
	WrUsart(a);
	RdUsart();	
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
