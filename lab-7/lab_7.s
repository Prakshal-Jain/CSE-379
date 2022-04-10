	.text

	.global uart_interrupt_init
	.global gpio_interrupt_init
	.global timer_interrupt_init
	.global UART0_Handler
	.global Switch_Handler
	.global Timer_Handler		; This is needed for Lab #6
	.global simple_read_character
	.global output_character	; This is from your Lab #4 Library
	.global read_string		; This is from your Lab #4 Library
	.global output_string		; This is from your Lab #4 Library
	.global uart_init		; This is from your Lab #4 Library

	; New added

	.global string2int
	.global int2string
	.global read_from_push_btn ; modify to just initialize
	.global illuminate_LEDs
	.global illuminate_RGB_LED

	;end

	;New need to be writted

	;.global push_btn_inturrpt_init
	;.global push_btn_inturrpt_handler

	;.global sw2_inturrpt_init
	;.global sw2_inturrpt_handler

	;.global generateRandomNumber
	;.global generateRandom2_4
	;.global incrementClock
	;.global select_RBG_color


	; end


	.global ptr_to_prompt
	.global ptr_to_hv_movement
	.global ptr_to_direction_movement
	.global ptr_to_current_position
	.global ptr_to_game_over

ptr_to_prompt:					.word prompt
ptr_to_hv_movement:	    		.word hv_movement
ptr_to_direction_movement: 		.word direction_movement
ptr_to_current_position: 	    .word current_postion
ptr_to_game_over: 				.word game_over
ptr_to_hb_array:				.word hb_array


lab7:
	uart_interrupt_init





