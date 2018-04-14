list p = 16f84a
#INCLUDE<P16F84A.INC>

__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_OFF & _XT_OSC

CBLOCK	0CH					; access GPRs start address at 0ch
	MIN_TENS				; place the value of tens of minute in this register
	MIN_ONES				; place the value of ones of minute in this register
	SEC_TENS				; place the value of tens of second in this register
	SEC_ONES				; place the value of ones of second in this register
	DELAY					; for 1 sec delay 
	DELAY2					; for 1 sec delay
	TEMP					; for testing if value of ones of second is zero
	count1					; fast delay for strobing
ENDC

VARIABLE ZERO = .0
VARIABLE NINE = .9
VARIABLE FIVE = .5
VARIABLE SET_DELAY2 = .24	; calibration for 1 sec delay
VARIABLE TEST_ZERO = 0FH	; value needed to test bit4 of TEMP
	
	ORG 00H
	GOTO START
		
START
	BSF STATUS, RP0			; bank0 to bank1 to access trisa & trisb
	CLRF TRISA				; all PORTA is output
	MOVLW 0x70			
	MOVWF TRISB				; RB6,RB5,RB4 are input, the rest: output
	BCF STATUS, RP0			; bank1 to bank0
	
INIT						; initialize display to 00:00
	MOVLW ZERO
	MOVWF MIN_TENS			; MIN_TENS = 0
	MOVWF MIN_ONES			; MIN_ONES = 0
	MOVWF SEC_TENS			; SEC_TENS = 0
	MOVWF SEC_ONES			; SEC_ONES = 0
			
MAIN						; main program
		CALL DISPLAY		; call display subroutine
		BTFSC PORTB,4		; if set minute button is pressed, skip nextline
		GOTO TEST1			; go to test1 for set-second button 
		GOTO INCRE_MIN		; go to INCRE_MIN, increment minute by 1
TEST1	BTFSC PORTB,5		; if set second button is pressed skip next line
		GOTO TEST2			; go to TEST2, for start button
		GOTO INCRE_SEC		; increment second by 1
TEST2	BTFSC PORTB,6		; if start button is press skip nextline
		GOTO MAIN			; back to main program if none of the buttons is pressed
		GOTO START_COUNT	; go to start countdown
;== strobing ==		
DISPLAY
	MOVLW 0xFE				; display 7segment of tens of minute first 
	MOVWF PORTB
	MOVF MIN_TENS,0			; move the value of MIN_TENS to w register
	MOVWF PORTA				; move content of w to PORTA
	call fast_delay
	MOVLW 0xFD				; display 7segment of ones of minute 
	MOVWF PORTB	
	MOVF MIN_ONES,0			; move the value of MIN_ONES to w register
	MOVWF PORTA				; move content of w to PORTA
	call fast_delay
	MOVLW 0xFB				; display 7segment of tens of second 
	MOVWF PORTB
	MOVF SEC_TENS,0			; move the value of SEC_TENS to w register
	MOVWF PORTA				; move content of w to PORTA
	call fast_delay
	MOVLW 0xF7				; display 7segment of ones of second 
	MOVWF PORTB
	MOVF SEC_ONES,0			; move the value of SEC_ONES to w register
	MOVWF PORTA				; move content of w to PORTA
	call fast_delay
	RETURN
;==set seconds and minutes	
INCRE_MIN
	CALL DISPLAY			; call display
	BTFSS PORTB,4			; if set-minute button is unpressed skip nextline
	GOTO INCRE_MIN			; if set-minute button still pressed loop to call display
	INCF MIN_ONES			; increment MIN_ONES by 1
	BTFSS MIN_ONES,3		; test bit3 of MIN_ONES (for MIN_ONES > 9) that is 1010
	GOTO MAIN				; go to main if MIN_ONES is not 1010
	BTFSS MIN_ONES,1		; test bit1 of MIN_ONES, if MIN_ONES = 1010 skip nextline
	GOTO MAIN				; go to main with MIN_ONES is 1001 or 1000 (8 or 9)
	MOVLW ZERO				; W = 0
	MOVWF MIN_ONES			; MIN_ONES = 0
	INCF MIN_TENS			; increment MIN_TENS by 1
	BTFSS MIN_TENS,2		; test bit2 of MIN_TENS (for MIN_TENS > 5) that is 0110 
	GOTO MAIN				; go to main with MIN_TENS = 1,2 or 3
	BTFSS MIN_TENS,1		; test bit1 of MIN_TENS, if MIN_TENS = 0110 skip nextline
	GOTO MAIN				; go to main with MIN_TENS = 4or5
	MOVLW ZERO				; w = 0
	MOVWF MIN_TENS			; MIN_TENS = 0
	GOTO MAIN				; go to main program
INCRE_SEC
	CALL DISPLAY			; call display
	BTFSS PORTB,5			; if set-second button is unpressed skip nextline
	GOTO INCRE_SEC			; if set-second button still pressed loop to call display
	INCF SEC_ONES			; increment SEC_ONES by 1
	BTFSS SEC_ONES,3		; test bit3 of SEC_ONES (for SEC_ONES > 9) that is 1010
	GOTO MAIN				; goto main if SEC_ONES is not 1010
	BTFSS SEC_ONES,1		; test bit1 of SEC_ONES, if SEC_ONES = 1010 skip nextline
	GOTO MAIN				; goto main with SEC_ONES is 1000 or 1001 (8 or 9)
	MOVLW ZERO				; W = 0
	MOVWF SEC_ONES			; SEC_ONES = 0
	INCF SEC_TENS			; increment MIN_ONES by 1
	BTFSS SEC_TENS,2		; test bit2 of SEC_TENS (for SEC_TENS > 5) that is 0110 
	GOTO MAIN				; go to main with SEC_TENS = 1,2 or 3
	BTFSS SEC_TENS,1		; test bit1 of SEC_TENS, if SEC_TENS = 0110 skip nextline
	GOTO MAIN				; go to main with SEC_TENS = 4or5
	MOVLW ZERO				; w = 0
	MOVWF SEC_TENS			; SEC_TENS = 0
	GOTO MAIN				; go to main program
;=========START COUNTDOWN=========
START_COUNT
	CALL TEST_S_ONES_0		; call routine if SEC_ONES = 0
	BTFSS TEMP,4			; if TEMP = 00010000 skip nextline
	DECF SEC_ONES			; decrement SEC_ONES by 1
	CALL TEST_S_ONES_0		; call routine if SEC_ONES = 0
	BTFSS TEMP,4			; if bit4 of TEMP is 1, skip next line
	GOTO DISPLAY_COUNT		; display output for 1 sec then go back to start count for next digit
	CALL DEC_S_TENS			; call subroutine for decrementing tens of second
	BTFSS SEC_TENS,4		; if bit4 of SEC_TENS is 1 skip next line
	GOTO DISPLAY_COUNT		; display output for 1 sec then go back to start count for next digit
	CALL DEC_M_ONES			; call subroutine for decrementing ones of minute
	BTFSS MIN_ONES,4		; if bit4 of MIN_ONES is 1 skip next line
	GOTO DISPLAY_COUNT		; display output for 1 sec then go back to start count for next digit
	CALL DEC_M_TENS			; call subroutine for decrementing tens of minute
    BTFSS MIN_TENS,4		; if bit4 of MIN_TENS is 1 skip next line
    GOTO DISPLAY_COUNT		; display output for 1 sec then go back to start count for next digit
	GOTO INIT				; go to initial display 00:00

TEST_S_ONES_0				
	MOVF SEC_ONES,0			; move current value of SEC_ONES  to w
	MOVWF TEMP				; move w to TEMP
	MOVLW TEST_ZERO			; move 00001111 to w
	XORWF TEMP,1			; XOR w with TEMP then place result to TEMP
	MOVLW .1				; w = 1
	ADDWF TEMP,1			; ADD w and TEMP then place result to TEMP
	RETURN					; return
					
DEC_S_TENS
	CALL DISPLAY_ANG_ZERO	; 
	MOVLW NINE				; w = 9
	MOVWF SEC_ONES			; SEC_ONES = 9
	DECF SEC_TENS			; decrement SEC_TENS
	RETURN					; return
DEC_M_ONES
	MOVLW FIVE				; w = 5
	MOVWF SEC_TENS			; SEC_TENS = 5
	DECF MIN_ONES			; decrement MIN_ONES
	RETURN					; return
DEC_M_TENS
	MOVLW NINE				; w = 9
	MOVWF MIN_ONES			; MIN_ONES = 9
	DECF MIN_TENS			; decrement MIN_TENS
	RETURN					; return
;== display for 1 second==
DISPLAY_COUNT
	MOVLW SET_DELAY2		; w = 24
	MOVWF DELAY2			; DELAY = 24
LOOP_HERE	
	CALL DISPLAY			; call display
	DECFSZ DELAY,1			; decrement DELAY, if DELAY = 0 skip next line 
	GOTO LOOP_HERE			; this will display output until DELAY = 0 
	decfsz DELAY2,1
	GOTO LOOP_HERE
	GOTO START_COUNT		; go to START_COUNT for next digit	
		
DISPLAY_ANG_ZERO			; this routine is intended of ones of second. 
	MOVLW SET_DELAY2		; if this routine would not be called,
	MOVWF DELAY2			; "0" will not display wehn the counting of ones  
LOOP_HERE2					; of second  reaches zero. 
	CALL DISPLAY			; example(...12-11-09-08-07...)
	DECFSZ DELAY,1
	GOTO LOOP_HERE2
	decfsz DELAY2,1
	GOTO LOOP_HERE2
	RETURN	
;==delay for strobe	
fast_delay	movlw .10
		movwf count1
loop1	decfsz count1,1
		goto loop1
		return	
END