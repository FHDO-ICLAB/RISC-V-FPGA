`include "raifes_ctrl_constants.vh"
`include "raifes_csr_addr_map.vh"
`include "raifes_hasti_constants.vh"
`include "raifes_dmi_constants.vh"
`include "raifes_platform_constants.vh"


////////////////////////////////////////////////////////////////////////////////
// Company: Fraunhofer IMS
// Engineer: A. Stanitzki
//
// Create Date: 08.06.2018
// Design Name: raifes
// Module Name: raifes_top
// Target Device: <target device>
// Tool versions: <tool_versions>
// Description:
//    <Description here>
// Dependencies:
//    <Dependencies here>
// Revision:
//    <Code_revision_information>
// Additional Comments:
//    <Additional_comments>
////////////////////////////////////////////////////////////////////////////////			

module raifes_top(
		input                   clk,
		input                   reset,
		
		input						tck,
		input						tms,
		input						tdi,
		output					    tdo,
		
		// caeco led
		output                      caeco_led,
		
//		output	[3:0]				dm_state,
        
		// System bus port for periphery
		output					            per_en,			// enable periphery in general
		output	[`HASTI_ADDR_WIDTH-1:0]		per_haddr,
		output					            per_hwrite,
		output	[`HASTI_SIZE_WIDTH-1:0]		per_hsize,
		output	[`HASTI_BURST_WIDTH-1:0]	per_hburst,
		output					            per_hmastlock,
		output	[`HASTI_TRANS_WIDTH-1:0]	per_htrans,
		output	[`HASTI_BUS_WIDTH-1:0]		per_hwdata,		
		input	[`HASTI_BUS_WIDTH-1:0]		per_hrdata,
		input					            per_hready,
		input	[`HASTI_RESP_WIDTH-1:0]		per_hresp
		
		
		 // F.B added for simulating external interrupt
//		 input                                 ext_inter
);


	// Bei Bedarf hier das invertierte Reset-Signal
   /*wire                                            resetn;
   assign resetn = ~reset;*/

	// Instruktions-Bus
	// ================
	//
	// Aktuell f�hren Daten- und Instruktions-Bus zum gleichen 
	// (internen) BlockRAM.

   wire [`HASTI_ADDR_WIDTH-1:0]                    imem_haddr;
   wire                                            imem_hwrite;
   wire [`HASTI_SIZE_WIDTH-1:0]                    imem_hsize;
   wire [`HASTI_BURST_WIDTH-1:0]                   imem_hburst;
   wire                                            imem_hmastlock;
   wire [`HASTI_PROT_WIDTH-1:0]                    imem_hprot;
   wire [`HASTI_TRANS_WIDTH-1:0]                   imem_htrans;
   wire [`HASTI_BUS_WIDTH-1:0]                     imem_hwdata;
   wire [`HASTI_BUS_WIDTH-1:0]                     imem_hrdata;
   wire                                            imem_hready;
   wire [`HASTI_RESP_WIDTH-1:0]                    imem_hresp;

   wire [`HASTI_ADDR_WIDTH-1:0]                    imem_haddr_core;
   wire                                            imem_hwrite_core;
   wire [`HASTI_SIZE_WIDTH-1:0]                    imem_hsize_core;
   wire [`HASTI_BURST_WIDTH-1:0]                   imem_hburst_core;
   wire                                            imem_hmastlock_core;
   wire [`HASTI_PROT_WIDTH-1:0]                    imem_hprot_core;
   wire [`HASTI_TRANS_WIDTH-1:0]                   imem_htrans_core;
   wire [`HASTI_BUS_WIDTH-1:0]                     imem_hwdata_core;
   wire [`HASTI_BUS_WIDTH-1:0]                     imem_hrdata_core;
   wire                                            imem_hready_core;
   wire [`HASTI_RESP_WIDTH-1:0]                    imem_hresp_core;


   
	// Daten-Bus und Peripherie-Bus-Multiplexer
	// ========================================
	//
	// Aktuell fuehren Daten- und Instruktions-Bus zum gleichen 
	// (internen) BlockRAM.
	
	wire [`HASTI_ADDR_WIDTH-1:0]                   dmem_haddr;
   wire                                            dmem_hwrite;
   wire [`HASTI_SIZE_WIDTH-1:0]                    dmem_hsize;
   wire [`HASTI_BURST_WIDTH-1:0]                   dmem_hburst;
   wire                                            dmem_hmastlock;
   wire [`HASTI_PROT_WIDTH-1:0]                    dmem_hprot;
   wire [`HASTI_TRANS_WIDTH-1:0]                   dmem_htrans;
   wire [`HASTI_BUS_WIDTH-1:0]                     dmem_hwdata;
   wire [`HASTI_BUS_WIDTH-1:0]                     dmem_hrdata;
   wire                                            dmem_hready;
   wire [`HASTI_RESP_WIDTH-1:0]                    dmem_hresp;

   wire [`HASTI_ADDR_WIDTH-1:0]                    dmem_haddr_core;
   wire                                            dmem_hwrite_core;
   wire [`HASTI_SIZE_WIDTH-1:0]                    dmem_hsize_core;
   wire [`HASTI_BURST_WIDTH-1:0]                   dmem_hburst_core;
   wire                                            dmem_hmastlock_core;
   wire [`HASTI_PROT_WIDTH-1:0]                    dmem_hprot_core;
   wire [`HASTI_TRANS_WIDTH-1:0]                   dmem_htrans_core;
   wire [`HASTI_BUS_WIDTH-1:0]                     dmem_hwdata_core;
   wire [`HASTI_BUS_WIDTH-1:0]                     dmem_hrdata_core;
   wire                                            dmem_hready_core;
   wire [`HASTI_RESP_WIDTH-1:0]                    dmem_hresp_core;
	
	
	// die Signale vom Core zum DBUS werden einfach zu den 
	// Peripherie-Geraeten durchgeschleift..
	assign	per_haddr = dmem_haddr;
	assign	per_hwrite = dmem_hwrite;
	assign	per_hsize = dmem_hsize;
	assign	per_hburst = dmem_hburst;
	assign	per_hmastlock = dmem_hmastlock;
	//assign	per_hprot = dmem_hprot; TODO: unused, include in top I/O ?
	assign	per_htrans = dmem_htrans;
	assign	per_hwdata = dmem_hwdata;

wire	[`HASTI_BUS_WIDTH-1:0]	blockram_hrdata;
wire							blockram_hready;
wire							periphery_hready;
wire	[`HASTI_RESP_WIDTH-1:0]	blockram_hresp;
wire	[`HASTI_RESP_WIDTH-1:0]	periphery_hresp;
wire	[`HASTI_BUS_WIDTH-1:0]	hrdata_muxed;
wire							hready_muxed;
wire	[`HASTI_RESP_WIDTH-1:0]	hresp_muxed;
wire    [`HASTI_BUS_WIDTH-1:0]  caeco_hrdata;
reg     [31:0]                  dmem_haddr_r;
//---------------------------------------------- Multiplexer for reading -----------------------------------------//
// For a read instruction, the hrdata_muxed defines the word to be loaded. Its defined by adresses. Either the BRAM or Peripherie is read through the DBUS!
// set periphery enable and let periphery handle the rest of decoding.
// Before caeco:
// assign	hrdata_muxed = (dmem_haddr_r[31:28] == 4'hC) ? per_hrdata : blockram_hrdata;

//// F.B added, data from caeco. Is stable
//assign	hrdata_muxed = (dmem_haddr_r[31:28] == 4'hC) ? caeco_hrdata : blockram_hrdata;

assign	per_en		 = (dmem_haddr[31:28] == 4'hC) ? 1'b1 : 1'b0;	


// F.B added, adress multiplexer for reading gpios and caeco.         
assign	hrdata_muxed = (dmem_haddr_r == `GPIO_BASE_ADDR) ? per_hrdata : 
                       (dmem_haddr_r == `CAECO_reg) ? caeco_hrdata : 
                       blockram_hrdata;
// Syncronize dmem and reset it with reset
//or posedge nrst
always @(posedge clk)
    begin
	   if (reset) dmem_haddr_r <= 32'hDEADBEEF;
	   else  
	   dmem_haddr_r <= dmem_haddr;
	end
//---------------------------------------------- Dmi bus ---------------------------------------------------------//
wire    [`DMI_ADDR_WIDTH-1:0]								    dmi_addr;
wire    [`DMI_WIDTH-1:0]									    dmi_wdata;
wire	[`DMI_WIDTH-1:0]									    dmi_rdata;
wire															dmi_en;
wire															dmi_error;
wire															dmi_wen;
wire															dmi_dm_busy;
wire    [3:0]                                                   debug_state; // F.B added, since port of dtm is used, but no signal is assigned
//---------------------------------------------- Caeco signals ----------------------------------------------------//
wire    [`HASTI_BUS_WIDTH-1:0]      caeco_wdata;
wire                                caeco_wen, caeco_cmd, caeco_interrupt, led;

//---------------------------------------------- The core ---------------------------------------------------------//
raifes_core raifes(
    .reset(reset),
    .clk(clk),
//    .ext_interrupts(`N_EXT_INTS'h0),
    .ext_interrupts({23'h0,caeco_interrupt}),
//    .ext_interrupts({23'h0,ext_inter}),
						
    .imem_haddr(imem_haddr_core),
    .imem_hwrite(imem_hwrite_core),
    .imem_hsize(imem_hsize_core),
    .imem_hburst(imem_hburst_core),
    .imem_hmastlock(imem_hmastlock_core),
    .imem_hprot(imem_hprot_core),
    .imem_htrans(imem_htrans_core),
    .imem_hwdata(imem_hwdata_core),
    .imem_hrdata(imem_hrdata_core),
    .imem_hready(1'b1), // imem_hready),
    .imem_hresp(1'b0), // imem_hresp),
						 
    .dmem_haddr(dmem_haddr_core),
    .dmem_hwrite(dmem_hwrite_core),
    .dmem_hsize(dmem_hsize_core),
    .dmem_hburst(dmem_hburst_core),
    .dmem_hmastlock(dmem_hmastlock_core),
    .dmem_hprot(dmem_hprot_core),
    .dmem_htrans(dmem_htrans_core),
    .dmem_hwdata(dmem_hwdata_core),
    .dmem_hrdata(dmem_hrdata_core),
    .dmem_hready(dmem_hready_core), 
    .dmem_hresp(1'b0), // dmem_hresp), TODO
			
    .dmi_addr(dmi_addr),
    .dmi_en(dmi_en),
    .dmi_error(dmi_error),
    .dmi_wen(dmi_wen),
    .dmi_wdata(dmi_wdata),
    .dmi_rdata(dmi_rdata),
    .dmi_dm_busy(dmi_dm_busy),
			
    .caeco_wdata(caeco_wdata),
    .caeco_rdata(caeco_hrdata),
    .caeco_wen(caeco_wen),
    .caeco_cmd(caeco_cmd)
); 


//---------------------------------------------- The dtm module ---------------------------------------------------------//

raifes_dtm	dtm(
		.tck(tck),
		.tms(tms),
		.tdi(tdi),
		.tdo(tdo),		
		.dmi_addr(dmi_addr),
		.dmi_en(dmi_en),
		.dmi_error(dmi_error),
		.dmi_wen(dmi_wen),
		.dmi_wdata(dmi_wdata),
		.dmi_rdata(dmi_rdata),
		.dmi_dm_busy(dmi_dm_busy),
		.debug_state(debug_state)
		);

raifes_sync_to_hasti_bridge imem_bridge(
				   .clk(clk),
		 		   .reset(reset),
                                   .dev_haddr(imem_haddr),
                                   .dev_hwrite(imem_hwrite),
                                   .dev_hsize(imem_hsize),
                                   .dev_hburst(imem_hburst),
                                   .dev_hmastlock(imem_hmastlock),
                                   .dev_hprot(imem_hprot),
                                   .dev_htrans(imem_htrans),
                                   .dev_hwdata(imem_hwdata),
                                   .dev_hrdata(imem_hrdata),
                                   .dev_hready(1'b1),
                                   .dev_hresp(1'b0),

                                   .core_haddr(imem_haddr_core),
                                   .core_hwrite(imem_hwrite_core),
                                   .core_hsize(imem_hsize_core),
                                   .core_hburst(imem_hburst_core),
                                   .core_hmastlock(imem_hmastlock_core),
                                   .core_hprot(imem_hprot_core),
                                   .core_htrans(imem_htrans_core),
                                   .core_hwdata(imem_hwdata_core),
                                   .core_hrdata(imem_hrdata_core),
                                   .core_hready(imem_hready_core),
                                   .core_hresp(imem_hresp_core)
                                   );

raifes_sync_to_hasti_bridge dmem_bridge(
				   .clk(clk),
		 		   .reset(reset),
                                   .dev_haddr(dmem_haddr),
                                   .dev_hwrite(dmem_hwrite),
                                   .dev_hsize(dmem_hsize),
                                   .dev_hburst(dmem_hburst),
                                   .dev_hmastlock(dmem_hmastlock),
                                   .dev_hprot(dmem_hprot),
                                   .dev_htrans(dmem_htrans),
                                   .dev_hwdata(dmem_hwdata),
                                   .dev_hrdata(hrdata_muxed),
                                   .dev_hready(1'b1),
                                   .dev_hresp(1'b0),

                                   .core_haddr(dmem_haddr_core),
                                   .core_hwrite(dmem_hwrite_core),
                                   .core_hsize(dmem_hsize_core),
                                   .core_hburst(dmem_hburst_core),
                                   .core_hmastlock(dmem_hmastlock_core),
                                   .core_hprot(dmem_hprot_core),
                                   .core_htrans(dmem_htrans_core),
                                   .core_hwdata(dmem_hwdata_core),
                                   .core_hrdata(dmem_hrdata_core),
                                   .core_hready(dmem_hready_core),
                                   .core_hresp(dmem_hresp_core)
                                   );									 
									 
wire	[3:0]	writea; assign writea = ~dmem_hwrite ? 4'b0000 :
					 per_en ? 4'b0000 :					
					(dmem_hsize == 2) ? 4'b1111 :
					(dmem_hsize == 1) ? (4'b0011 << dmem_haddr[1:0]) :
					(dmem_hsize == 0) ? (4'b0001 << dmem_haddr[1:0]) :
					4'b0000;

wire	[3:0]	writeb; assign writeb = ~imem_hwrite ? 4'b0000 : 
					per_en ? 4'b0000 : 
					(imem_hsize == 2) ? 4'b1111 :
					(imem_hsize == 1) ? (4'b0011  << imem_haddr[1:0]) :
					(imem_hsize == 0) ? (4'b0001  << imem_haddr[1:0]) :
					4'b0000;

blk_mem_gen_0 bram01 (
    .clka(clk),
    .wea(writea), 
    .addra({2'b0,dmem_haddr[29:0]}),  
    .dina(dmem_hwdata), 
    .douta(blockram_hrdata),

    .clkb(clk),  
    .web(writeb), 
    .addrb({2'b0,imem_haddr[29:0]}),  
    .dinb(imem_hwdata),   
    .doutb(imem_hrdata) 
);

// commend!
caecointerface caecointerface_inst(
    .clk(clk),
    .rst(reset),
    .en(per_en),
    .wen(per_hwrite),
    .addr(per_haddr),
    .wdata(per_hwdata),
    .rdata(caeco_hrdata),
    .res_inter(caeco_interrupt),
    .dm_wdata(caeco_wdata),
    .dm_wen(caeco_wen),
    .dm_cmd(caeco_cmd),
    .led(led)
    );



reg [31:0] debug_out;
reg [31:0] debug_addr;
reg	   debug_hwrite;

always @(posedge clk) begin
	debug_addr <= dmem_haddr;
	debug_hwrite <= dmem_hwrite;
	if((debug_addr == 32'h80001000) && (debug_hwrite))
		debug_out <= dmem_hwdata;
end


//---------------------------------------------- assignments ---------------------------------------------------------//

assign caeco_led    = led;


endmodule // raifes_sim_top