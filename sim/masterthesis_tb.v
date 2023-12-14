`timescale 1ns / 1ns

`include "raifes_hasti_constants.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company:         FH Dortmund
// Engineer:        Fabian Brünger
// 
// Create Date:     12.07.2019 09:50:36
// Design Name: 
// Module Name:     masterthesis_tb
// Project Name:    POMAA
// Target Devices:  Nexys4 DDR
// Tool Versions:   01
// Description:     Complete testbench:
//                  1) BRAM Initialisation through .coe file. Pre-Synthesis or writing BRAM in testbench
//                  2) Writing caeco through core or writing it through dmi
//                  3) 
//////////////////////////////////////////////////////////////////////////////////

module masterthesis_tb();
//----------------------------------------- signals, registers -------------------------------------------//
// mandatory:
reg             CLK, RESET, tck, tms, tdi;
reg     [31:0]  result;
reg     [31:0]  result_bram;
integer         testcase, i;
wire            nRESET;
// optional (depending on tasks selected)
// writing mem file in bram
 reg     [31:0]  memimg_bram[2167:0];
// ------
// optional
// writing .ecg data thorugh mcu
 reg     [63:0]  memimg_caeco_mcu[15450-1:0];
 reg     [63:0]  buff_caeco_mcu;
 reg     [31:0]  sample_caeco_mcu;
 integer         mcd_caeco_mcu;
// ------
// optional
// writing .ecg data through dmi
//reg     [63:0]  memimg_caeco_dmi[30805-1:0];
//reg     [63:0]  buff_caeco_dmi;
//reg     [31:0]  sample_caeco_dmi;
//integer         mcd_caeco_dmi;

//----------------------------------------- DUT ----------------------------------------------------------//
raifes_fpga_wrapper DUT(
        .clk_raw(CLK),
        .nRESET(nRESET),
        .TCK(tck),
        .TDI(tdi),
        .TDO(tdo),
        .TMS(tms),
        .uart_tx(uart_tx),
        .led(ledout),
        .sw(8'b00000000),
        .btnu(1'b1),
        .btnd(1'b1),
        .btnl(1'b1),
        .btnr(1'b1),
        .btnc(1'b1)
        // added for testing the hardware interrupt. only needed if caeco is not connected to interrupt
        // .ext_inter(ext_inter)
);
//----------------------------------------- mandatory -----------------------------------------------------//
assign nRESET = ~RESET;
// clock setting on 100 MHz for board clock -> 25 MHz mcu clock
always 
begin
    CLK = 1'b1;
    #5;
    CLK = ~CLK;
    #5;
//	#5
//	CLK = ~CLK;
end

//`define CLK_PERIOD 50
// speed up JTAG -> 20 MHz
`define CLK_PERIOD 10
`include "jtag_tasks.vh"
//----------------------------------------- JTAG Task definitions ----------------------------------------//
//----------------------------------------- BRAM write ---------------------------------------------------//
//select this task, if bram has to be written in testbench//
 task bram_write_mcu;
 input   reg[7:0]	        testnum;
 input   reg[255*8:1]	    filename;
 input   reg[15:0]	    length;
 output  reg[31:0]        result;
 begin
  $write("JTAG Task Start: write BRAM through mcu!");
 	$write("Read mem file for testcase. BRAM should be written!");
 	// read program into buffer //
 	$readmemh(filename,memimg_bram);
 	for (i = 0; i < length; i = i + 1) begin
 		jtag_write_mem(32'h80000000 + i*4,memimg_bram[i],result);
 	end
 	$write("writing the programmcode is finished. Reseting the core!");
 	#50000 RESET <= 1'b1;
 	#50000 RESET <= 1'b0;
  $write("JTAG Task End: write BRAM through mcu!");
 end
 endtask
 
//----------------------------------------- caeco mcu ---------------------------------------------------//
 task caeco_write_mcu;
 input   reg[7:0]	    testnum;
 input   reg[255*8:1]	filename;
 input   reg[15:0]	    length;
 output  reg[31:0]       result;
 begin
     $write("JTAG Task Start: write Caeco through mcu!");
 	//----------
 	// Set cmd signal through SW instruction. Address 32'hc0000011
     $write("Set the caemo signal cmd \n");
     jtag_write_mem(32'hc0000011,32'h00000000,result);
     jtag_write_mem(32'hc0000011,32'h00000010,result);
     jtag_write_mem(32'hc0000011,32'h00000011,result);
 	$write("Read ecg file for real testcase\n");
     // read file as binary
     mcd_caeco_mcu = $fopen(filename, "rb");
     $fread(memimg_caeco_mcu, mcd_caeco_mcu);
     $write("write the EKG data through store instructions into the caeco\n");
 	for (i = 49; i < length; i = i + 1) begin
 	   // 64 - Bit = 2 Datasamples
 	   // get Sample 1 = 32 MSB
 	   buff_caeco_mcu = memimg_caeco_mcu[i];
 	   sample_caeco_mcu = buff_caeco_mcu[63:32];
 	   $write("writing 1st-half of sample ");$write(i);$write(": ");$write(sample_caeco_mcu);$write("\n");
 	   jtag_write_mem(32'hc0000010,sample_caeco_mcu,result);
 	   // get Sample 1 = 32 MSB
        sample_caeco_mcu = buff_caeco_mcu[31:0];
        $write("writing 2nd-half of sample ");$write(i);$write(": ");$write(sample_caeco_mcu);$write("\n");
        jtag_write_mem(32'hc0000010,sample_caeco_mcu,result);
 	end
     $write("JTAG Task End: write Caeco through mcu!");
     jtag_write_mem(32'hc0000011,32'h00000018,result);
 end
 endtask
//----------------------------------------- caeco dmi ---------------------------------------------------//

//task caeco_write_dmi;
//input   reg[7:0]	    testnum;
//input   reg[255*8:1]	filename;
//input   reg[15:0]	    length;
//output  reg[31:0]       result;
//begin
//    $write("JTAG Task Start: write Caeco through dmi!");
//	// set cmd signal directly with dmi address of 23
//    $write("Set the caemo signal cmd \n");
//    jtag_write_caeco(6'h23,32'h00000000,result);
//    jtag_write_caeco(6'h23,32'h00000010,result);
//    jtag_write_caeco(6'h23,32'h00000011,result);
//    // write the data
//	$write("Read ecg file for real testcase\n");
//    mcd_caeco_dmi = $fopen(filename, "rb");
//    $fread(memimg_caeco_dmi, mcd_caeco_dmi);
//    // write the data via jtag directly through the dm
//	for (i = 49; i < length; i = i + 1) begin
//	   // 64 - Bit = 2 Datasamples
//	   // get Sample 1 = 32 MSB
//	   buff_caeco_dmi = memimg_caeco_dmi[i];
//	   sample_caeco_dmi = buff_caeco_dmi[63:32];
//	   // check if value is not zero (for last sample)
//	   if (sample_caeco_dmi != 32'h0) begin
//	       $write("writing sample: ");$write(sample_caeco_dmi);$write("\n");
//           jtag_write_caeco(6'h22,sample_caeco_dmi,result); 
//	   end
//	   // get Sample 1 = 32 MSB
//       sample_caeco_dmi = buff_caeco_dmi[31:0];
//       if (sample_caeco_dmi != 32'h0)begin
//            $write("writing sample 2: ");$write(sample_caeco_dmi);$write("\n");
//            jtag_write_caeco(6'h22,sample_caeco_dmi,result);
//       end
//	end
//    $write("JTAG Task End: write Caeco through dmi!");
//    jtag_write_caeco(6'h23,32'h00000018,result);

//end
//endtask
//----------------------------------------- rst ----------------------------------------------------------//
//initial
//begin
//    RESET = 1;
//    #2000000;
//    RESET = 0;
//end


//----------------------------------------- Testbench start! ---------------------------------------------//
initial begin
	$write("Testbench is starting! \n");
	RESET <= 1'b1; tms <= 1'b0; tdi <= 1'b0; tck <= 1'b0; i <= 32'h0;
	$write("Wait for BRAM ");
	#2000000;
	RESET <= 1'b0;
	$write("JTAG TAP: reset..\n");
	jtag_tap_reset;
    $write("Initializing finished! Now starting with the testcases \n");

    // optional: writing programmcode through mcu
    //bram_write_mcu(1,"POOMAV1_0Sim.mem",2167,result_bram);

    // writing caeco through mcu
        // caeco_write_mcu(1,"00019fb0-6b6a-4ccf-b818-b52221ec524c.ecg",15401,result);
        //caeco_write_mcu(1,"00019fb0-6b6a-4ccf-b818-b52221ec524c.ecg",5116,result);
    // writing caeco directly through dmi
    //    caeco_write_dmi(1,"00019fb0-6b6a-4ccf-b818-b52221ec524c.ecg",30804,result);
        //caeco_write_dmi(1,"00019fb0-6b6a-4ccf-b818-b52221ec524c.ecg",1116,result); // Not getting correct result, not enough samples!!
        //caeco_write_dmi(1,"00019fb0-6b6a-4ccf-b818-b52221ec524c.ecg",5116,result);     // Min recommended
        //364ms
    $write("let the mcu run 500ms!");
    #30000000
    jtag_dmi_read(6'h24,result);  // At this point there should be a valid result
    #50000000;

    $finish();
end // initial
endmodule