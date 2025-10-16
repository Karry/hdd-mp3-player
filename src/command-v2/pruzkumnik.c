unsigned char NactiZaznam(unsigned char Kam, unsigned char Prvni, unsigned char Nasledujici){
	// pokusí se načíst údaje o záznamu (nasledujiciho/predchazejiciho za/pred nejakym zaznamem v bufferu)
	// do BufferSouboru a AdresySouboru na pozici "Kam"
	// pokud takový záznam exisuje, vrátí 1, pokud ne, vrátí 0
	unsigned char Referencni,dato,i;
	
	WrUsart(0x09);
	WrUsart(LbaAktualnihoAdresare[0]);
	WrUsart(LbaAktualnihoAdresare[1]);
	WrUsart(LbaAktualnihoAdresare[2]);
	WrUsart(LbaAktualnihoAdresare[3]);

	if (Prvni==1){
		WrUsart(0x00);
		WrUsart(0x00);
		WrUsart(0x08);
	}else{
		if (Nasledujici==1){ Referencni=Kam-1; }
		else{ Referencni=Kam+1; }
		WrUsart(AdresySouboru[Referencni][5]);
		WrUsart(AdresySouboru[Referencni][6]);
		if (Nasledujici){ WrUsart(0x00); }
		else{ WrUsart(0x10); }
	}
	
	dato=RdUsart();
	if (dato==0x00 || dato==0x81){
		AdresySouboru[Kam][0]=0;
		BufferSouboru[Kam][0]=0;
		for (i=0;i<17;i++){RdUsart();}
		return 0;
	}else{
		for (i=0; i<8; i++){
			BufferSouboru[Kam][i]=RdUsart();
		}						
		if (dato==0x01){BufferSouboru[Kam][8]=' ';
		}else{BufferSouboru[Kam][8]='.';}
		
		BufferSouboru[Kam][9]=RdUsart();
		BufferSouboru[Kam][10]=RdUsart();
		BufferSouboru[Kam][11]=RdUsart();
		for (i=12;i<18;i++){BufferSouboru[Kam][i]=0x20;}
		BufferSouboru[Kam][18]=0;
		AdresySouboru[Kam][0]=dato;
		AdresySouboru[Kam][1]=RdUsart();
		AdresySouboru[Kam][2]=RdUsart();
		AdresySouboru[Kam][3]=RdUsart();
		AdresySouboru[Kam][4]=RdUsart();
		AdresySouboru[Kam][5]=RdUsart();
		AdresySouboru[Kam][6]=RdUsart();
		
		WrUsart(0x0A);
		WrUsart(LbaAktualnihoAdresare[0]);
		WrUsart(LbaAktualnihoAdresare[1]);
		WrUsart(LbaAktualnihoAdresare[2]);
		WrUsart(LbaAktualnihoAdresare[3]);
		WrUsart(AdresySouboru[Kam][5]);
		WrUsart(AdresySouboru[Kam][6]);
		
		RdUsart();
		dato=RdUsart();
		if (dato==0x00){
			for (i=0; i<64;i++){
				RdUsart();
			}			
		}else{
			BufferSouboru[Kam][0]=dato;
			for (i=1; i<18;i++){
				dato=RdUsart();
				if (dato==0x00 || dato==0xFF ){
					dato=' ';
				}
				BufferSouboru[Kam][i]=dato;
			}
			BufferSouboru[Kam][18]=0;
			for (i=0; i<47;i++){
				RdUsart();
			}			
		}
		
		return 0x01;
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
unsigned char NactiDanyZaznam(unsigned char Kam,unsigned char Zaznam0,unsigned char Zaznam1){
	// pokusí se načíst údaje o konkrétním záznamu do BufferSouboru a AdresySouboru na pozici "Kam"
	// pokud takový záznam exisuje, vrátí 1, pokud ne, vrátí 0
	unsigned char dato,i;

	WrUsart(0x05);
	WrUsart(LbaAktualnihoAdresare[0]);
	WrUsart(LbaAktualnihoAdresare[1]);
	WrUsart(LbaAktualnihoAdresare[2]);
	WrUsart(LbaAktualnihoAdresare[3]);
	WrUsart(Zaznam0);
	WrUsart(Zaznam1);

	dato=RdUsart();
	if (dato==0x00 || dato==0x80 || dato==0x81){
		AdresySouboru[Kam][0]=0;
		BufferSouboru[Kam][0]=0;
		for (i=0;i<15;i++){RdUsart();}
		return 0;
	}else{
		for (i=0; i<8; i++){
			BufferSouboru[Kam][i]=RdUsart();
		}						
		if (dato==0x01){BufferSouboru[Kam][8]=' ';
		}else{BufferSouboru[Kam][8]='.';}
		
		BufferSouboru[Kam][9]=RdUsart();
		BufferSouboru[Kam][10]=RdUsart();
		BufferSouboru[Kam][11]=RdUsart();
		for (i=12;i<18;i++){BufferSouboru[Kam][i]=0x20;}
		BufferSouboru[Kam][18]=0;
		AdresySouboru[Kam][0]=dato;
		AdresySouboru[Kam][1]=RdUsart();
		AdresySouboru[Kam][2]=RdUsart();
		AdresySouboru[Kam][3]=RdUsart();
		AdresySouboru[Kam][4]=RdUsart();
		AdresySouboru[Kam][5]=Zaznam0;
		AdresySouboru[Kam][6]=Zaznam1;
		
		WrUsart(0x0A);
		WrUsart(LbaAktualnihoAdresare[0]);
		WrUsart(LbaAktualnihoAdresare[1]);
		WrUsart(LbaAktualnihoAdresare[2]);
		WrUsart(LbaAktualnihoAdresare[3]);
		WrUsart(AdresySouboru[Kam][5]);
		WrUsart(AdresySouboru[Kam][6]);
		
		RdUsart();
		dato=RdUsart();
		if (dato==0x00){
			for (i=0; i<64;i++){
				RdUsart();
			}			
		}else{
			BufferSouboru[Kam][0]=dato;
			for (i=1; i<18;i++){
				dato=RdUsart();
				if (dato==0x00 || dato==0xFF ){
					dato=' ';
				}
				BufferSouboru[Kam][i]=dato;
			}
			BufferSouboru[Kam][18]=0;
			for (i=0; i<47;i++){
				RdUsart();
			}			
		}
		return 0x01;
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void PosunNahoru(void){
	unsigned char i,k;
	for (i=0; i<(BufferSize-1);i++){
		for (k=0;k<19;k++){
			BufferSouboru[i][k]=BufferSouboru[i+1][k];
		}
		for (k=0;k<7;k++){
			AdresySouboru[i][k]=AdresySouboru[i+1][k];
		}
	}
	AdresySouboru[BufferSize][0]=0;
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void PosunDolu(void){
	unsigned char i,k;
	for (i=(BufferSize-1); i>0;i--){
		for (k=0;k<19;k++){
			BufferSouboru[i][k]=BufferSouboru[i-1][k];
		}
		for (k=0;k<7;k++){
			AdresySouboru[i][k]=AdresySouboru[i-1][k];
		}
	}
	AdresySouboru[0][0]=0;
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void OAdresarVis(void){
		WrUsart(0x0C);					// zjisti zaznam o aktualnim v nadrazenem adresari
 	  WrUsart(LbaAktualnihoAdresare[0]);
    WrUsart(LbaAktualnihoAdresare[1]);
 	  WrUsart(LbaAktualnihoAdresare[2]);
   	WrUsart(LbaAktualnihoAdresare[3]);
		if (RdUsart()==0){
			LbaAktualnihoAdresare[0]=RdUsart();
			LbaAktualnihoAdresare[1]=RdUsart();
			LbaAktualnihoAdresare[2]=RdUsart();
			LbaAktualnihoAdresare[3]=RdUsart();
			OznacitZaznam[0]=RdUsart();
			OznacitZaznam[1]=RdUsart();

			Flags2.Bit.ZmenenAdresar=1;
		}else{
			for (i=0; i<6; i++){
				RdUsart();
			}			
		}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void Pruzkumnik(void){
	unsigned char dato;
	char ram Buffer[6];
	
	if (Flags.Bit.ZmenaObrazovky){
		Flags.Bit.ZmenaObrazovky=0;

		Flags.Bit.TlVolUp		=0;
		Flags.Bit.TlVolDown	=0;
		Flags.Bit.TlUp			=0;
		Flags.Bit.TlDown		=0;
		Flags.Bit.TlLeft		=0;
		Flags.Bit.TlPlay		=0;
		Flags.Bit.TlStop		=0;
		Flags.Bit.TlRight		=0;
		Flags.Bit.TlMenu		=0;

		// zjistim si informace o prehravanem souboru (adresari)...
		WrUsart(0x83);
		RdUsart();
		RdUsart();
		RdUsart();
		RdUsart();
		RdUsart();
		RdUsart();
  	LbaAktualnihoAdresare[0]=RdUsart();
  	LbaAktualnihoAdresare[1]=RdUsart();
  	LbaAktualnihoAdresare[2]=RdUsart();
  	LbaAktualnihoAdresare[3]=RdUsart();
		OznacitZaznam[0]=RdUsart();
		OznacitZaznam[1]=RdUsart();	
		
		Flags2.Bit.ZmenenAdresar=1;
	}
	
	
	
	if (Flags2.Bit.ZmenenAdresar){		
		Flags2.Bit.ZmenenAdresar=0;
		
		SmazLcd();
		radek=3;
		sloupec=12;
		PisMaleConst("načítám adresář...",0,0);		
		
		Flags2.Bit.PlayPredStandBy=PREHSTAV0.Bit.Play;
		PREHSTAV0.Bit.Play=0;
		NastavStavPrehravani();		
		
		AktualniAdresar[15]=0;
		WrUsart(0x0C);
 	  WrUsart(LbaAktualnihoAdresare[0]);
    WrUsart(LbaAktualnihoAdresare[1]);
 	  WrUsart(LbaAktualnihoAdresare[2]);
   	WrUsart(LbaAktualnihoAdresare[3]);
		dato=RdUsart();
		for (i=0; i<6; i++){
			Buffer[i]=RdUsart();
		}
		if (dato==0x01){
			str2ram (AktualniAdresar, "ROOT");
		}else{
			WrUsart(0x0A);
  	  WrUsart(Buffer[0]);
	    WrUsart(Buffer[1]);
  	  WrUsart(Buffer[2]);
    	WrUsart(Buffer[3]);
	    WrUsart(Buffer[4]);
  	  WrUsart(Buffer[5]);

			RdUsart();
			for (i=0; i<15; i++){
				AktualniAdresar[i]=RdUsart();
			}
			for (i=0; i<50; i++){ RdUsart(); }
			if (AktualniAdresar[0]==0){
				WrUsart(0x05);
  		  WrUsart(Buffer[0]);
	 	  	WrUsart(Buffer[1]);
  	  	WrUsart(Buffer[2]);
    		WrUsart(Buffer[3]);
		    WrUsart(Buffer[4]);
	  	  WrUsart(Buffer[5]);
				RdUsart();
				for (i=0; i<8; i++){
					AktualniAdresar[i]=RdUsart();
				}						
				AktualniAdresar[8]=' ';
				AktualniAdresar[9]=RdUsart();
				AktualniAdresar[10]=RdUsart();
				AktualniAdresar[11]=RdUsart();
				AktualniAdresar[12]=0;
				RdUsart();
				RdUsart();
				RdUsart();
				RdUsart();
			}
		}
		
		radek=0;
		sloupec=0;
		PisVelkeConst("\x0C\x0D",0,0,0);
		sloupec=18;
		PisVelke(AktualniAdresar,0,0,0);
		
		// ted napisy nad tlacitky
		radek=7;
		sloupec=0;
		str2ram(StringBuffer, "\x11zpět\x12..\x12oddíl\x12\x12vyber\x13");
		PisMale(StringBuffer,1,0);				
		
		// ted nactu do bufferu informace o zaznamech v adresari
		PrvniZobrazeny=Vybrany=0;
		for (i=0;i<BufferSize;i++){
			AdresySouboru[i][0]=0;
		}

		if (NactiDanyZaznam(0,OznacitZaznam[0],OznacitZaznam[1])==1){	// nejdrive se pokusime dat na prvni misto pozadovany zaznam
			i=1;
			while ((i<BufferSize) && (NactiZaznam(i,0,1)==1)){i++;}			
		}else{												// pokud se to ale nepovede, dame na prni misto prvni zaznam
			if (NactiZaznam(0,1,0)==1){
				i=1;
				while ((i<BufferSize) && (NactiZaznam(i,0,1)==1)){i++;}
			}
		}
		radek=3;
		sloupec=12;
		PisMaleConst("                  ",0,0);		
		
		PREHSTAV0.Bit.Play=Flags2.Bit.PlayPredStandBy;
		NastavStavPrehravani();	

		Flags2.Bit.ZmenenVybZaznam=1;
	}
	
	if (Flags2.Bit.ZmenenVybZaznam){
		Flags2.Bit.ZmenenVybZaznam=0;
		i=PrvniZobrazeny;
		for (radek=2;radek<7;radek++){
			if (AdresySouboru[i][0]!=0x00){
				sloupec=0;
				if (i==Vybrany){
					if (AdresySouboru[i][0]==0x01){
						PisMaleConst("\x06\x0F",1,1);
					}else{
						PisMaleConst("\x06\x0E",1,1);					
					}
					PisMale(BufferSouboru[i],1,1);				
					PisMaleConst("\x07",1,1);
				}else{
					if (AdresySouboru[i][0]==0x01){
						PisMaleConst(" \x0F",0,0);
					}else{
						PisMaleConst(" \x0E",0,0);					
					}
					PisMale(BufferSouboru[i],0,0);
					PisMaleConst(" ",0,0);
				}
			i++;
			}
		}
	}
	
	if (Flags.Bit.TlStop){
		Flags.Bit.TlStop=0;
		Flags.Bit.ZmenaObrazovky=1;		
		Flags2.Bit.BylNactenyOddil=1;
		Obrazovka=0x01;
	}	

	if (ATlDown){
		Flags.Bit.TlDown=0;

		CitacRolovani=25;				// 25 * 5ms = 125ms (pri drzeni tlacitka se za vterinu posuneme o 8)
		Flags.Bit.Rolovat=0;

		if (Vybrany < (BufferSize-1)){
			Vybrany++;
			if (AdresySouboru[Vybrany][0]==0x00){
				Vybrany--;
			}else{
				Flags2.Bit.ZmenenVybZaznam=1;
				if ((Vybrany-PrvniZobrazeny)>4){
					PrvniZobrazeny++;
				}
			}
		}else{
			PosunNahoru();
			if (NactiZaznam((BufferSize-1),0,1)!=1){
				PrvniZobrazeny--;
				Vybrany--;
			}
			Flags2.Bit.ZmenenVybZaznam=1;
		}

		while(!Flags.Bit.Rolovat);
	}	
	
	if (ATlUp){
		Flags.Bit.TlUp=0;

		CitacRolovani=25;				// 25 * 5ms = 125ms (pri drzeni tlacitka se za vterinu posuneme o 8)
		Flags.Bit.Rolovat=0;
		
		if (Vybrany > 0){
			Vybrany--;
			if (AdresySouboru[Vybrany][0]==0x00){
				Vybrany++;
			}else{
				Flags2.Bit.ZmenenVybZaznam=1;
				if (PrvniZobrazeny>Vybrany){
					PrvniZobrazeny--;
				}
			}
		}else{
			PosunDolu();
			if (NactiZaznam(0,0,0)!=1){
				PrvniZobrazeny++;
				Vybrany++;
			}
			Flags2.Bit.ZmenenVybZaznam=1;
		}
		
		while(!Flags.Bit.Rolovat);
	}	
	
	if (Flags.Bit.TlMenu){
		Flags.Bit.TlMenu=0;
		if (AdresySouboru[Vybrany][0]==0x01){
			dato = LbaAktualnihoAdresare[0] | LbaAktualnihoAdresare[1];
			dato = dato | LbaAktualnihoAdresare[2];
			dato = dato | LbaAktualnihoAdresare[3];
			if ( (dato!=0) && (AdresySouboru[Vybrany][5]==0x01) &&	(AdresySouboru[Vybrany][6]==0x00)){
					// pokud aktualni adresar neni ROOT a byl vybran prni zaznam, znamena to, ze jdeme o adresar vis
					// slo by to udelat i jednoduseji, takhle ale budeme mit zjistenou hodnotu OznacitZaznam[]
				OAdresarVis();
			}else{
				Flags2.Bit.ZmenenAdresar=1;
				LbaAktualnihoAdresare[0]=AdresySouboru[Vybrany][1];
  			LbaAktualnihoAdresare[1]=AdresySouboru[Vybrany][2];
  			LbaAktualnihoAdresare[2]=AdresySouboru[Vybrany][3];
  			LbaAktualnihoAdresare[3]=AdresySouboru[Vybrany][4];
  			
  			OznacitZaznam[0]=1;
  			OznacitZaznam[1]=0;
  		}
		}else{
			WrUsart(0x80);
			WrUsart(LbaAktualnihoAdresare[0]);
			WrUsart(LbaAktualnihoAdresare[1]);
			WrUsart(LbaAktualnihoAdresare[2]);
			WrUsart(LbaAktualnihoAdresare[3]);
			WrUsart(AdresySouboru[Vybrany][5]);
			WrUsart(AdresySouboru[Vybrany][6]);
			RdUsart();
			Flags.Bit.ZmenaObrazovky=1;
			Flags.Bit.Stop=0;
			Obrazovka=0x10;
		}
	}	
	
	if (Flags.Bit.TlLeft){		
		Flags.Bit.TlLeft=0;
		Flags.Bit.ZmenaObrazovky=1;
		Obrazovka=0x10;
		PolozkaMenu=0;
	}	
	
	if (Flags.Bit.TlPlay){  // o adresar vys ".."
		Flags.Bit.TlPlay=0;
		OAdresarVis();		
	}
}
