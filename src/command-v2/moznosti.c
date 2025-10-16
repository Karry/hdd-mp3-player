char desitky(unsigned char Hodnota,unsigned char nula);
char jednotky(unsigned char Hodnota);
char stovky(unsigned int Hodnota,unsigned char nula);
void NastavEkvalizer(void);
void NastavRezimPrehravani(void);
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void moznosti (void){
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
		str2ram (StringBuffer, "MOŽNOSTI PŘ.:");
		PisVelke(StringBuffer,0,0,0);
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
		
		if (PolozkaMenu==0){
			if (Ekvalizer==12){Ekvalizer=0;}
			else{Ekvalizer++;}
			NastavEkvalizer();		
		}
		if (PolozkaMenu==1){
			if (PREHSTAV1.Bit.ZvyraznitBasy){PREHSTAV1.Bit.ZvyraznitBasy=0;}
			else{PREHSTAV1.Bit.ZvyraznitBasy=1;}
			NastavStavPrehravani();
		}
		if (PolozkaMenu==2){
			if (PREHSTAV0.Bit.PrehravatPoSpusteni){PREHSTAV0.Bit.PrehravatPoSpusteni=0;}
			else{PREHSTAV0.Bit.PrehravatPoSpusteni=1;}
			NastavStavPrehravani();
		}
		if (PolozkaMenu==3){
			if (RezimPrehravani<4){RezimPrehravani++;}
			else{RezimPrehravani=0;}
			NastavRezimPrehravani();
		}
	}
	if (Flags.Bit.TlRight){
		Flags.Bit.TlRight=0;
		ZmenaPolozky=1;
		if (PolozkaMenu==0){
			if (Ekvalizer==0){Ekvalizer=12;}
			else{Ekvalizer--;}
			NastavEkvalizer();
		}
		if (PolozkaMenu==3){
			if (RezimPrehravani!=0){RezimPrehravani--;}
			else{RezimPrehravani=4;}
			NastavRezimPrehravani();
		}
	}

	if (Flags.Bit.TlLeft){
		Flags.Bit.TlLeft=0;
		Flags.Bit.ZmenaObrazovky=1;
		Obrazovka=0x30;
		PolozkaMenu=1;
		UlozKonfiguraci();		// ulozime si konfiguraci ridiciho modulu...
		
		WrUsart(0x87);				// ulozime stav prehravani i v prehravaci
		RdUsart();
	}
	///////////////////////////////////////////////////

	if (ZmenaPolozky==1){
		if (PolozkaMenu==1 || PolozkaMenu==2){
			str2ram(StringBuffer, "\x11zpět\x12  \x12  \x12  \x12změnit\x13");
		}else{
			str2ram(StringBuffer, "\x11zpět\x12   \x12   \x12 < \x12 > \x13");
		}
		radek=7;
		sloupec=0;
		PisMale(StringBuffer,1,0);		

		radek=2;
		sloupec=2;		
		str2ram (StringBuffer, " ekvalizér: ");
		str2ram (StringBuffer2, "         ");
		StringBuffer2[6]=desitky(Ekvalizer,' ');
		StringBuffer2[7]=jednotky(Ekvalizer);
		if (PolozkaMenu==0){
				StringBuffer[0]=0x06;
				StringBuffer2[8]=0x07;
				PisMale(StringBuffer,1,1);
				PisMale(StringBuffer2,1,1);
		}else{
				PisMale(StringBuffer,0,0);
				PisMale(StringBuffer2,0,0);
		}


		radek=3;
		sloupec=2;		
		str2ram (StringBuffer, " zvýraznění basů   \x15 ");
		if (PREHSTAV1.Bit.ZvyraznitBasy){StringBuffer[19]=0x16;}
		if (PolozkaMenu==1){
				StringBuffer[0]=0x06;
				StringBuffer[20]=0x07;
				PisMale(StringBuffer,1,1);
		}else{
				PisMale(StringBuffer,0,0);
		}

		radek=4;
		sloupec=2;		
		str2ram (StringBuffer, " přehrávat po zap. \x15 ");
		if (PREHSTAV0.Bit.PrehravatPoSpusteni){StringBuffer[19]=0x16;}
		if (PolozkaMenu==2){
				StringBuffer[0]=0x06;
				StringBuffer[20]=0x07;
				PisMale(StringBuffer,1,1);
		}else{
				PisMale(StringBuffer,0,0);
		}

		radek=5;
		sloupec=2;		
		str2ram (StringBuffer, " režim přehrávání    ");
		// unsigned char RezimPrehravani=0;		
		// 0=prohledávání, hrát porád dál; 1=přehrát složku; 2=repeat složky; 3=přehrát jednu; 4=repeat souboru		
		StringBuffer[18]=0x19;
		StringBuffer[19]=0x18;
		if (RezimPrehravani==0){
			StringBuffer[18]=0x1A;
			StringBuffer[19]=0x1B;
		}
		if (RezimPrehravani==2){
			StringBuffer[18]=0x17;
		}
		if (RezimPrehravani==3){
			StringBuffer[19]='1';
		}
		if (RezimPrehravani==4){
			StringBuffer[18]=0x17;
			StringBuffer[19]='1';
		}

		if (PolozkaMenu==3){
				StringBuffer[0]=0x06;
				StringBuffer[20]=0x07;
				PisMale(StringBuffer,1,1);
		}else{
				PisMale(StringBuffer,0,0);
		}

	}
	ZmenaPolozky=0;
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
char desitky(unsigned char Hodnota,unsigned char nula){
	// vratí číslici jako ASCII znak, která na pozici desítek... Pokud je nula, tak vrátí znak definovaný v nula
	unsigned char pomocna;
	pomocna=Hodnota / 10;
	if (pomocna>9){pomocna=pomocna-10;}
	if (pomocna>9){pomocna=pomocna-10;}
	if (pomocna==0){return nula;}
	else{return (pomocna+48);}	// 48 je ASCII hodnota 0
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
char stovky(unsigned int Hodnota,unsigned char nula){
	// vratí číslici jako ASCII znak, která na pozici desítek... Pokud je nula, tak vrátí znak definovaný v nula
	unsigned int pomocna;
	pomocna=Hodnota / 100;
	if (pomocna==0){return nula;}
	else{return (pomocna+48);}	// 48 je ASCII hodnota 0
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
char jednotky(unsigned char Hodnota){
  return (Hodnota-((Hodnota/10)*10))+48;	// 48 je ASCII hodnota 0
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void NastavEkvalizer(void){
	WrUsart(0x85);
	WrUsart(Ekvalizer);
	RdUsart();	
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void NastavRezimPrehravani(void){
 	// RezimPrehravani - 0=prohledávání, hrát porád dál; 1=přehrát složku; 2=repeat složky; 3=přehrát jednu; 4=repeat souboru	
 	if (RezimPrehravani==0){							// 0=prohledávání, hrát porád dál
		PREHSTAV0.Bit.NeprehravatDal=0;
		PREHSTAV0.Bit.Repeat=0;
		//PREHSTAV0.Bit.RepeatSouboru=0;
		PREHSTAV0.Bit.ProhledavatAdresare=1;
	}
 	if (RezimPrehravani==1){							//  1=přehrát složku
		PREHSTAV0.Bit.NeprehravatDal=0;
		PREHSTAV0.Bit.Repeat=0;
		//PREHSTAV0.Bit.RepeatSouboru=0;
		PREHSTAV0.Bit.ProhledavatAdresare=0;
	}
 	if (RezimPrehravani==2){							//  2=repeat složky
		PREHSTAV0.Bit.NeprehravatDal=0;
		PREHSTAV0.Bit.Repeat=1;
		PREHSTAV0.Bit.RepeatSouboru=0;
		//PREHSTAV0.Bit.ProhledavatAdresare=0;
	}
 	if (RezimPrehravani==3){							// 3=přehrát jednu
		PREHSTAV0.Bit.NeprehravatDal=1;
		//PREHSTAV0.Bit.Repeat=0;
		//PREHSTAV0.Bit.RepeatSouboru=0;
		//PREHSTAV0.Bit.ProhledavatAdresare=1;
	}
 	if (RezimPrehravani==4){							// 4=repeat souboru	
		PREHSTAV0.Bit.NeprehravatDal=0;
		PREHSTAV0.Bit.Repeat=1;
		PREHSTAV0.Bit.RepeatSouboru=1;
		//PREHSTAV0.Bit.ProhledavatAdresare=1;
	}
 	NastavStavPrehravani();
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
