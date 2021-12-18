/*LAB2
   Halil Ibrahim Erdal  &  Arif Emre Yildiz  &  Omer Sarimese
      1901022264             1901022263          1801022001
         4 x 7 segment display with 2 buttons*/

.syntax unified
.cpu cortex-m0plus
.fpu softvfp
.thumb
/* make linker see this */
.global Reset_Handler
/* get these from linker script */
.word _sdata
.word _edata
.word _sbss
.word _ebss
/* define peripheral addresses from RM0444 page 57, Tables 3-4 */
.equ RCC_BASE,         (0x40021000)          // RCC base address
.equ RCC_IOPENR,       (RCC_BASE   + (0x34)) // RCC IOPENR register offset
.equ GPIOA_BASE,       (0x50000000)          // GPIOC base address           /* From rm0444-stm32g0x1 datasheet */
.equ GPIOA_MODER,      (GPIOA_BASE + (0x00)) // GPIOC MODER register offset
.equ GPIOA_ODR,        (GPIOA_BASE + (0x14)) // GPIOC ODR register offset
.equ GPIOA_IDR,        (GPIOA_BASE + (0x10))
.equ GPIOB_BASE,       (0x50000400)          // GPIOC base address           /* From rm0444-stm32g0x1 datasheet */
.equ GPIOB_MODER,      (GPIOB_BASE + (0x00)) // GPIOC MODER register offset
.equ GPIOB_ODR,        (GPIOB_BASE + (0x14)) // GPIOC ODR register offset
/* vector table, +1 thumb mode */
.section .vectors
vector_table:
	.word _estack             /*     Stack pointer */
	.word Reset_Handler +1    /*     Reset handler */
	.word Default_Handler +1  /*       NMI handler */
	.word Default_Handler +1  /* HardFault handler */
	/* add rest of them here if needed */
/* reset handler */
.section .text
Reset_Handler:
	/* set stack pointer */
	ldr r0, =_estack
	mov sp, r0
	/* initialize data and bss
	 * not necessary for rom only code
	 * */
	bl init_data
	/* call main */
	bl main
	/* trap if returned */
	b .
/* initialize data and bss sections */
.section .text
init_data:
	/* copy rom to ram */
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
	/* zero bss */
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
/* default handler */
.section .text
Default_Handler:
	b Default_Handler
/* main function */
.section .text
main:
	/* enable GPIOA & GPIOB clock, bit0 & bit1 on IOPENR */
	ldr r6, =RCC_IOPENR
	ldr r5, [r6]
	/* movs expects imm8, so this should be fine */
	movs r4, 0x3
	orrs r5, r5, r4
	str r5, [r6]
    /* setup PA6 for d1 of 7seg with bits 12-13 in MODER  */
    ldr r6,=GPIOA_MODER
    ldr r5,[r6]
    /* cannot do with movs, so use pc relative */
    ldr r4,=0x3000
    mvns r4,r4
    ands r5,r5,r4
    ldr r4,=0x1000
    orrs r5,r5,r4
    str r5,[r6]
/*  setup PA7 for button 00 for bits 14-15 in moder */
    ldr r6,=GPIOA_MODER
    ldr r5,[r6]
    /* cannot do with moves so use pc relative */
    ldr r4,=0x3
    lsls r4,r4,#14
    mvns r4,r4
    ands r5,r5,r4
    str r5,[r6]
/*  setup PA8 for button 00 for bits 16-17 in moder */ //Cözüldü
    ldr r6,=GPIOA_MODER
    ldr r5,[r6]
    /* cannot do with moves so use pc relative */
    ldr r4,=0x3
    lsls r4,r4,#16
    bics r5,r5,r4
    str r5,[r6]
movs r2, [0x0] //  on or off (R2 Function sonlarinda artiyor)
loop:
b button_ctrl_1
b button_ctrl_2
/*b FF // required for the first run, doesnt makes sense 
     //   functions already called in button_ctrl_2 
         //   WRONG DELETE     */
b loop
button_ctrl_1: // start stop control
/* ctrl button 1 connected to A7(PA7) in IDR */
bl button_ctrl_1
	ldr r6,=GPIOA_IDR
	ldr r5,[r6]
	lsrs r5,r5,#7 // button1
	movs r4,#0x1
	ands r5,r5,r4
	cmp r5,#0x1
	beq start_stop // go to start_stop
    b button_ctrl_2 
button_ctrl_2:
/* ctrl button 2 connected to A8(PA8) in IDR */
bl button_ctrl_2
	ldr r6,=GPIOA_IDR
	ldr r5,[r6]
	lsrs r5,r5,#8 // button2
	movs r4,#0x1
	ands r5,r5,r4
	cmp r5,#0x1
	beq FF     // go to function change
    bx lr
start_stop:
	ldr r6, =GPIOB_IDR
	ldr r5, [r6]
	orrs r5, r5, r4
	str r5, [r6]
	cmp r2, [0x1] // R2 Function sonlarinda artiyor
	beq F1 // countdown from 4 halil
	cmp r2, [0x2]
	beq F2 // countdown from 3 arif
	cmp r2, [0x0]
	beq F3 // countdown from 1 ömer
	ldr r6, =GPIOB_ODR
	ldr r5, [r6]
	ldr r4, =[0x8]
	bics r5, r5, r4
	str r5, [r6]
    b loop
FF:
	ldr r6, = GPIOB_IDR
	ldr r5, [r6] 
	movs r4, #0x20
	ands r5, r5, r4 // is button active
	lsrs r5, #5
	cmp r5, #0x1
	cmp r2, [0x0]
	beq F1
	cmp r2, [0x1]
	beq F2
	cmp r2, [0x2]
	beq F3
	bne loop
 F1:
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
 	/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x1414                                 // 4
	orrs r5, r5, r4
	str r5, [r6]
	ldr r1, =#5000000
	bl delay
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x1055                                 // 3
	orrs r5, r5, r4
	str r5, [r6]
	ldr r1, =#5000000
	bl delay
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x1145                                 // 2
	orrs r5, r5, r4
	str r5, [r6]
	ldr r1, =#5000000
	bl delay
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x0014                                 // 1
	orrs r5, r5, r4
	str r5, [r6]
	ldr r1, =#5000000
	bl delay
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x0555                                 // 0
	orrs r5, r5, r4
	str r5, [r6]
 	ldr r1, =#5000000
	movs r2, [0x1]
	bl delay
 F2:
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x1055                                 // 3
	orrs r5, r5, r4
	str r5, [r6]
	ldr r1, =#5000000
	bl delay
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x1145                                 // 2
	orrs r5, r5, r4
	str r5, [r6]
	ldr r1, =#5000000
	bl delay
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x0014                                 // 1
	orrs r5, r5, r4
	str r5, [r6]
	ldr r1, =#5000000
	bl delay
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x0555                                 // 0
	orrs r5, r5, r4
	str r5, [r6]
 	ldr r1, =#5000000
	bl delay
    movs r2, [0x2]
F3:
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x0014                                 // 1
	orrs r5, r5, r4
	str r5, [r6]
	ldr r1, =#5000000
	bl delay
     ldr r6,=GPIOB_MODER
     ldr r5,[r6]
     movs r4,0x0000
     ands r5,r5,r4
     str r5,[r6]
    ldr r1, =#50000
	bl delay
		/* setup PB0-6 for 7seg A to G for bits 12-13 in MODER */
	ldr r6, =GPIOB_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	ldr r4, =0x0555                                 // 0
	orrs r5, r5, r4
	str r5, [r6]
 	ldr r1, =#5000000
	bl delay
	movs r2, [0x0]
 delay:
 	subs r1,r1,#1
	bne delay
	bx lr
