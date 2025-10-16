#pragma chip PIC16F877A


#pragma origin 0x005

/* assign names to port pins */
bit in  @ PORTB.0;
bit out @ PORTB.1;

//*********************************************************************
void prevod(void)
{
    uns16 pomocna;
    perioda = 60 / otacky;
}
//*********************************************************************
void main(){
  //if (TO == 1 && PD == 1 /* power up */)  {
  //  WARM_RESET:
  //  clearRAM(); // clear all RAM
  //}  
  uns16 i = 600;

  while (1){
	clrwdt();
	//sub();
    otacky = i;
    prevod();
    nop();
    i++;
  }
}
//*********************************************************************
