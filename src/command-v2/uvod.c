void ZobrazLogo(void){
	unsigned int pozice;
	unsigned char Dato;
	radek=0;
	sloupec=0;
	NastavPozici();
	for (pozice=0xA00; pozice<0xC00; pozice++){
		if (pozice==0xA80 || pozice==0xB00 || pozice==0xB80){
			radek++;
			sloupec=0;
			NastavPozici();			
		}
		if (sloupec==64){
 			NastavPozici();
		}
		Dato=FontVelky[pozice];
		ZapisD(Dato);
  }
	radek=4;
	sloupec=0;
	NastavPozici();
  for (Dato=0;Dato<23;Dato++){
	  ZapisMalyZnak(' ',0,1);
	}
}
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
void CekejNaDisk(void){
	unsigned char dato,prijato,VlastnostiDisku;
	unsigned char buffer[40];

	ZobrazLogo();
	
	radek=5;
	sloupec=0;
	str2ram (StringBuffer, "èekám na disk...");
	PisMale(StringBuffer,0,0);				

	Delay10KTCYx(250);
	Delay10KTCYx(250);
	Delay10KTCYx(250);
	while( DataRdyUSART() ){
		WREG=RCREG;							// po zapnuti se obcas z nejakych zakmitu objevi v RX bufferu nejaky byte
	}													// timto jej ignorujeme...

	WrUsart( 0x01 );
	WrUsart( 0x01 );		// pro jistotu :)
/*
	WrUsart( 0x01 );
	WrUsart( 0x01 );
	WrUsart( 0x01 );
	WrUsart( 0x01 );
*/
	VlastnostiDisku=RdUsart();
	prijato=0;
	while(prijato<40){
		buffer[prijato]=RdUsart();
		prijato++;
	}

	str2ram (StringBuffer2, " ");
	if ((VlastnostiDisku & 0x80) == 0x80){
		if ((VlastnostiDisku & 0x04) == 0x04){ 
			str2ram (StringBuffer2, "OK, adresování LBA 48");
		}else{
			str2ram (StringBuffer2, "OK, adresování LBA 28");
		}
	}else{
		if ((VlastnostiDisku & 0x02) == 0x00){ 
			str2ram (StringBuffer2, "disk nepodporuje LBA");
		}		
		if ((VlastnostiDisku & 0x08) == 0x08){ 
			str2ram (StringBuffer2, "sektory vìtší 512B");
		}		
	}
	radek=6;
	sloupec=0;
	PisMale(StringBuffer2,0,0);

	radek=7;
	sloupec=0;
	NastavPozici();
	prijato=0;
	while(prijato<21){
		ZapisMalyZnak(buffer[prijato],0,0);		
		prijato++;
	}
	Delay10KTCYx(255);
	Delay10KTCYx(255);
	Delay10KTCYx(255);
	while ((VlastnostiDisku & 0x80) != 0x80);

	Flags.Bit.ZmenaObrazovky=1;		
	Obrazovka=0x01;
	Flags.Bit.NactenOddil=0;
}
