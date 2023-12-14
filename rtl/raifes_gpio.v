// 
//	raifes_gpio
//
`include "raifes_hasti_constants.vh"

//`define GPIO_BASE_ADDR	32'hC00000008
/*
module raifes_gpio(
		// system clk and reset
		input			reset,
		input			clk,

		// gpio in/outputs
		output	reg	[7:0]	gpio_d,
		output	reg	[7:0]	gpio_en,
		input		[7:0]	gpio_i,

		// system bus 
	        input	[`HASTI_ADDR_WIDTH-1:0]  haddr,
        	input				hwrite,			// unused, as imem is read-only (typically)
	        input	[`HASTI_SIZE_WIDTH-1:0]  hsize,
		    input	[`HASTI_BURST_WIDTH-1:0] hburst,
	        input 			   	hmastlock,
	        input	[`HASTI_PROT_WIDTH-1:0]  hprot,
	        input	[`HASTI_TRANS_WIDTH-1:0] htrans,
	        input	[`HASTI_BUS_WIDTH-1:0]   hwdata,			// unused, as imem is read-only (typically)
	        output	reg	[`HASTI_BUS_WIDTH-1:0]    hrdata,
	        output 	reg			   	hready,
	        output	reg	[`HASTI_RESP_WIDTH-1:0]   hresp       //F.B uncommented, since it is not used in fpga_wrapper
);


`define GPIO_IDLE 0
`define GPIO_READ_D 1
`define GPIO_READ_EN 2
`define GPIO_WRITE_D 3
`define GPIO_WRITE_EN 4
`define GPIO_Sel 5

reg	[2:0]	state, next_state;
reg	[`HASTI_ADDR_WIDTH-1:0]	addr_r;	// hold addr in case of write operations

always @(posedge clk) begin
	if(reset) begin 
		state <= `GPIO_IDLE;
	end else begin
		state <= next_state;


		if(next_state == `GPIO_READ_D) begin
			hrdata <= {gpio_i,gpio_i,gpio_i,gpio_i};
		end else
		if(next_state == `GPIO_READ_EN) begin
			hrdata <= {gpio_en,gpio_en,gpio_en,gpio_en};
		end else
		if(next_state == `GPIO_WRITE_D) begin
			gpio_d <= hwdata[7:0];
		end else
		if(next_state == `GPIO_WRITE_EN) begin
			gpio_en <= hwdata[7:0];
		end
	end
end

always @(*) begin
	hready = 1'b0;
	case (state) 
//		`GPIO_IDLE	:	begin
//					hready = 1'b1;
//					if((haddr == `GPIO_BASE_ADDR) && |htrans) begin
//						next_state = |hwrite ? `GPIO_WRITE_D : `GPIO_READ_D;
//					end else 
//					if((haddr == `GPIO_BASE_ADDR+4) && |htrans) begin
//						next_state = |hwrite ? `GPIO_WRITE_EN : `GPIO_READ_EN;
//					end else next_state = `GPIO_IDLE;
//				end
				
		// --- S.G timing_issue_modif begin
		`GPIO_IDLE	:	begin
					hready = 1'b1;
					if( ((haddr == `GPIO_BASE_ADDR) && |htrans) || ((haddr == `GPIO_BASE_ADDR+4) && |htrans) ) begin
						next_state = `GPIO_Sel;
					end else next_state = `GPIO_IDLE;
				end		
				
		`GPIO_Sel	:	begin
					if(haddr == `GPIO_BASE_ADDR) begin
						next_state = |hwrite ? `GPIO_WRITE_D : `GPIO_READ_D;
					end else 
					if(haddr == `GPIO_BASE_ADDR+4) begin
						next_state = |hwrite ? `GPIO_WRITE_EN : `GPIO_READ_EN;
					end else next_state = `GPIO_Sel;
				end		
		// --- timing issue modif
		
		`GPIO_READ_D	:	begin
					next_state = `GPIO_IDLE;		
				end
		`GPIO_WRITE_D :	begin
					next_state = `GPIO_IDLE;
				end
		`GPIO_READ_EN : 	begin 
					next_state = `GPIO_IDLE;
				end
		`GPIO_WRITE_EN :	begin 
					next_state = `GPIO_IDLE;
				end
	endcase
end
*/

module raifes_gpio( 
  // system clk and reset
  input     reset,
  input     clk,

  // gpio in/outputs
  output  reg [7:0]            gpio_d,
  output  reg [7:0]            gpio_en,
  input   [7:0]                gpio_i,

  // system bus 
  input [`HASTI_ADDR_WIDTH-1:0]      haddr,
  input                              hwrite,     // unused, as imem is read-only (typically)
  input [`HASTI_SIZE_WIDTH-1:0]      hsize,
  input [`HASTI_BURST_WIDTH-1:0]     hburst,
  input                              hmastlock,
  input [`HASTI_PROT_WIDTH-1:0]      hprot,
  input [`HASTI_TRANS_WIDTH-1:0]     htrans,
  input [`HASTI_BUS_WIDTH-1:0]       hwdata,      // unused, as imem is read-only (typically)
  output  reg [`HASTI_BUS_WIDTH-1:0] hrdata,
  output                             hready,
  output    [`HASTI_RESP_WIDTH-1:0]  hresp
);

reg [`HASTI_ADDR_WIDTH-1:0] haddr_r;
reg                         hwrite_r;
reg wr, rd;

always @(posedge clk or posedge reset) begin
  if(reset)
    haddr_r <= 0;
  else 
    haddr_r <= haddr;   
end

always @(posedge clk or posedge reset) begin
  if(reset)
    hwrite_r <= 0;
  else 
    hwrite_r <= hwrite;
end

always @(posedge clk or posedge reset) begin
  if(reset) begin
    hrdata   <= 0;
    gpio_d   <= 0;
    gpio_en  <= 0; 
    wr <= 0;
    rd <= 0;
  end
  else
  begin
    if(hwrite_r) begin
      case(haddr_r)
        (`GPIO_BASE_ADDR)   : begin
                                gpio_d <= hwdata[7:0];
                                wr <= 1;
                              end
        (`GPIO_BASE_ADDR+4) : gpio_en <= hwdata[7:0];
        default       :;
      endcase 
    end
    else begin
    wr <= 0;
    if(|htrans) begin
      case(haddr)
        (`GPIO_BASE_ADDR) : begin
                                hrdata <= gpio_i;
                                rd <= 1;
                            end
        (`GPIO_BASE_ADDR+4) : begin
                                hrdata <= gpio_en;
                                rd <= 0;
                              end
        default: rd <= 0;
      endcase
    end
    else rd <= 0;
    end
  end
end

// the core complex peripherals will always 
// handle read/writes in one cycle, so they will 
// never issue wait cycles. Hence hready is always 1'b1
assign hready = 1'b1;
assign hresp = 0;

endmodule
