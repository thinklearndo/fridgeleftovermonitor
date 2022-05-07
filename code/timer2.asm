include HT68F001.inc

ds	.section	'data'

SMALLCOUNTDOWN DB ?
MIDCOUNTDOWN DB ?
BIGCOUNTDOWN DB ?

DELAYCOUNTDOWN DB ?

STATE DB ?

TURNOFFCOUNTER DB ?

LEDCOUNTER DB ?

BLINKCOUNT DB ?

LEDSTATE DB ?
; LEDSTATE.0 - keep track of pa0
; LEDSTATE.1 - if we just reset the counter
;LEDSTATE.4 - blink enabled
;LEDSTATE.5 - shortest blink
;LEDSTATE.6 - mid blink
;LEDSTATE.7 - longest blink

;state.0 = small byte done
;state.1 = mid byte done
;state.2 = big byte done
;state.3 = all done
;state.4 = first time through init
;state.5 = button has been pressed
;state.6 = periodic check
;state.7 = 8.125 seconds have passed

cs	.section	at  000h	'code'

org 00h 
jmp POWERON
org 04h
jmp PERIODICINT
org 08h
jmp TIMERINT

POWERON:
clr state.4

JMP INIT

INIT:

mov A, 00001010b
swap ACC
mov A, 00001000b
mov WDTC, A			;disable watchdog

clr LEDSTATE

;pa1 is switch
;pa5 is led

;original
clr PAPU0
set PAPU1 ; pull up resistor for switch
clr PAPU2
clr PAPU3
clr PAPU4
CLR PAPU5

;set PAPU1 ; pull up resistor for switch

;original
clr PAC0
set PAC1 ; switch is input
clr PAC2
clr PAC3
clr PAC4
clr PAC5 ; led is output

;set PAC1 ; switch is input
;clr PAC5 ; led is output

clr PAWU0
set PAWU1 ; turn on wake up control for switch
clr PAWU2
clr PAWU3
clr PAWU4
clr PAWU5

;original
clr PA0 ; all pins off
clr PA1
clr PA2
clr PA3
clr PA4
clr PA5

;clr PA5

clr STATE.7
set STATE.0 ; set big bit high, it needs to clear to mark it done
set STATE.1 ; set mid bit high, it needs to clear to mark it done
set STATE.2 ; set low bit high, it needs to clear to mark it done
; once all 3 bits are set to 0, it means we're done running
clr STATE.3 ; 3 is 1 when all done
clr STATE.5

mov A, 00001111b ; SMALLCOUNTDOWN should always be 255
swap ACC
mov A, 00001111b

mov SMALLCOUNTDOWN, A
;original
mov A, 00001111b ; MIDCOUNTDOWN should be 255 for 1 week
swap ACC
mov A, 00001111b

mov MIDCOUNTDOWN, A

;fast
;mov A, 00000000b ; BIGCOUNTDOWN should be 32 for 1 week
;swap ACC
;mov A, 00001000b

;mov MIDCOUNTDOWN, A

;original
mov A, 00000010b ; BIGCOUNTDOWN should be 32 for 1 week
swap ACC
mov A, 00000000b

mov BIGCOUNTDOWN, A

;fast
;mov A, 00000000b ; BIGCOUNTDOWN should be 32 for 1 week
;swap ACC
;mov A, 00001000b

;mov BIGCOUNTDOWN, A


mov A, 00000000b
swap ACC
mov A, 00000000b
mov TMR, A		;preload timer counter to 254, so it triggers an interrupt after ~4 ms

mov A, 00000010b
swap ACC
mov A, 00000000b
mov TURNOFFCOUNTER, A

set TM1
clr TM0 		; set timer mode to counter

clr TPSC0
set TPSC1
clr TPSC2		

; originally uncommented
set TON			; start the timer

mov A, 00000000b
swap ACC
mov A, 00000111b
mov INTC, A		  ; enable timer base interrupts, timer counter interrupts and global interrupts

mov A, 00001000b
swap ACC
mov A, 00000111b
mov TBC, A		  ; turn on timerbase interrupt, with it triggering every 8 seconds (0111b)

; fastest timerbase interrupts
;mov A, 00001000b
;swap ACC
;mov A, 00000000b
;mov TBC, A		  ; FAST


sz state.4
jmp SHOWTURNONBLINKS
set state.4
JMP TURNOFF

HANDLETURNONPERIODIC:
clr STATE.6

sdz LEDCOUNTER
JMP TURNONLOOP

JMP ENDTURNONLED


SHOWTURNONBLINKS:

mov A, 00000001b
SWAP ACC
mov A, 00000000b
MOV LEDCOUNTER, A

set PA5

TURNONLOOP:

sz  STATE.6
JMP HANDLETURNONPERIODIC

JMP TURNONLOOP

JMP ENDTURNONLED

ENDTURNONLED:

mov A, 00000000b
SWAP ACC
mov A, 00000000b
MOV LEDCOUNTER, A

clr LEDSTATE.4
clr PA5
clr STATE.5

JMP MAIN


MAIN:

sz STATE.7
JMP HANDLETIMER
sz STATE.6
JMP HANDLEPERIODIC

JMP MAIN

TIMERINT PROC

set STATE.7

RETI
TIMERINT ENDP

PERIODICINT PROC

;mov A, 00001110b
;swap ACC
;mov A, 00000110b
;mov TMR, A ;reset timer starting point to give us 100ms call

SET STATE.6

RETI
PERIODICINT ENDP

HANDLEPERIODIC:
clr STATE.6

sz PA1
JMP NOBUTTON ;PA1 high here means no button press, its pullup
JMP HANDLEBUTTON

HANDLEAFTERBUTTON:

sz STATE.3
CALL SETDONEBLINKS

call SHOWBLINKS

JMP MAIN


SHOWBLINKS PROC

SNZ LEDSTATE.4
JMP ENDBLINKS

SZ LEDCOUNTER
JMP LIGHTUP
JMP SETLEDCOUNTER

LIGHTUP:

sdz LEDCOUNTER
JMP ENDBLINKS
JMP DECREMENTBLINKCOUNT




ENDBLINKS:
RET
SHOWBLINKS ENDP

DECREMENTBLINKCOUNT:
sdz BLINKCOUNT
JMP SWITCHBLINK
JMP CLEARBLINKS


SWITCHBLINK:
sz PA5
JMP CLEARPA5
SET PA5

JMP ENDBLINKS

CLEARPA5:
clr PA5
JMP ENDBLINKS

CLEARBLINKS:
clr PA5
clr LEDSTATE.4
clr LEDSTATE.5
clr LEDSTATE.6
clr LEDSTATE.7
JMP ENDBLINKS


SETLEDCOUNTER:
sz LEDSTATE.5
JMP SETFASTBLINKS

SZ LEDSTATE.6
JMP SETMIDBLINKS

SZ LEDSTATE.7
JMP SETLONGBLINKS

JMP MAIN

SETFASTBLINKS:
mov A, 00000000b
SWAP ACC
mov A, 00000100b
MOV LEDCOUNTER, A

JMP LIGHTUP

SETMIDBLINKS:

sz PA5
JMP SETONBLINKS

JMP SETOFFBLINKS

SETOFFBLINKS:

mov A, 00000001b
SWAP ACC
mov A, 00000000b
MOV LEDCOUNTER, A

JMP LIGHTUP

SETONBLINKS:

mov A, 00000000b
SWAP ACC
mov A, 00000100b
MOV LEDCOUNTER, A

JMP LIGHTUP

SETLONGBLINKS:

sz PA5
JMP SETONLONGBLINKS

JMP SETOFFLONGBLINKS

SETOFFLONGBLINKS:

mov A, 00000000b
SWAP ACC
mov A, 00000100b
MOV LEDCOUNTER, A

JMP LIGHTUP

SETONLONGBLINKS:

mov A, 00000010b
SWAP ACC
mov A, 00000000b
MOV LEDCOUNTER, A

JMP LIGHTUP



SETDONEBLINKS PROC

sz LEDSTATE.4
JMP ENDDONEBLINKS

set LEDSTATE.6
mov A, 00000000b
swap ACC
mov A, 00000010b
mov BLINKCOUNT, A

set LEDSTATE.4

ENDDONEBLINKS:

RET
SETDONEBLINKS ENDP


NOBUTTON:

sz STATE.5 ; if 5 is 1, it was pressed
jmp SHOWONBLINKS
JMP HANDLEAFTERBUTTON


SHOWONBLINKS:
clr STATE.5

mov A, 00000010b
swap ACC
mov A, 00000000b
mov TURNOFFCOUNTER, A ; reset turn off counter, button was released

sz STATE.3
jmp HANDLEAFTERBUTTON ; ignore showing on blinks if its expired

set LEDSTATE.5
mov A, 00000000b
swap ACC
mov A, 00000100b
mov BLINKCOUNT, A

set LEDSTATE.4

JMP HANDLEAFTERBUTTON

HANDLEBUTTON:
set STATE.5 ; set that the button has been pressed

sdz TURNOFFCOUNTER
jmp HANDLEAFTERBUTTON
jmp SHOWTURNOFFBLINKS

SHOWTURNOFFBLINKS:
;------------------------------------

clr LEDSTATE.6
clr LEDSTATE.5
set LEDSTATE.7
mov A, 00000000b
swap ACC
mov A, 00000110b
mov BLINKCOUNT, A

set LEDSTATE.4

HANDLETURNOFFBLINKS:

sz STATE.6
JMP HANDLEPERIODICTURNINGOFF

sz LEDSTATE.4
jmp HANDLETURNOFFBLINKS

JMP TURNOFF

HANDLEPERIODICTURNINGOFF:

clr STATE.6

CALL SHOWBLINKS

JMP HANDLETURNOFFBLINKS



TURNOFF:
mov A, 00000000b
swap ACC
mov A, 00000000b
mov INTC, A	; turn off all interrupts

mov A, 00000000b
swap ACC
mov A, 00000000b
mov TBC, A ; turn off timerbase counter

clr TON


HALT ; everything resumes from here

mov A, 00000010b
swap ACC
mov A, 00000000b
mov TURNOFFCOUNTER, A

CHECKBUTTONBOUNCE:

;check for the button being pressed
sz PA1
JMP TURNOFF ;PA1 high here means no button press, its pullup

sdz TURNOFFCOUNTER
JMP INIT

JMP CHECKBUTTONBOUNCE

HANDLETIMER:

clr STATE.7

sz STATE.3
jmp MAIN

sz PA0
jmp CLRPA0

set PA0
jmp CONTINUETIMER

CLRPA0:
clr PA0

CONTINUETIMER:

dec SMALLCOUNTDOWN ; once SMALLCOUNTDOWN hits zero, need to check if we're done

sz LEDSTATE.1
jmp CHECKSMALLCOUNT

JMP MIDTIME ; comment out to echo out small byte

JMP ECHOBYTES

ECHOBYTES:

set PA2

sz PA0
jmp SETLEDSTATE0

clr LEDSTATE.0
JMP TRANSMITBITS

SETLEDSTATE0:
set LEDSTATE.0

JMP TRANSMITBITS

TRANSMITBITS:

clr PA0

CALL DELAY

;bit 7

sz SMALLCOUNTDOWN.7
set PA0

sz SMALLCOUNTDOWN.7
jmp bit6

clr PA0
jmp bit6

bit6:
clr PA2
call DELAY
SET PA2
call DELAY

sz SMALLCOUNTDOWN.6
set PA0

sz SMALLCOUNTDOWN.6
jmp bit5

clr PA0
jmp bit5

bit5:
clr PA2
call DELAY
SET PA2
call DELAY

sz SMALLCOUNTDOWN.5
set PA0

sz SMALLCOUNTDOWN.5
jmp bit4

clr PA0
jmp bit4

bit4:
clr PA2
call DELAY
SET PA2
call DELAY

sz SMALLCOUNTDOWN.4
set PA0

sz SMALLCOUNTDOWN.4
jmp bit3

clr PA0
jmp bit3

bit3:
clr PA2
call DELAY
SET PA2
call DELAY

sz SMALLCOUNTDOWN.3
set PA0

sz SMALLCOUNTDOWN.3
jmp bit2

clr PA0
jmp bit2

bit2:
clr PA2
call DELAY
SET PA2
call DELAY

sz SMALLCOUNTDOWN.2
set PA0

sz SMALLCOUNTDOWN.2
jmp bit1

clr PA0
jmp bit1

bit1:
clr PA2
call DELAY
SET PA2
call DELAY

sz SMALLCOUNTDOWN.1
set PA0

sz SMALLCOUNTDOWN.1
jmp bit0

clr PA0
jmp bit0

bit0:
clr PA2
call DELAY
SET PA2
call DELAY

sz SMALLCOUNTDOWN.0
set PA0

sz SMALLCOUNTDOWN.0
jmp clear2

clr PA0
jmp clear2

clear2:

clr PA2
call DELAY

; reset pa0

sz LEDSTATE.0
jmp SETPA0FROMSTATE0

clr PA0
JMP MIDTIME

SETPA0FROMSTATE0:
set PA0

JMP MIDTIME

MIDTIME:
sz SMALLCOUNTDOWN
JMP MAIN


sz MIDCOUNTDOWN
JMP DECREMENTMID

sz BIGCOUNTDOWN
JMP DECREMENTBIG


;sz STATE.1
;jmp DECREMENTMID

clr STATE.0

jmp ALLDONE

ALLDONE:

set STATE.3

;for continued testing
;JMP INIT ; REMOVE ME TO GET BACK TO NORMAL

JMP MAIN

DECREMENTMID:

dec MIDCOUNTDOWN

JMP RESETSMALL

DECREMENTBIG:

dec BIGCOUNTDOWN

JMP RESETSMALL


;DECREMENTMID:

;sdz MIDCOUNTDOWN
;JMP RESETSMALL

;sz STATE.2
;JMP DECREMENTBIG

;clr STATE.1
;JMP RESETSMALL


;DECREMENTBIG:
;clr STATE.2
;JMP RESETMIDCOUNTDOWN

;RESETMIDCOUNTDOWN:

;mov A, 00001111b ; for 1wk counting
;mov A, 00000000b ; for fast counting
;swap ACC
;mov A, 00001111b ; for 1 wk counting
;mov A, 000000010b ; for fast counting
;mov MIDCOUNTDOWN, A

;JMP RESETSMALL

RESETSMALL:

set LEDSTATE.1

;original
;;mov A, 00001111b ; for 1wk counting
;mov A, 00000100b ; for fast counting
;;swap ACC
;;mov A, 00001111b ; for 1wk counting
;mov A, 00000000b ; for fast couting
;mov SMALLCOUNTDOWN, A

set SMALLCOUNTDOWN.0
set SMALLCOUNTDOWN.1
set SMALLCOUNTDOWN.2
set SMALLCOUNTDOWN.3
set SMALLCOUNTDOWN.4
set SMALLCOUNTDOWN.5
set SMALLCOUNTDOWN.6
set SMALLCOUNTDOWN.7

JMP MAIN

DELAY:

mov A, 00001000b 
swap ACC
mov A, 00000000b 
mov DELAYCOUNTDOWN, A

KEEPCOUNTING:

sdz DELAYCOUNTDOWN
JMP KEEPCOUNTING

RET

CHECKSMALLCOUNT:

clr LEDSTATE.1

snz SMALLCOUNTDOWN.7
jmp FIXSMALLCOUNT

snz SMALLCOUNTDOWN.6
jmp FIXSMALLCOUNT

snz SMALLCOUNTDOWN.5
jmp FIXSMALLCOUNT

snz SMALLCOUNTDOWN.4
jmp FIXSMALLCOUNT

snz SMALLCOUNTDOWN.3
jmp FIXSMALLCOUNT

snz SMALLCOUNTDOWN.2
jmp FIXSMALLCOUNT

snz SMALLCOUNTDOWN.1
jmp FIXSMALLCOUNT

;jmp ECHOBYTES ;for echoing out small byte
JMP MIDTIME

FIXSMALLCOUNT:

set SMALLCOUNTDOWN.1
set SMALLCOUNTDOWN.2
set SMALLCOUNTDOWN.3
set SMALLCOUNTDOWN.4
set SMALLCOUNTDOWN.5
set SMALLCOUNTDOWN.6
set SMALLCOUNTDOWN.7

;jmp ECHOBYTES ; for echoing out small byte
JMP MIDTIME