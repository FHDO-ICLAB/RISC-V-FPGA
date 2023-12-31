`define N_EXT_INTS 24

`define ADDR_DEBUG_ROM 		1'b0
`define ADDR_IMEM		1'b1
`define ADDR_HART0_STATUS	`XPR_LEN'h00000144
`define ADDR_HART0_STACK	`XPR_LEN'h00000140
`define ADDR_HART0_POSTEXEC `XPR_LEN'h00000148




`define START_ADDRESS `XPR_LEN'h80000000
`define DEBUG_ADDRESS `XPR_LEN'h00000000

// Periphery Adress mappings
// 0xC0000000 - 0xCfffffff

`define PER_MASK	`HASTI_BUS_WIDTH'h40000000
`define UART_reg       `HASTI_BUS_WIDTH'hC0000000    //Bits: 9=uart_reset, 8=send_strobe, 7-0=data_byte
`define GPIO_BASE_ADDR	32'hC0000008
`define CAECO_reg       `HASTI_BUS_WIDTH'hc00000c0      // F.B added: Caeco virtuell address. Also has to be mentioned in linker script! (S.G. This address is not mention in .ld?)

`define PRINCE_in0      `HASTI_BUS_WIDTH'hC0001000
`define PRINCE_in1      `HASTI_BUS_WIDTH'hC0001004
`define PRINCE_out0     `HASTI_BUS_WIDTH'hC0001008
`define PRINCE_out1     `HASTI_BUS_WIDTH'hC000100C
`define PRINCE_key0     `HASTI_BUS_WIDTH'hC0001010
`define PRINCE_key1     `HASTI_BUS_WIDTH'hC0001014
`define PRINCE_key2     `HASTI_BUS_WIDTH'hC0001018
`define PRINCE_key3     `HASTI_BUS_WIDTH'hC000101C
`define PRINCE_ctrl     `HASTI_BUS_WIDTH'hC0001020

`define KTANTAN32_in    `HASTI_BUS_WIDTH'hC0002000
`define KTANTAN32_out   `HASTI_BUS_WIDTH'hC0002004
`define KTANTAN32_key0  `HASTI_BUS_WIDTH'hC0002008
`define KTANTAN32_key1  `HASTI_BUS_WIDTH'hC000200C
`define KTANTAN32_key2  `HASTI_BUS_WIDTH'hC0002010
`define KTANTAN32_ctrl  `HASTI_BUS_WIDTH'hC0002014

