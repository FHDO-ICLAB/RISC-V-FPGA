`timescale 1ns / 1ps
`include "POMAA_constants.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Fabian Brünger
// 
// Create Date: 04/12/2020 06:50:23 PM
// Design Name: 
// Module Name: caemointerface
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is an interface for connection the caemo accelerator with the risc-v hardware plattform.
// The control signals are set by the core. The interface should be implemented within the top module raifes_fpga_wrapper.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//-----------------------------------  States   ---------------------------------------------------//

module caecointerface(
    input clk,
    input rst,
    //------------------------------- Signals from processor --------------------------------------//
    // enable signal for perepherie
    input           en,
    // write signal 
    input           wen,
    // adresse 
    input   [31:0]  addr,
    // data
    input   [31:0]  wdata,
    //------------------------------- Signals from dmi module direct -----------------------------//
    // data from debug module direct. Should be 0x00000001, if cmd is 1
    input   [31:0]  dm_wdata,
    // write enable from dm
    input           dm_wen,
    // command set from dm
    input           dm_cmd,    
    //------------------------------- SOut always through the processor  -------------------------//
    // final data out
    output  [31:0]  rdata,
    // interrupt
    output          res_inter,
    // led for debugging
    output          led
);
//-----------------------------------  Signale ---------------------------------------------------//
wire    [15:0]  din;
wire    [31:0]  result;
wire            invalid, inready, resultvalid, cmd;
reg     [15:0]  datahalf_r; 
reg     [3:0]   state, next_state;
reg             invalid_r, ctrl_r, led_r;

//-----------------------------------  Instantiierung Caemo --------------------------------------//
caeco caeco_inst(
    // data: in 16-Bit
    .DIN(din),
    // control signal to valid dai: in 1-Bit
    .DIN_VALID(invalid),
    // if true, data can be written: out 1-Bit
    .DIN_READY(inready),
    // has to be set, if last data is written: in 1-Bit
    .DIN_LAST(1'b0),
    //-----
    // result register: out 
    .RESULT(result),
    // valid result : out 1-Bit
    .RESULT_VALID(resultvalid),
    // cmd: in 1-Bit
    .CMD(cmd),
    // en: in 1-Bit
    .EN(1'b0), 
    //-----
    .RSTN(~rst),
    .CLK(clk)
);
//-----------------------------------  FSM signal processing Inputs-----------------------------------------//
//------------------------------------------------ LED
always@(posedge clk or posedge rst)
begin
    if(rst) begin
    led_r <= 1'b0;
    end
    else begin
        if(cmd) begin
        led_r <= 1'b1;
        end
        else if (resultvalid) begin
        led_r <= 1'b0;
        end
    end
end
//------------------------------------------------ 1
always @(posedge clk or posedge rst)
begin
    if(rst) begin
        state<=`IDLE;
    end
    else begin
        state <= next_state;
    end
end
//------------------------------------------------ 2
always@(*)
begin
        case(state)
            `IDLE: begin
            //-------------------------------- States for the direct signals from cpu
            // If adress is c0..10 -> write process start
                if (en && wen && addr==32'hc0000010) begin
                    next_state = `WDA0;
                end
            // If address is c0 .. 11 -> control signal is set for one clock
                else if (en && wen && addr==32'hc0000011) begin
                    next_state = `CTRL;           
                end
            //-------------------------------- States for the direct signals from dm
                else if (dm_cmd) begin
                    next_state = `CTRL_DM;  
                end
                else if (dm_wen) begin
                    next_state = `WDA0_DM;
                end
                else begin 
                    next_state = `IDLE; 
                end         
            end
            `WDA0: begin 
                next_state = `WDA1; 
            end
            `WDA1: begin 
                next_state = `IDLE;
            end
            `WDA0_DM: begin
                next_state = `WDA1_DM;
            end
            `WDA1_DM: begin
                next_state = `WAIT_DM;
            end
            `CTRL:      begin 
                next_state = `IDLE; 
            end
            `CTRL_DM:   begin 
                next_state = `WAIT_DM; 
            end
            `WAIT_DM:   begin 
                next_state = (dm_cmd || dm_wen) ? `WAIT_DM : 
                (en && wen && addr==32'hc0000010) ?  `WDA0 :
                `IDLE; 
            end
            
            default: next_state = `IDLE;
        endcase
end
//------------------------------------------------ 3
always@(*)
begin
    invalid_r   = 1'b0;
    ctrl_r      = 1'b0;
    datahalf_r  = 16'h0;
    case(state)
        `IDLE: begin 
            invalid_r   = 1'b0;
            ctrl_r      = 1'b0;
            datahalf_r  = 16'h0;           
        end
        `WDA0: begin 
            invalid_r   = 1'b1;
            ctrl_r      = 1'b0; 
            datahalf_r  = { wdata[23:16] ,wdata[31:24] }; 
        end
        `WDA1: begin 
            invalid_r   = 1'b1;
            ctrl_r      = 1'b0; 
            datahalf_r  = { wdata[7:0] ,wdata[15:8] } ; 
        end
        `WDA0_DM: begin 
            invalid_r   = 1'b1;
            ctrl_r      = 1'b0; 
            datahalf_r  = { dm_wdata[23:16] ,dm_wdata[31:24] }; 
        end
        `WDA1_DM: begin 
            invalid_r   = 1'b1;
            ctrl_r      = 1'b0; 
            datahalf_r  = { dm_wdata[7:0] ,dm_wdata[15:8] } ; 
        end
        `CTRL: begin 
            invalid_r   = 1'b0;
            ctrl_r      = wdata[0];
            datahalf_r  = 16'h0;   
        end
        `CTRL_DM: begin
            invalid_r   = 1'b0;
            ctrl_r      = dm_wdata[0];
            datahalf_r  = 16'h0;
        end
        `WAIT_DM: begin
            invalid_r   = 1'b0;
            ctrl_r      = 1'b0; 
            datahalf_r  = 16'h0;
        end
    endcase
end
//--------- Assign
assign cmd          = ctrl_r;
assign din          = datahalf_r;
assign invalid      = invalid_r;
assign rdata        = result;
assign res_inter    = resultvalid;
assign led          = led_r;

endmodule

