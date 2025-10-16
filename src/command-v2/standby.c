void standby(void){
	if (Flags.Bit.ZmenaObrazovky){
		Flags.Bit.ZmenaObrazovky=0;
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

		radek=1;
		sloupec=32;
		str2ram (StringBuffer, "STAND-BY");
		PisVelke(StringBuffer,0,0,0);		

		radek=4;
		sloupec=20;
		str2ram (StringBuffer, "Stiskni cokoliv");
		PisMale(StringBuffer,0,0);		

		radek=5;
		sloupec=3;
		str2ram (StringBuffer, "     pro návrat     "); 
		PisMale(StringBuffer,0,0);		

		radek=6;
		sloupec=3;
		str2ram (StringBuffer, "    do přehrávání.   "); 
		PisMale(StringBuffer,0,0);		

		// tady se řeší nastavení pauzy a vypnutí disku
		Flags2.Bit.PlayPredStandBy=PREHSTAV0.Bit.Play;
		PREHSTAV0.Bit.Play=0;
		NastavStavPrehravani();
		WrUsart(0x0D);
		WrUsart(0);
		WrUsart(0);
		RdUsart();			
	}
	if (AktualniPodsvetleniTlacitek>1){
		AktualniPodsvetleniTlacitek--;
	}else{
		AktualniPodsvetleniTlacitek = 0;
	}
	if (AktualniPodsvetleniLCD>1){
			AktualniPodsvetleniLCD--;
	}else{
			AktualniPodsvetleniLCD = 0;
	}
	Delay10KTCYx(50);

	if (Flags.Bit.TlVolUp 
			|| Flags.Bit.TlVolDown 
			|| Flags.Bit.TlUp		
			|| Flags.Bit.TlDown	
			|| Flags.Bit.TlLeft	
			|| Flags.Bit.TlPlay	
			|| Flags.Bit.TlStop	
			|| Flags.Bit.TlRight
			|| Flags.Bit.TlMenu
	){
		Flags.Bit.TlVolUp		=0;
		Flags.Bit.TlVolDown	=0;
		Flags.Bit.TlUp			=0;
		Flags.Bit.TlDown		=0;
		Flags.Bit.TlLeft		=0;
		Flags.Bit.TlPlay		=0;
		Flags.Bit.TlStop		=0;
		Flags.Bit.TlRight		=0;
		Flags.Bit.TlMenu		=0;

		AktualniPodsvetleniTlacitek = PodsvetleniTlacitek;
		AktualniPodsvetleniLCD = PodsvetleniLCD;
		SetDCPWM2(AktualniPodsvetleniLCD);
		SetDCPWM1(AktualniPodsvetleniTlacitek);

		PREHSTAV0.Bit.Play=Flags2.Bit.PlayPredStandBy;
		NastavStavPrehravani();

		PolozkaMenu=3;
		Flags.Bit.ZmenaObrazovky=1;
		Obrazovka=0x10;	// jdi do prehravani
	}
}
