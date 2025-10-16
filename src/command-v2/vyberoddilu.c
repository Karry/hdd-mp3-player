void NastavPrehravac(void);
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void VyberOddilu(void){
	unsigned char ZmenaPolozky,dato;
	if (Flags.Bit.ZmenaObrazovky){
		VyprazdniBufferSouboru();
		SmazLcd();
		PocetOddilu=0;	
		i=0;		
		do{
			WrUsart(0x02);
			WrUsart(i);
			if (RdUsart()==0xFF){
				for (k=0; k<4; k++){
					AdresySouboru[PocetOddilu][k]=RdUsart();
				}
				for (k=0; k<11; k++){
					BufferSouboru[PocetOddilu][k]=RdUsart();
				}
				PocetOddilu++;
			}else{ for (k=0; k<15; k++){RdUsart();}	}	
			i++;		
		}while(i<4);
		

		if (PolozkaMenu>=PocetOddilu){	
			PolozkaMenu=0;
		}
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

		if (PocetOddilu==0){
			radek=0;
			sloupec=0;
			PisMaleConst("nenalezen žádný oddíl",0,0);
			radek=1;
			sloupec=0;
			PisMaleConst("typu FAT32",0,0);
			while(1);
		}else{
			radek=0;
			sloupec=0;
		
			if (PocetOddilu==1){
				dato = 0x10;
				if (!Flags2.Bit.BylNactenyOddil){
					WrUsart(0x03);
					for (i=0; i<4; i++){
						WrUsart(AdresySouboru[0][i]);
					}
					dato=RdUsart();
				}
				// zjistit, zda byl oddil korektne nacten....
				if ((dato & 0x10) == 0x10){
					Flags.Bit.ZmenaObrazovky=1;
					Flags.Bit.NactenOddil=1;					
					if (Flags2.Bit.BylNactenyOddil){
						PisMaleConst("pouze jeden oddíl...",0,0);						
						Obrazovka=0x20;
						Delay10KTCYx(255);
						Delay10KTCYx(255);
						Delay10KTCYx(255);
					}else{
						NastavPrehravac();
						Obrazovka=0x10;
					}
				}else{
					PisMaleConst("nepodaøilo se",0,0);
					radek=1;
					sloupec=0;
					PisMaleConst("nastavit oddíl",0,0);
					while(1);
				}
			}else{
				PisVelkeConst(" VYBER ODDÍL:",0,0,0);
				radek=7;
				sloupec=0;
				if (Flags2.Bit.BylNactenyOddil){
					PisMaleConst("\x11zpìt\x12  \x12   \x12  \x12vyber\x13",1,0);
				}else{
					PisMaleConst("\x11   \x12   \x12   \x12  \x12vyber\x13",1,0);
				}
			}
		}
	}
 if (PocetOddilu>1){
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
		if (PolozkaMenu<(PocetOddilu-1)){
			PolozkaMenu++;
			ZmenaPolozky=1;
		} 
	}
	
	if (Flags2.Bit.BylNactenyOddil && Flags.Bit.TlLeft){
		Flags.Bit.TlLeft=0;
		Flags.Bit.ZmenaObrazovky=1;
		Obrazovka=0x20;
	}
	
	if (Flags.Bit.TlMenu){
		Flags.Bit.TlMenu=0;
		Flags.Bit.ZmenaObrazovky=1;

				WrUsart(0x03);
				for (i=0; i<4; i++){
					WrUsart(AdresySouboru[PolozkaMenu][i]);
				}
				dato=RdUsart();
				// zjistit, zda byl oddil korektne nacten....
				if ((dato & 0x10) == 0x10){
					NastavPrehravac();
					if (Flags2.Bit.BylNactenyOddil){
						Obrazovka=0x20;
					}else{
						Obrazovka=0x10;
					}
					Flags.Bit.ZmenaObrazovky=1;
					Flags.Bit.NactenOddil=1;
				}else{
					SmazLcd();
					radek=1;
					sloupec=0;
					PisMaleConst("nepodaøilo se",0,0);
					radek=1;
					sloupec=0;
					PisMaleConst("nastavit oddíl",0,0);
					Delay10KTCYx(255);
					Delay10KTCYx(255);
				}		
	}
	///////////////////////////////////////////////////

	if (ZmenaPolozky==1){
		radek=2;
		for (i=0; i<PocetOddilu; i++){
			sloupec=10;
			NastavPozici();
			if (PolozkaMenu==i){
					ZapisMalyZnak(0x06,1,1);		
					for (k=0; k<12; k++){
						ZapisMalyZnak(BufferSouboru[i][k],1,1);
					}
					ZapisMalyZnak(0x07,1,1);		
			}else{
					ZapisMalyZnak(0x00,0,0);		
					for (k=0; k<12; k++){
						ZapisMalyZnak(BufferSouboru[i][k],0,0);
					}
					ZapisMalyZnak(0x00,0,0);
			}
			radek++;
		}

	}
	ZmenaPolozky=0;
 }
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void VyprazdniBufferSouboru(void){
	unsigned char i,k;
	for (i=0; i<BufferSize; i++){
		for (k=0; k<7; k++){
			AdresySouboru[i][k]=0;
		}
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void NastavPrehravac(void){
	// po nacteni oddilu nastavi prehravac podle hodnot ulozenych v pameti EEPROM
	WrUsart(0x86);
	RdUsart();
	i=RdUsart();
	Hlasitost=0xFF-i;	// protoze v dekoderu je 00 maximalni a 255 minimalni

	NastavEkvalizer();
	NastavDobuDoStandBy();
	NastartujOdpocet();
}
