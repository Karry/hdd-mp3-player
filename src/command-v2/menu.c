void Menu(void){
	unsigned char ZmenaPolozky;
	#define Odsazeni 4;

	if (Flags.Bit.ZmenaObrazovky){
		SmazLcd();
		if (PolozkaMenu>3){	PolozkaMenu=0;}
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

		for (radek=1; radek<6; radek++){
			sloupec=Odsazeni;
			str2ram (StringBuffer, "\2                  \2");
			PisMale(StringBuffer,0,0);				
		}

		radek=6;
		sloupec=Odsazeni;
		str2ram (StringBuffer, "\x04\x14\x14\x14\x14\x14\x14\x14\x14\x14\x14\x14\x14\x14\x14\x14\x14\x14\x14\x05");
		PisMale(StringBuffer,0,0);				

		radek=0;
		sloupec=Odsazeni;
		NastavPozici();
		ZapisMalyZnak(0x01,0,0);
		str2ram (StringBuffer, " MENU:       ");
		PisVelke(StringBuffer,0,1,0);		

		sloupec=112;
		NastavPozici();
		ZapisMalyZnak(0x00,0,1);
		ZapisMalyZnak(0x03,0,0);

		// ted napisy nad tlacitky
		radek=7;
		sloupec=0;
		str2ram(StringBuffer, "\x11zpět\x12  \x12   \x12  \x12vyber\x13");
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
		Flags.Bit.ZmenaObrazovky=1;
		
		if (PolozkaMenu==0){
			Obrazovka=0x20;
		}
		if (PolozkaMenu==1){
			Obrazovka=0x40;
		}
		if (PolozkaMenu==2){
			Obrazovka=0x50;
		}
		if (PolozkaMenu==3){
			Obrazovka=0x60;
		}
		
	}
	if (Flags.Bit.TlLeft){
		Flags.Bit.TlLeft=0;
		Flags.Bit.ZmenaObrazovky=1;
		Obrazovka=0x10;
	}
	///////////////////////////////////////////////////

	if (ZmenaPolozky==1){
		radek=2;
		sloupec=10;		
		if (PolozkaMenu==0){
				str2ram (StringBuffer, "\x06výběr souboru   \x07");		
				PisMale(StringBuffer,1,1);
		}else{
				str2ram (StringBuffer, " výběr souboru    ");		
				PisMale(StringBuffer,0,0);
		}
		radek=3;
		sloupec=10;		
		if (PolozkaMenu==1){
				str2ram (StringBuffer, "\x06možn. přehrávání\x07");		
				PisMale(StringBuffer,1,1);
		}else{
				str2ram (StringBuffer, " možn. přehrávání ");		
				PisMale(StringBuffer,0,0);
		}
		radek=4;
		sloupec=10;		
		if (PolozkaMenu==2){
				str2ram (StringBuffer, "\x06nastavení       \x07");
				PisMale(StringBuffer,1,1);
		}else{
				str2ram (StringBuffer, " nastavení        ");
				PisMale(StringBuffer,0,0);
		}
		radek=5;
		sloupec=10;		
		if (PolozkaMenu==3){
				str2ram (StringBuffer, "\x06stand-by        \x07");		
				PisMale(StringBuffer,1,1);
		}else{
				str2ram (StringBuffer, " stand-by         ");		
				PisMale(StringBuffer,0,0);
		}
	}
	ZmenaPolozky=0;
}
