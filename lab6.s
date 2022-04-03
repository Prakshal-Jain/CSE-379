	.data

	.global prompt
	.global hv_movement
	.global direction_movement
	.global current_position
	.global game_over

prompt:	.string 0xC," -------------------- ",13,10
		    .string "|                    |",13,10
		    .string "|                    |",13,10
		    .string "|                    |",13,10
		    .string "|                    |",13,10
		    .string "|                    |",13,10
		    .string "|                    |",13,10
		    .string "|                    |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string "|         X          |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string "|                    |",13,10
			.string " -------------------- ",13,10,0


hv_movement:	    .byte 0x00		; Horizontal -> 0 Vertical -> 1
direction_movement: .byte 0x00		; Left -> 0 Right -> 1 ; Up -> 0 Down -> 1
current_postion: 	.word 0x00000000		; Store number of time SW1 is pressed
game_over: 			.byte 0x00


	.text

	.global uart_interrupt_init
	.global gpio_interrupt_init
	.global UART0_Handler
	.global Switch_Handler
	.global Timer_Handler		; This is needed for Lab #6
	.global simple_read_character
	.global output_character	; This is from your Lab #4 Library
	.global read_string		; This is from your Lab #4 Library
	.global output_string		; This is from your Lab #4 Library
	.global uart_init		; This is from your Lab #4 Library
	.global lab6

ptr_to_prompt:					.word prompt
ptr_to_hv_movement:	    		.word hv_movement
ptr_to_direction_movement: 		.word direction_movement
ptr_to_current_position: 	    .word current_postion
ptr_to_game_over: 				.word game_over
lab6:					; This is your main routine which is called from your C wrapper

	PUSH {lr}   		; Store lr to stack

    bl uart_init			;  initializes the user UART
	bl uart_interrupt_init	; initialization for uart interrupt (when data is received)
	bl gpio_interrupt_init	; initialization for gpio interrupt (when switch is pressed)
	bl timer_interrupt_init

	; This is where you should implement a loop, waiting for the user to
	; enter a q, indicating they want to end the program.

	ldr r4, ptr_to_current_position
	ldr r5, ptr_to_prompt
	ADD r5, r5, #251
	STR r5, [r4]
VALID_POSITION:
	ldr r4, ptr_to_game_over
	LDRB r4, [r4]
	CMP r4, #1
	BEQ GAMEOVER
	B VALID_POSITION
GAMEOVER:
	POP {lr}		; Restore lr from the stack
	MOV pc, lr


uart_interrupt_init:
	PUSH {lr}   		; Store lr to stack

	; Set the Receive Interrupt Mask (RXIM) bit in the UART Interrupt Mask Register (UARTIM)
	MOV r0, #0xC000		; Store the base address for UART0
	MOVT r0, #0x4000

	MOV r1, #0x10			; Mask with bit-4 set to 1
	LDRB r2, [r0, #0x038]	; Load the original byte

	ORR r2, r2, r1			; Set the bit-4 to 1, keeping other bits the same
	STRB r2, [r0, #0x038]	; Store the byte back

	; Set the bit 5 bit in the Interrupt 0-31 Set Enable Register (EN0)
	MOV r0, #0xE000		; Store the base address for EN0
	MOVT r0, #0xE000

	MOV r1, #0x20			; Mask with bit-5 set to 1
	LDRB r2, [r0, #0x100]	; Load the original byte

	ORR r2, r2, r1			; Set the bit-5 to 1, keeping other bits the same
	STRB r2, [r0, #0x100]	; Store the byte back

	POP {lr}		; Restore lr from the stack
	MOV pc, lr


gpio_interrupt_init:

	; Your code to initialize the SW1 interrupt goes here
	; Don't forget to follow the procedure you followed in Lab #4
	; to initialize SW1.
	PUSH {r4-r11, lr}		; Store r4-r11, lr to stack

	BL read_tiva_pushbutton	; Read from TIVA push button

	; Determining Edge/Level Sensitivity
	MOV r0, #0x5000			; r0 = GPIO Port F Base Address
	MOVT r0, #0x4002
	LDRB r2, [r0, #0x404]	; Load the byte at address 0x40025404
	AND r2, r2, #0xEF		; Set bit-4 to 0 (Edge Sensitive)
	STRB r2, [r0, #0x404]	; Store r2 back at address 0x40025404

	; Selecting Both or Single Edge Triggering
	LDRB r2, [r0, #0x408]	; Load the byte at address 0x40025408
	AND r2, r2, #0xEF		; Set bit-4 to 0
	STRB r2, [r0, #0x408]	; Store r2 back at address 0x40025408

	; Selecting Edge for Interrupt Triggering
	LDRB r2, [r0, #0x40C]	; Load the byte at address 0x4002540C
	AND r2, r2, #0xEF		; Set bit-4 to 0
	STRB r2, [r0, #0x40C]	; Store r2 back at address 0x4002540C

	; Enabling the Interrupt
	LDRB r2, [r0, #0x410]	; Load the byte at address 0x40025410
	ORR r2, r2, #0x10		; Set bit-4 to 1
	STRB r2, [r0, #0x410]	; Store r2 back at address 0x40025410

	; Configure Processor to Allow GPIO Port F to Interrupt Processor
	MOV r0, #0xE000			; EN0 Base Address
	MOVT r0, #0xE000
	LDR r2, [r0, #0x100]	; Load the word at address 0xE000E100
	MOV r1, #0x0000			; Mask with bit 30 set to 1
	MOVT r1, #0x4000
	ORR r2, r2, r1			; Set bit-30 to 1
	STR r2, [r0, #0x100]	; Store the resulting word back

	POP {r4-r11, lr}		; Restore r4-r11, lr from the stack
	MOV pc, lr


UART0_Handler:
	; Your code for your UART handler goes here.
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler

	; Clear Interrupt (UART Interrupt Clear Register (UARTICR))
	PUSH {r4-r11, lr}		; Store r4-r11, lr to stack

	MOV r0, #0xC000			; Move the base address for UART0 in r0
	MOVT r0, #0x4000

	MOV r1, #0x10			; Mask with bit-4 set to 1
	LDRB r2, [r0, #0x044]	; Load the original byte

	ORR r2, r2, r1			; Set the bit-4 to 1, keeping other bits the same
	STRB r2, [r0, #0x044]	; Store the byte back

	; Handle Interrupt
	BL simple_read_character	; Branch to the simple_read_character function
	CMP r0, #13
	BNE ENTERNOTPRESSED
	ldr r4, ptr_to_hv_movement
	LDRB r0, [r4]
	EOR r0, r0, #0x1
	AND r0, r0, #0x1
	STRB r0, [r4]
ENTERNOTPRESSED:
	POP {r4-r11, lr}		; Restore r4-r11, lr from the stack
	BX lr       	; Return


Switch_Handler:

	; Your code for your UART handler goes here.
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler

	; Clear the Interrupt for the Pin on the Port via the GPIO Interrupt Clear Register (GPIOICR)
	PUSH {r4-r11, lr}		; Store r4-r11, lr to stack

	MOV r0, #0x5000			; Move the base address for GPIO Port F in r0
	MOVT r0, #0x4002

	MOV r1, #0x10			; Mask with bit-4 set to 1
	LDRB r2, [r0, #0x41C]	; Load the byte at GPIOICR offset

	ORR r2, r2, r1			; Set the bit-4 to 1, keeping other bits the same
	STRB r2, [r0, #0x41C]	; Store the byte back

	ldr r4, ptr_to_direction_movement
	LDRB r0, [r4]
	EOR r0, r0, #0x1
	AND r0, r0, #0x1
	STRB r0, [r4]

	POP {r4-r11, lr}						; Restore r4-r11, lr from the stack
	BX lr       	; Return


timer_interrupt_init:
	PUSH {r4-r11, lr}		; Store r4-r11, lr to stack

							; Connect Clock to Timer
	MOV r0, #0xE000			; Store base address for General Purpose Timer Run Mode Clock Gating Control Register (RCGCTIMER)
	MOVT r0, #0x400F
	LDRB r1, [r0, #0x604]	; Load the existing byte
	ORR r1, #0x1			; Set bit-0 to 1
	STRB r1, [r0, #0x604]	; Store the changed byte

							; Disable the timer during setup
	MOV r0, #0x0000			; Store base address for General Purpose Timer Control Register (GPTMCTL)
	MOVT r0, #0x4003
	LDRB r1, [r0, #0x00C]	; Load the existing byte
	AND r1, #0xFE			; Set bit-0 to 0
	STRB r1, [r0, #0x00C]	; Store the changed byte

							; Setup Timer for 32-Bit Mode via General Purpose Timer Configuration Register (GPTMCFG)
	LDRB r1, [r0]			; Load the existing byte
	AND r1, #0xF8			; Set bits (0, 1, 2) to 1
	STRB r1, [r0]			; Store the changed byte

							; Put Timer in Periodic Mode
	LDRB r1, [r0, #0x004]	; Load the existing byte
	ORR r1, #0x2			; Write ‘2’ to TAMR
	STRB r1, [r0, #0x004]	; Store the changed byte

							; Setup Interval Period
	MOV r1, #0x1200			; Set 80000000 to the click (2 times per seconds)
	MOVT r1, #0x007A
	STR r1, [r0, #0x028]	; Store the changed byte

							; Enable Timer to Interrupt Processor
	LDRB r1, [r0, #0x018]	; Load the existing byte
	ORR r1, #0x1			; Set last bit to 1
	STRB r1, [r0, #0x018]	; Store the changed byte

							; Configure Processor to Allow Timer to Interrupt Processor
	MOV r0, #0xE000			; Store base address for General Purpose Timer Control Register (GPTMCTL)
	MOVT r0, #0xE000
	LDR r1, [r0, #0x100]	; Load the existing byte
	MOV r2, #0x0000			; Mask with bit 19 set to 1
	MOVT r2, #0x0008
	ORR r1, r2				; Set bit-19 to 1
	STR	 r1, [r0, #0x100]	; Store the changed byte

							; Enable Timer
	MOV r0, #0x0000			; Store base address for General Purpose Timer Control Register (GPTMCTL)
	MOVT r0, #0x4003
	LDRB r1, [r0, #0x00C]	; Load the existing byte
	ORR r1, #0x1			; Set bit-0 to 1
	STRB r1, [r0, #0x00C]	; Store the changed byte

	POP {r4-r11, lr}		; Restore r4-r11, lr from the stack
	MOV pc, lr


Timer_Handler:

	; Your code for your Timer handler goes here.  It is not needed
	; for Lab #5, but will be used in Lab #6.  It is referenced here
	; because the interrupt enabled startup code has declared Timer_Handler.
	; This will allow you to not have to redownload startup code for
	; Lab #6.  Instead, you can use the same startup code as for Lab #5.
	; Remember to preserver registers r4-r11 by pushing then popping
	; them to & from the stack at the beginning & end of the handler.
	PUSH {r4-r11, lr}

	MOV r0, #0x0000
	MOVT r0, #0x4003
	LDRB r1, [r0, #0x024]
	ORR r1, #0x1
	STRB r1, [r0, #0x024]

	ldr r1, ptr_to_hv_movement
	LDRB r1, [r1]
	ldr r2, ptr_to_direction_movement
	LDRB r2, [r2]
	ldr r4, ptr_to_current_position
	MOV r3, r4
	LDR r3, [r3]
	MOV r0, #32
	STRB r0, [r3]

	CMP r1, #0
	BNE NOTHORIZONTAL
	CMP r2, #0
	BNE NOTLEFT
	SUB r3, r3, #1
	B MOVEMENTDIRECTIONFOUND
NOTLEFT:
	ADD r3, r3, #1 ; direction is horizontal and right
	B MOVEMENTDIRECTIONFOUND
NOTHORIZONTAL:
	CMP r2, #0
	BNE NOTUP
	SUB r3, r3, #24 ; direction is vertical and up
	B MOVEMENTDIRECTIONFOUND
NOTUP:
	ADD r3, r3, #24 ; direction is vertical and down
MOVEMENTDIRECTIONFOUND:

	MOV r7, #1
	ldr r6, ptr_to_game_over
	LDRB r5, [r3]

	CMP r5, #45
	BNE GAME_OVER_NOTFOUND_1
	STRB r7, [r6]
GAME_OVER_NOTFOUND_1:

	CMP r5, #124
	BNE GAME_OVER_NOTFOUND_2
	STRB r7, [r6]
GAME_OVER_NOTFOUND_2

	STR r3, [r4]
	MOV r0, #88
	STRB r0, [r3]

	ldr r0, ptr_to_prompt
	BL output_string

	POP {r4-r11, lr}						; Restore r4-r11, lr from the stack
	BX lr       	; Return


simple_read_character:
	PUSH {lr}   		; Store lr to stack

	MOV r1, #0xC000		; Store the base address for UART0
	MOVT r1, #0x4000

	LDRB r0, [r1]		; Read Byte from Receive Register
	; return read character in r0
	POP {lr}		; Restore lr from the stack
	MOV PC,LR      	; Return


output_character:
	PUSH {r4-r11, lr}    		; Store register {r4-r11, lr} on stack
						 		; Your code for your output_character routine is placed here
	MOV r1, #0xC000      		; Set #0xC000 in the lower 32 bits of register r1
	MOVT r1, #0x4000 	 		; Set #0x4000 in the upper 32 bits of register r1
LOOP:
	LDRB r2, [r1, #0x18]  		; Get data from Address 0x4000C018 and store in register r2
	AND r3, r2, #32      		; AND 32 with data in register r2 and store the result in register r3
	CMP r3, #0           		; Compare the contents of r with 0
	BNE LOOP             		; If r3 != 0 then jump to label LOOP
	STRB r0, [r1]        		; Else store the contents of r0 at address 0x4000C000

	POP {r4-r11, lr}			; Restore r4 to r11, lr from the stack
	mov pc, lr					; Return


read_string:
	PUSH {r4-r10, lr}   ; Store register lr on stack
						; Your code for your read_string routine is placed here
STILL_READING:
	BL simple_read_character 		; Call read_character to get a charater from the user (a number in str format)
	BL output_character 	; Output the recieved character from previous instruction to the screen
	CMP r0, #13 			; Compare the recieved character to the ascii value of enter button (to determine end of input)
	BEQ DONE_READ_STRING 	; Branch to label DONE_READ_STRING if the value from above comparison id equa;
	STR r0, [r8] 			; ELSE: store the inputted chararcter in memory at address in r8
	ADD r8, r8, #1 			; increment the address in r8 by 1
	B STILL_READING 		; Unconditional banch to label STILL_READING
DONE_READ_STRING:
	MOV r0, #10 			; Move value 10 to r0 (which is the ascii of new line) return carriage is already outputted
	BL output_character 	; Call output_character to output the newline to the user
	ADD r8, r8, #1 			; increment the address in r8
	MOV r0, #0 				; Store 0 in the r0 register
	STR r0, [r8] 			; Now store the value from r0 (null) in memory at location r8
	POP {r4-r10, lr}
	mov pc, lr


output_string:
	; Pointer to the base address to string in r0
	PUSH {r4-r11, lr}	; Store register {r4-r11, lr} on stack
	MOV r6, r0			; r6 = r0

LOOP_OUTPUT_STRING:
	LDRB r0, [r6]					; Load the byte and move to the next byte (Post-indexed Addressing)
	ADD r6, r6, #1
	CMP r0, #0						; If r0 has NULL termination character (ASCII 0) ?
	BEQ EXIT_LOOP_OUTPUT_STRING		; Exit the loop
	BL output_character				; Output the character
	B LOOP_OUTPUT_STRING			; Continue looping

EXIT_LOOP_OUTPUT_STRING:
	POP {r4-r11, lr}	; Restore r4 to r11, lr from the stack
	MOV PC,LR      		; Return


int2string:
	; Input: r0 ->  integer,	r1 -> memory address to save the NULL-terminated string (corresponding to integer in r0)
	; Output: Corresponding string stored at address pointed by address in r1.

	PUSH {r4-r10, lr}   		; Store register {r4-r10, lr} on stack
								; Your code for your int2string routine is placed here
	MOV r5, #10         		; Move value 10 into r5 register
	MOV r2, #0          		;  Move value 0 into r2 register
	MOV r3, #1          		;  Move value 1 into r3 register
LOOPI2S:
	MUL r3, r3, r5    			; Multiply r3 with 10 and set in r3
	ADD r2, r2, #1    			; Add 1 to r2
	CMP r0, r3        			; Compare r0, r3
	BLT CONVERTING    			; if r0 < r3 jump to line 143 i.e tag CONVERTING
	B LOOPI2S         			; else Jump to line 37 i.e tag LOOPI2S
CONVERTING:
	MOV r3, #0        			; Mov value 0 to register r3
	STRB r3, [r1, r2] 			; Store a byte of data from regiter r3 into memory at location r1 + r2
NOTCONVERTEDI2S:
	SUB r2, r2, #1    			; Decrement the value in r2 by 1
	UDIV r3, r0, r5   			; integer divide the value in r0 by r5 (10) and store the result in r3
	MUL r3, r3, r5    			; Multiply the value in r3 by r5 (10) and store in r3
	SUB r4, r0, r3    			; subtract the r0 by r3 and store the result in r4
	ADD r4, r4, #48   			; add decimal 48 into r4 and store in r4 converting from decimal to ascii
	STRB r4, [r1, r2] 			; store a byte of data from r4 into the memory at address r1 + r2
	UDIV r0, r0, r5   			; Unsigned divide r0 by r5 (10) and store the result in r0
	CMP r2, #0        			; Compre the value in r0 with 0
	BNE NOTCONVERTEDI2S 		; Branch to label NOTCONVERTEDI2S if r2 is not equal to 0
	POP {r4-r10, lr}
	mov pc, lr


read_tiva_pushbutton:
	PUSH {r4-r10, lr}

	MOV r0, #0xE608 ; Move value 0xE608 in register r0
	MOVT r0, #0x400F ; Move value 0x400F in register r0 (TOP)
	MOV r1, #0x20 ; Move value 0x2 into r1
	STRB r1, [r0] ; Store value from r1 into memory address at r0

	MOV r0, #0x5400 ; Move value 0x5400 into r0
	MOVT r0, #0x4002 ; Move value 0x4002 into r0 (TOP)
	LDRB r1, [r0] ; Load value from memory address located in r0 into r1
	AND r1, r1, #0xEF ; And the value in r1 with value 0xEF
	STRB r1, [r0] ; Store the value from r1 into memory address at location stored in r0

	MOV r1, #0x10 ; MOve value 0x10 into r1
	MOV r0, #0x5510 ; Move value 0x5510 into r0
	MOVT r0, #0x4002 ; Move value 0x4002 into r0 (TOP)
	STRB r1, [r0] ; Store the value from r1 into memory at address located in r0

	MOV r0, #0x551C ; Move value 0x551C into r0
	MOVT r0, #0x4002; Move value 0x4002 into r0 (TOP)
	STRB r1, [r0] ; Store the value from r1 into memory at address located in r0

	POP {r4-r10, lr}
	MOV pc, lr


uart_init:
    PUSH {r4-r10, lr}   		; Store registers and lr on stack

    							; Your code for your uart_init routine is placed here
    MOV r0, #0xE618   			; Mov 0xE618 in the lower 32 bits of r0
    MOVT r0, #0x400F  			; Mov 0x400F in the upper 32 bits of r0
    MOV r1, #1        			; Move 1 in r1
    STR r1, [r0]      			; store the value 1 at location 0x400FE618


    MOV r0, #0xE608  			; Mov 0xE608 in the lower 32 bits of r0
    MOVT r0, #0x400F 			; Mov 0x400F in the upper 32 bits of r0
    MOV r1, #1       			; Move 1 in r1
    STR r1, [r0]     			; store the value 1 at location 0x400FE608

    MOV r0, #0xC030  			; Mov 0xC030 in the lower 32 bits of r0
    MOVT r0, #0x4000 			; Mov 0x4000 in the upper 32 bits of r0
    MOV r1, #0       			; Move 0 in r1
    STR r1, [r0]     			; store the value 0 at location 0x4000C030

    MOV r0, #0xC024  			; Mov 0xC024 in the lower 32 bits of r0
    MOVT r0, #0x4000 			; Mov 0x4000 in the upper 32 bits of r0
    MOV r1, #8       			; Move 8 into r1
    STR r1, [r0]     			; store the value 8 at location 0x4000C024

    MOV r0, #0xC028  			; Mov 0xC028 in the lower 32 bits of r0
    MOVT r0, #0x4000 			; Mov 0x4000 in the upper 32 bits of r0
    MOV r1, #44      			; Move 44 into r1
    STR r1, [r0]     			; store the value 44 at location 0x4000C028

    MOV r0, #0xCFC8  			; Mov 0xCFC8 in the lower 32 bits of r0
    MOVT r0, #0x4000 			; Mov 0x4000 in the upper 32 bits of r0
    MOV r1, #0       			; Move 0 into r1
    STR r1, [r0]     			; store the value 0 at location 0x4000CFC8

    MOV r0, #0xC02C  			; Mov 0xC02C in the lower 32 bits of r0
    MOVT r0, #0x4000 			; Mov 0x4000 in the upper 32 bits of r0
    MOV r1, #0x60    			; Move 0x60 into r1
    STR r1, [r0]     			; store the value 0x60 at location 0x4000C02C

    MOV r0, #0xC030  			; Mov 0xC030 in the lower 32 bits of r0
    MOVT r0, #0x4000 			; Mov 0x4000 in the upper 32 bits of r0
    MOV r1, #0x301   			; Move 0x301 into r1
    STR r1, [r0]     			; store the value 0x301 at location 0x4000C030

    MOV r0, #0x451C  			; Mov 0x451C in the lower 32 bits of r0
    MOVT r0, #0x4000 			; Mov 0x4000 in the upper 32 bits of r0
    LDR r1, [r0]     			; Load value from memory at address 0x4000451C into r1
    ORR r1, r1, #0x03 			; Logical OR the value in r1 with 0x03
    STR r1, [r0]     			; store the result from r1 into memory at address 0x4000451C

    MOV r0, #0x4420 			; Mov 0x4420 in the lower 32 bits of r0
    MOVT r0, #0x4000 			; Mov 0x4000 in the upper 32 bits of r0
    LDR r1, [r0]     			; Load value from memory at address 0x40004420 into r1
    ORR r1, r1, #0x03 			; Logical OR the value in r1 with 0x03
    STR r1, [r0]     			; store the result from r1 into memory at address 0x40004420

    MOV r0, #0x452C  			; Mov 0x452C in the lower 32 bits of r0
    MOVT r0, #0x4000 			; Mov 0x4000 in the upper 32 bits of r0
    LDR r1, [r0]     			; Load value from memory at address 0x4000452C into r1
    ORR r1, r1, #0x11 			; Logical OR the value in r1 with 0x11
    STR r1, [r0]     			; store the result from r1 into memory at address 0x4000452C

    POP {r4-r10, lr}
    mov pc, lr

	.end
