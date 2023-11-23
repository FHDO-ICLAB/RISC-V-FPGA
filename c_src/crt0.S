// section declaration
.section .text
.align 1
// entry point for linker script
.globl _start
.type _start, @function
_start:
	// risc-v standard initialisation
	.cfi_startproc
	.cfi_undefined ra
	.option push
	.option norelax
	la		gp, __global_pointer$
	.option pop
	la		sp, __stack
	// referencing the interrupt function
	.globl exception_handler
	.type exception_handler, @function
	// referencing the interrupt function
	.globl l_1_caeco_interrupt_handler
	.type l_1_caeco_interrupt_handler, @function
	// write the mstatus register, to enable the interrupts
	csrwi mstatus, 0x1F
	// loading the handler address
//	la		x29, l_0_caeco_interrupt_handler
	la		x29, trap_handler
	csrw	mtvec, x29
	//	clear GPRs
	mv		x1, x0
	mv		x2, x1
	mv		x3, x1
	mv		x4, x1
	mv		x5, x1
	mv		x6, x1
	mv		x7, x1
	mv		x8, x1
	mv		x9, x1
	mv		x10, x1
	mv		x11, x1
	mv		x12, x1
	mv		x13, x1
	mv		x14, x1
	mv		x15, x1
	mv		x16, x1
	mv		x17, x1
	mv		x18, x1
	mv		x19, x1
	mv		x20, x1
	mv		x21, x1
	mv		x22, x1
	mv		x23, x1
	mv		x24, x1
	mv		x25, x1
	mv		x26, x1
	mv		x27, x1
	mv		x28, x1
	mv		x29, x1
	mv		x30, x1
	mv		x31, x1

	la x26, _bss_start
	la x27, _bss_end
	bge x26, x27, zero_loop_end

	zero_loop:
		sw x0, 0(x26)
		addi x26, x26, 4
		ble x26, x27, zero_loop
	zero_loop_end:
	// added in the c code
	call main
	//jal zero, main
.cfi_endproc
//---------------------------------------------------
1:
	j		1b
//---------------------------------------------------
trap_handler:
	// csrr a0, mcause
	j exception_handler
	j l_1_caeco_interrupt_handler
	mret



