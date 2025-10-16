;**********************************************************
;**********************************************************
;**********************************************************
; Obsahuje podrogramy realizujici zakladni aritmeticke operace
; pouzivane v mp3 preprcavaci. Vsechny operace se provadi 
; s 32bitovymi cisly.
; 
; Pro praci aritmetickych procedur je rezervovana BANKA 1 !!!!!
;**********************************************************
;**********************************************************
;**********************************************************
SOUCET
; provede soucet hodnoty v registrech OPERAND_X[1..4] 
; s hodnotou v OPERAND_Y[1..4] a umisti do VYSLEDEK[1..4] 
; pokud dojde k preteceni, nastavi se PRETECENI do 1
; (byty s indexem 1 maji nejnizsi vahu)
	BANK_1
	clrf PRETECENI

	movfw OPERAND_X1
	addwf OPERAND_Y1,W
	movwf VYSLEDEK1
	btfsc STATUS,C
		bsf PRETECENI,1

	movfw OPERAND_X2
	addwf OPERAND_Y2,W
	movwf VYSLEDEK2
	btfsc STATUS,C
		bsf PRETECENI,0
	btfsc PRETECENI,1
		incf VYSLEDEK2,F
	btfsc STATUS,C
		bsf PRETECENI,0
	bcf PRETECENI,1

	movfw OPERAND_X3
	addwf OPERAND_Y3,W
	movwf VYSLEDEK3
	btfsc STATUS,C
		bsf PRETECENI,1
	btfsc PRETECENI,0
		incf VYSLEDEK3,F
	btfsc STATUS,C
		bsf PRETECENI,1
	bcf PRETECENI,0

	movfw OPERAND_X4
	addwf OPERAND_Y4,W
	movwf VYSLEDEK4
	btfsc STATUS,C
		bsf PRETECENI,0
	btfsc PRETECENI,1
		incf VYSLEDEK4,F
	btfsc STATUS,C
		bsf PRETECENI,0
	bcf PRETECENI,1	

	BANK_0
	return
;**********************************************************
;**********************************************************
ROZDIL	; VYSLEDEK := X - Y
		; pri podteceni PRETECENI = 1 ( VYSLEDEK < 0 => PRETECENI = 1 )
	BANK_1
	clrf PRETECENI

	movfw OPERAND_Y1
	subwf OPERAND_X1,W	; W = X - Y	
	movwf VYSLEDEK1
	btfss STATUS,C
		bsf PRETECENI,1
	
	movfw OPERAND_Y2
	subwf OPERAND_X2,W	; W = X - Y	
	movwf VYSLEDEK2
	btfss STATUS,C
		bsf PRETECENI,0
	btfsc PRETECENI,1
		decf VYSLEDEK2,F
	btfss STATUS,C
		bsf PRETECENI,0
	bcf PRETECENI,1	
	
	movfw OPERAND_Y3
	subwf OPERAND_X3,W	; W = X - Y	
	movwf VYSLEDEK3
	btfss STATUS,C
		bsf PRETECENI,1
	btfsc PRETECENI,0
		decf VYSLEDEK3,F
	btfss STATUS,C
		bsf PRETECENI,1
	bcf PRETECENI,0
	
	movfw OPERAND_Y4
	subwf OPERAND_X4,W	; W = X - Y	
	movwf VYSLEDEK4
	btfss STATUS,C
		bsf PRETECENI,0
	btfsc PRETECENI,1
		decf VYSLEDEK4,F
	btfss STATUS,C
		bsf PRETECENI,0
	bcf PRETECENI,1	
	
	BANK_0
	return
;**********************************************************
POSUNDOLEVA	; X := (X * 2) mod 0xFFFFFFFF , PRETECENI := (X * 2) div 0xFFFFFFFF
			; tento podprogram nepouzivat, primo v hlavnim programu
			; musi se nastavit BANK_1 a vymazat PRETECENI!!!
			; (je pouze pro pouziti v nasobicich podprogramech)
			; pouzivat jen POSUNDOLEVA_1, 2, 3, 4 
	rlf OPERAND_X1,F
	rlf OPERAND_X2,F
	rlf OPERAND_X3,F
	rlf OPERAND_X4,F
	rlf PRETECENI,F	
	return
;**********************************************************
POSUNDOLEVA_1	; X := X * 2
				; X > 0xFFFF FFFF => PRETECENI obsahuje bity navic
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
POSUNDOLEVA_2	; X := X * 4
				; X > 0xFFFF FFFF => PRETECENI obsahuje bity navic
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
POSUNDOLEVA_3	; X := X * 8
				; X > 0xFFFF FFFF => PRETECENI obsahuje bity navic
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
POSUNDOLEVA_4	; X := X * 16
				; X > 0xFFFF FFFF => PRETECENI obsahuje bity navic
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
POSUNDOLEVA_5	; X := X * 32
				; X > 0xFFFF FFFF => PRETECENI obsahuje bity navic
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
POSUNDOPRAVA	; X := X div 2 , PRETECENI := X mod 2
			; tento podprogram nepouzivat, primo v hlavnim programu
			; musi se nastavit BANK_1 a vymazat PRETECENI!!!
			; (je pouze pro pouziti v nasobicich podprogramech)
			; pouzivat jen POSUNDOPRAVA_1, 2, 3, 4 
	rrf OPERAND_X4,F
	rrf OPERAND_X3,F
	rrf OPERAND_X2,F
	rrf OPERAND_X1,F
	rrf PRETECENI,F	
	return
;**********************************************************
POSUNDOPRAVA_1	; X := X div 2
				; PRETECENI := X mod 2
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
POSUNDOPRAVA_2	; X := X div 4
				; PRETECENI := X mod 4
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
POSUNDOPRAVA_3	; X := X div 8
				; PRETECENI := X mod 8
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
POSUNDOPRAVA_4	; X := X div 16
				; PRETECENI := X mod 16
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
POSUNDOPRAVA_5	; X := X div 32
				; PRETECENI := X mod 32
	BANK_1
	clrf PRETECENI
	bcf STATUS,C
	
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA
	call POSUNDOLEVA

	BANK_0
	return
;**********************************************************
NULA	; if (X =  0) then PRETECENI := 0
		; if (X <> 0) then PRETECENI := 1
		; obsah X zustane nezmenen
	BANK_1
	clrf PRETECENI
	movlw h'FF'	

	andwf OPERAND_X1,F
	btfss STATUS,Z
		bsf PRETECENI,0
	andwf OPERAND_X2,F
	btfss STATUS,Z
		bsf PRETECENI,0
	andwf OPERAND_X3,F
	btfss STATUS,Z
		bsf PRETECENI,0
	andwf OPERAND_X4,F
	btfss STATUS,Z
		bsf PRETECENI,0		

	BANK_0
	return
;**********************************************************
