
.syntax unified
.cpu cortex-m0plus
.fpu softvfp
.thumb

// make linker see this
.global Reset_Handler

// get these from linker script
.word _sdata
.word _edata
.word _sbss
.word _ebss

// define clock base and enable addresses
.equ RCC_BASE,         (0x40021000)          // RCC base address
.equ RCC_IOPENR,       (RCC_BASE   + (0x34)) // RCC IOPENR register offset

// define GPIO Base, Moder and ODR pin addresses
.equ GPIOB_BASE,       (0x50000400)          // GPIOB base address
.equ GPIOB_MODER,      (GPIOB_BASE + (0x00)) // GPIOB MODER register offset
.equ GPIOB_IDR,        (GPIOB_BASE + (0x10)) // GPIOB IDR register offset
.equ GPIOB_ODR,        (GPIOB_BASE + (0x14)) // GPIOB ODR register offset

//Delay Interval
.equ delayInterval, 160000

// vector table, +1 thumb mode
.section .vectors
vector_table:
	.word _estack             //     Stack pointer
	.word Reset_Handler +1    //     Reset handler
	.word Default_Handler +1  //       NMI handler
	.word Default_Handler +1  // HardFault handler
	// add rest of them here if needed

// reset handler
.section .text
Reset_Handler:
	// set stack pointer
	ldr r0, =_estack
	mov sp, r0

	// initialize data and bss
	// not necessary for rom only code

	bl init_data
	// call main
	bl main
	// trap if returned
	b .

// initialize data and bss sections
.section .text
init_data:

	// copy rom to ram
	ldr r0, =_sdata
	ldr r1, =_edata
	ldr r2, =_sidata
	movs r3, #0
	b LoopCopyDataInit

	CopyDataInit:
		ldr r4, [r2, r3]
		str r4, [r0, r3]
		adds r3, r3, #4

	LoopCopyDataInit:
		adds r4, r0, r3
		cmp r4, r1
		bcc CopyDataInit

	// zero bss
	ldr r2, =_sbss
	ldr r4, =_ebss
	movs r3, #0
	b LoopFillZerobss

	FillZerobss:
		str  r3, [r2]
		adds r2, r2, #4

	LoopFillZerobss:
		cmp r2, r4
		bcc FillZerobss

	bx lr

// default handler
.section .text
Default_Handler:
	b Default_Handler

// main function
.section .text
main:
	// enable GPIOB clock, bit1 on IOPENR
	ldr r6, =RCC_IOPENR
	ldr r5, [r6]
	// movs expects imm8, so this should be fine
	movs r4, 0x2
	orrs r5, r5, r4
	str r5, [r6]

	// setup PB0, PB1, PB2...PB9 for 01 (Except PB7) and PB6 for 00 in MODER
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	// cannot do with movs, so use pc relative
	ldr r5, =[0xFFFFF]
	str r5, [r6]
	ldr r4, =[0x5C555]
	ands r5, r5, r4
	str r5, [r6]

	bl status_led //Control the status switch

	play:
	//  *3 *2 *1 *0 *1 *2 *3

	ldr r4, =[0x100] //0 led connected to PB8
	bl on //function that turns on the led
	bl status_led //button control

	//Third Stage
	ldr r4, =[0x304] //1&1 led connectod to PB2
	bl on
	bl status_led

	ldr r4, =[0x337] // 3&3 led connected to PB1
	bl on
	bl status_led

	ldr r4, =[0x325] // 2&2 led connected to PB5
	bl on
	bl status_led

	//Reset Stage
	ldr r4, =[0x000]
	bl on
	bl status_led

	b play

	pause:
	ldr r6, = GPIOB_ODR
	ldr r5, [r6] //ODR Value
	movs r4, 0x10 //Status led connected to PB4
	orrs r5, r5, r4 //Setting led on
	str r5, [r6]

	b status_led

	on:
	ldr r6, =GPIOB_ODR
	ldr r5, [r6]
	cmp r4, 0x0 //Control the which led on at last
	beq Reset //If all leds are on, then take all them off
	bne On
	Reset:
	ands r5, r5, r4
	On:
	orrs r5, r5, r4
	str r5, [r6]
	// Assign value to register r1 to sub 1 per clock
	ldr r1, =delayInterval
	delay:
	subs r1, r1, #1
	bne delay
	bx lr

	status_led:
	ldr r6, = GPIOB_IDR
	ldr r5, [r6] //IDR Value
	movs r4, #0x40   //Status switch connected to PB6
	ands r5, r5, r4  //Getting the value of button pressed or not
	lsrs r5, #6      //Shifting to lsb for compare

	cmp r5, #0x1 //Compare IDR Value with 1 bit
	bne BNE //If not equal
	beq BEQ //If equal

	BEQ:
	b pause

	BNE:
	//Turns the leds off
	ldr r6, =GPIOB_ODR
	ldr r5, [r6]
	ldr r5, =[0x0]
	str r5, [r6]
	bx lr

	// this should never get executed
	nop
