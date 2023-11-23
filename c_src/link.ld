OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv",
	      "elf32-littleriscv")
OUTPUT_ARCH(riscv)
MEMORY
{
   RAM (rwx)  : ORIGIN = 0x80000000, LENGTH = 256K 
}
ENTRY(_start)
SECTIONS
{
  	.text : { 
		. = ALIGN(4);
		_stext = .;
		*(.text) 
		}
	__global_pointer$ = .;
	.data : { 
		. = ALIGN(4);
		*(.data) 
		}
	.rodata : { *(.rodata) }
	.bss : {
		. = ALIGN(4); 
		_bss_start = .;
		*(.bss) 
		*(.bss.*)
		*(.sbss)
		*(.sbss.*)		
		_bss_end = .;
		}
	.bss : {
		. = ALIGN(4);
		__end = .;
	}	
	__stack = ALIGN(4) + 0x4000;
	_uart_dreg = 0xc0000000;
	_gpio_dreg = 0xc0000008;
	_gpio_creg = 0xc000000C;
}