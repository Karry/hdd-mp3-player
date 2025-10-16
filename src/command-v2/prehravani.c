////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void Prehravani(void){
	unsigned char ZmenaPolozky,minuty,vteriny,dato,i;
	char ram Buffer[6];
	#define Odsazeni 4;

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	if (Flags.Bit.ZmenaObrazovky){
		SmazLcd();

		Flags.Bit.TlVolUp		=0;
		Flags.Bit.TlVolDown	=0;
		Flags.Bit.TlUp			=0;
		Flags.Bit.TlDown		=0;
		Flags.Bit.TlLeft		=0;
		Flags.Bit.TlPlay		=0;
		Flags.Bit.TlStop		=0;
		Flags.Bit.TlRight		=0;
		Flags.Bit.TlMenu		=0;

		ZobrazenyCas=0xFFFF;
		PoziceSouboru=PoziceAdresare=0xFF;
		Flags.Bit.ZmenaHlasitosti=1;
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	// pokazde si v teto funkci zjistim informace o prehravanem souboru...
	WrUsart(0x83);
	AUDATA[0]=RdUsart();
	AUDATA[1]=RdUsart();
	HDAT0[0]=RdUsart();
	HDAT0[1]=RdUsart();
	HDAT1[0]=RdUsart();
	HDAT1[1]=RdUsart();

  LbaPrehrAdresare[0]=RdUsart();
  LbaPrehrAdresare[1]=RdUsart();
  LbaPrehrAdresare[2]=RdUsart();
  LbaPrehrAdresare[3]=RdUsart();
	ZazPrehrSouboru[0]=RdUsart();
	ZazPrehrSouboru[1]=RdUsart();	

	if (Flags.Bit.ZmenaObrazovky || PREHSTAV0.Bit.ZmenenSoubor ){
		// pokud se zmìnila obrazovka, nebo pokud se právì automaticky zmìnil pøehrávaný soubor, 
		// naèteme si jméno pøehrávaného souboru a adresáøe pro zobrazování na lcd...
		Flags.Bit.ZmenaObrazovky=0;
		
		PrehravanySoubor[65]=0;
		PrehravanyAdresar[65]=0;	// pokud je nazev dlouhty nebo delsi jak 65 znaku tak tato nula slouzi jako konec retezce		

		if (PREHSTAV0.Bit.JeSoubor && (!Flags.Bit.Stop)){
			WrUsart(0x0A);
  	  WrUsart(LbaPrehrAdresare[0]);
	    WrUsart(LbaPrehrAdresare[1]);
  	  WrUsart(LbaPrehrAdresare[2]);
    	WrUsart(LbaPrehrAdresare[3]);
	    WrUsart(ZazPrehrSouboru[0]);
  	  WrUsart(ZazPrehrSouboru[1]);

			RdUsart();
			for (i=0; i<65; i++){
				PrehravanySoubor[i]=RdUsart();
			}
			if (PrehravanySoubor[0]==0){
				WrUsart(0x05);
  		  WrUsart(LbaPrehrAdresare[0]);
    		WrUsart(LbaPrehrAdresare[1]);
		    WrUsart(LbaPrehrAdresare[2]);
  		  WrUsart(LbaPrehrAdresare[3]);
    		WrUsart(ZazPrehrSouboru[0]);
	    	WrUsart(ZazPrehrSouboru[1]);
				RdUsart();
				for (i=0; i<8; i++){
					PrehravanySoubor[i]=RdUsart();
				}						
				PrehravanySoubor[8]='.';
				PrehravanySoubor[9]=RdUsart();
				PrehravanySoubor[10]=RdUsart();
				PrehravanySoubor[11]=RdUsart();
				PrehravanySoubor[12]=0;
				RdUsart();
				RdUsart();
				RdUsart();
				RdUsart();
			}
		}else{
			str2ram (PrehravanySoubor, "---");
		}


		WrUsart(0x0C);
 	  WrUsart(LbaPrehrAdresare[0]);
    WrUsart(LbaPrehrAdresare[1]);
 	  WrUsart(LbaPrehrAdresare[2]);
   	WrUsart(LbaPrehrAdresare[3]);
		dato=RdUsart();
		for (i=0; i<6; i++){
			Buffer[i]=RdUsart();
		}
		if (dato==0x01){
			str2ram (PrehravanyAdresar, "ROOT");
		}else{
			WrUsart(0x0A);
  	  WrUsart(Buffer[0]);
	    WrUsart(Buffer[1]);
  	  WrUsart(Buffer[2]);
    	WrUsart(Buffer[3]);
	    WrUsart(Buffer[4]);
  	  WrUsart(Buffer[5]);

			RdUsart();
			for (i=0; i<65; i++){
				PrehravanyAdresar[i]=RdUsart();
			}
			if (PrehravanyAdresar[0]==0){
				WrUsart(0x05);
  		  WrUsart(Buffer[0]);
	 	  	WrUsart(Buffer[1]);
  	  	WrUsart(Buffer[2]);
    		WrUsart(Buffer[3]);
		    WrUsart(Buffer[4]);
	  	  WrUsart(Buffer[5]);
				RdUsart();
				for (i=0; i<8; i++){
					PrehravanyAdresar[i]=RdUsart();
				}						
				PrehravanyAdresar[8]=' ';
				PrehravanyAdresar[9]=RdUsart();
				PrehravanyAdresar[10]=RdUsart();
				PrehravanyAdresar[11]=RdUsart();
				PrehravanyAdresar[12]=0;
				RdUsart();
				RdUsart();
				RdUsart();
				RdUsart();
			}
		}		
	Flags.Bit.Rolovat=1;
	CitacRolovani=RychlostRolovani;
	PoziceSouboru=PoziceAdresare=0xFF;
	}

	//vypiseme na lcd prehravany adresar a soubor
	if (Flags.Bit.Rolovat==1){
		if (!PREHSTAV0.Bit.JeSoubor){str2ram(PrehravanySoubor, "---");}
		
		sloupec=0;
		i=strlen(PrehravanyAdresar);
		dato=0;
		if (i>16){
			if (PoziceAdresare!=0xFF){dato=PoziceAdresare;}
			if (PoziceAdresare==i){PoziceAdresare=0xFF;
			}else{PoziceAdresare++;}
		}
		radek=0;
		NastavPozici();
		for (k=0;(k<16)&&(k+dato<i);k++){
			ZapisVelkyZnak(PrehravanyAdresar[k+dato],0,0,0);				
		}
		while(sloupec<127){
			ZapisVelkyZnak(' ',0,0,0);
		}

		i=strlen(PrehravanySoubor);
		dato=0;
		if (i>16){
			if (PoziceSouboru!=0xFF){dato=PoziceSouboru;}
			if (PoziceSouboru==i){PoziceSouboru=0xFF;
			}else{PoziceSouboru++;}
		}
		radek=2;
		sloupec=0;
		NastavPozici();
		for (k=0;(k<16)&&(k+dato<i);k++){
			ZapisVelkyZnak(PrehravanySoubor[k+dato],0,0,1);				
		}
		while(sloupec<127){
			ZapisVelkyZnak(' ',0,0,1);
		}
		
		// ted napissi text nad tlacitky
		radek=7;
		sloupec=0;
		PisMaleConst("\x11 \x08 \x12\x09/\x0A\x12 \x0B \x12\x0C/\x0D\x12menu\x13",1,0);		
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	if (Flags.Bit.TlUp || Flags.Bit.TlDown){
		Flags.Bit.TlUp=0;
		Flags.Bit.TlDown=0;
		Obrazovka=0x20;
		Flags.Bit.ZmenaObrazovky=1;		
	}
	if (Flags.Bit.TlStop){
		Flags.Bit.TlStop=0;
		Flags.Bit.Stop=1;
		PREHSTAV0.Bit.Play=0;
		NastavStavPrehravani();
		str2ram (PrehravanySoubor, "---");
	}
	if (Flags.Bit.TlPlay){
		Flags.Bit.TlPlay=0;
		if (Flags.Bit.Stop){
			Flags.Bit.Stop=0;
			Flags.Bit.ZmenaObrazovky=1;
			WrUsart(0x80);
			WrUsart(LbaPrehrAdresare[0]);
			WrUsart(LbaPrehrAdresare[1]);
			WrUsart(LbaPrehrAdresare[2]);
			WrUsart(LbaPrehrAdresare[3]);
			WrUsart(ZazPrehrSouboru[0]);
			WrUsart(ZazPrehrSouboru[1]);
			RdUsart();
		}else{
			PREHSTAV0.Bit.Play=!PREHSTAV0.Bit.Play;
			NastavStavPrehravani();
		}
	}
	if (Flags.Bit.TlMenu){
		Flags.Bit.TlMenu=0;
		PolozkaMenu=0;
		Flags.Bit.ZmenaObrazovky=1;		
		Obrazovka=0x30;	
	}
	if (Flags.Bit.TlUp || Flags.Bit.TlDown){
		Flags.Bit.TlUp=Flags.Bit.TlDown=0;
		Flags.Bit.ZmenaObrazovky=1;		
		Obrazovka=0x20;	
	}
	
	if (Flags.Bit.TlRight && ATlRight){
		Delay10KTCYx(40);	// 80ms = 400 000 instrukci
		if (ATlRight){
			Flags.Bit.TlRight=0;
			PREHSTAV1.Bit.PrevijetMp3=1;
			PREHSTAV1.Bit.PrevijetPomalu=1;
			NastavStavPrehravani();
			TrvaniPomalehoPrevijeni=0;
		}
	}
	if (PREHSTAV1.Bit.PrevijetMp3 && (!ATlRight)){
		PREHSTAV1.Bit.PrevijetMp3=0;
		NastavStavPrehravani();
	}	
	
	
	if (Flags.Bit.TlRight || Flags.Bit.TlLeft){
		WrUsart(0x09);
		WrUsart(LbaPrehrAdresare[0]);
		WrUsart(LbaPrehrAdresare[1]);
		WrUsart(LbaPrehrAdresare[2]);
		WrUsart(LbaPrehrAdresare[3]);
		WrUsart(ZazPrehrSouboru[0]);
		WrUsart(ZazPrehrSouboru[1]);

		if (Flags.Bit.TlRight){
			WrUsart(0x26);
		}else{
			WrUsart(0x36);
		}
		
		Flags.Bit.TlRight=0;
		Flags.Bit.TlLeft=0;
		
		dato=RdUsart();
		for (i=0;i<15;i++){
			RdUsart();
		}
		Buffer[0]=RdUsart();
		Buffer[1]=RdUsart();
		
		if (dato==0x06){
			WrUsart(0x80);
			WrUsart(LbaPrehrAdresare[0]);
			WrUsart(LbaPrehrAdresare[1]);
			WrUsart(LbaPrehrAdresare[2]);
			WrUsart(LbaPrehrAdresare[3]);
			WrUsart(Buffer[0]);
			WrUsart(Buffer[1]);
			RdUsart();
			
			Flags.Bit.ZmenaObrazovky=1;
			Flags.Bit.Stop=0;			
		}
	}
	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////
	if (Flags.Bit.ZmenaHlasitosti){
		Flags.Bit.ZmenaHlasitosti=0;

		if (PREHSTAV1.Bit.Mute){
			radek=5;
			sloupec=103;
			PisVelkeConst("\x13\x14  ",0,0,0);
		}else{
			//dolni pulka
			radek=6;
			sloupec=103;
 			NastavPozici();
 			for (i=0; i<245; i=i+10){
		 		dato=0x20;
	 			if (i<Hlasitost){
			 		if (i>25){dato=0x30;}
			 		if (i>50){dato=0x38;}
			 		if (i>75){dato=0x3C;}
		 			if (i>100){dato=0x3E;}
		 			if (i>125){dato=0x3F;}
				}
				ZapisD(dato);
	 		}
		 	//horni pulka
			radek=5;
			sloupec=103;
			PisMaleConst("\x7F\x80",0,0);
 			//NastavPozici();
 			for (i=120; i<245; i=i+10){
		 		dato=0x00;
		 		if (i<Hlasitost){
			 		if (i>145){dato=0x80;}
			 		if (i>170){dato=0xC0;}
		 			if (i>195){dato=0xE0;}
		 			if (i>220){dato=0xF0;}
			 		if (i>245){dato=0xF8;}
				}
				ZapisD(dato);
	 		}
	 	}
	}

	///////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////

	if (ZobrazenyCas!=Cas.Odehrany || (((!PREHSTAV0.Bit.JeSoubor)||(!PREHSTAV0.Bit.Play))&&(Flags.Bit.Rolovat))){
		// vypis informaci o mp3
		radek=4;
		sloupec=0;		
		if (PREHSTAV0.Bit.JeSoubor && (!Flags.Bit.Stop)){
			dato=HDAT0[0] & 0xC0;
			if (dato==0x00){PisMaleConst("  STEREO ",0,0);}
			if (dato==0x40){PisMaleConst("J-STEREO ",0,0);}
			if (dato==0x80){PisMaleConst("DUAL CH. ",0,0);}
			if (dato==0xC0){PisMaleConst("    MONO ",0,0);}
			
			bitrate=AUDATA[0]+((AUDATA[1] & 0x01)*256);
			StringBuffer[0]=stovky(bitrate,' ');
			StringBuffer[1]=desitky(bitrate,'0');
			StringBuffer[2]=jednotky(bitrate);
			StringBuffer[3]='k';	// 0x1C
			StringBuffer[4]='b';	// 0x1D
			StringBuffer[5]='/';
			StringBuffer[6]=0x00;
			PisMale(StringBuffer,0,0);
			
			dato=AUDATA[1] & 0x1E;
			if (dato==0x00){PisMaleConst("???",0,0);}
			if (dato==0x02){PisMaleConst("44.1",0,0);}
			if (dato==0x04){PisMaleConst("48",0,0);}
			if (dato==0x06){PisMaleConst("32",0,0);}
			if (dato==0x08){PisMaleConst("22",0,0);}
			if (dato==0x0A){PisMaleConst("24",0,0);}
			if (dato==0x0C){PisMaleConst("16",0,0);}
			if (dato==0x0E){PisMaleConst("11",0,0);}
			if (dato==0x10){PisMaleConst("12",0,0);}
			if (dato==0x12){PisMaleConst("8",0,0);}
			PisMaleConst("\x1E\x1F",0,0);
			
		}else{
			SmazRadek();
		}
		///////////////////////////////////////////////////////////////////////////
		// zobrazeni rezimu prehravani
		// 0=prohledávání, hrát porád dál; 1=pøehrát složku; 2=repeat složky; 3=pøehrát jednu; 4=repeat souboru		
		StringBuffer[0]=0x10;
		StringBuffer[1]=0x0F;
		StringBuffer[2]=0x00;		
		if (RezimPrehravani==0){
			StringBuffer[0]=0x11;
			StringBuffer[1]=0x12;
		}
		if (RezimPrehravani==2){
			StringBuffer[0]=0x0E;
		}
		if (RezimPrehravani==3){
			StringBuffer[1]='1';
		}
		if (RezimPrehravani==4){
			StringBuffer[0]=0x0E;
			StringBuffer[1]='1';
		}
		radek=5;
		sloupec=64;
		PisVelke(StringBuffer,0,0,0);

		///////////////////////////////////////////////////////////////////////////
		// zobrazeni casu
		radek=5;
		sloupec=3;
		//ted tady vyresime to, aby se prvnich 30s previjelo pomalu a potom rychle
		if (PREHSTAV1.Bit.PrevijetMp3 && PREHSTAV1.Bit.PrevijetPomalu){
			TrvaniPomalehoPrevijeni++;
			if (TrvaniPomalehoPrevijeni==30){
				PREHSTAV1.Bit.PrevijetPomalu=0;
				NastavStavPrehravani();				
			}
		}

		if (PREHSTAV0.Bit.JeSoubor && (!Flags.Bit.Stop)){
			if ((!PREHSTAV0.Bit.Play) && (!Flags.Bit.ZobrazitCas)){
				PisVelkeConst("   \x0A  ",0,0,0);
			}else{
				NastavPozici();
				ZobrazenyCas=Cas.Odehrany;

				minuty=Cas.Odehrany/60;
				vteriny=Cas.Odehrany-(minuty*60);
				dato=minuty/100;
				if (dato!=0){
						ZapisVelkyZnak(dato,0,0,0);
				}else{ZapisVelkyZnak(' ',0,0,0);}

				minuty=minuty-(dato*100);
				ZapisVelkyZnak((dato=minuty / 10),0,0,0);
				ZapisVelkyZnak((minuty-(dato*10)),0,0,0);
				ZapisVelkyZnak(0x0A,0,0,0);

				ZapisVelkyZnak((dato=vteriny / 10),0,0,0);
				ZapisVelkyZnak((vteriny-(dato*10)),0,0,0);
			}
		}else{
			PisVelkeConst(" \x0B\x0B\x0A\x0B\x0B",0,0,0);
		}
	}
	Flags.Bit.Rolovat=0;
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
