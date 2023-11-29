`timescale 1ns / 1ps
`include "caecointerface_constants.vh"
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
wire            in_ready;
reg     [31:0]  data; 
reg     [3:0]   state, next_state;
reg             in_valid;
(*mark_debug = 1*) reg     [31:0]  caecoif_ctrl_r, caecoif_ctrl;

//-----------------------------------  Instantiierung Caemo --------------------------------------//
caeco caeco_inst(
    // data: in 16-Bit
    .DIN(data),
    // control signal to valid dai: in 1-Bit
    .DIN_VALID(in_valid),
    // if true, data can be written: out 1-Bit
    .DIN_READY(in_ready),
    // has to be set, if last data is written: in 1-Bit
    .DIN_LAST(caecoif_ctrl_r[3]),
    //-----
    // result register: out 
    .RESULT(rdata),
    // valid result : out 1-Bit
    .RESULT_VALID(res_inter),
    // cmd: in 1-Bit
    .CMD(caecoif_ctrl_r[1:0]),
    // en: in 1-Bit
    .EN(caecoif_ctrl_r[2]), 
    //-----
    .RSTN((~rst) & caecoif_ctrl_r[4]),
    .CLK(clk)
);
//-----------------------------------  FSM signal processing Inputs-----------------------------------------//
//------------------------------------------------ LED
//always@(posedge clk or posedge rst)
//begin
//    if(rst) begin
//    led <= 1'b0;
//    end
//    else begin
//        if(cmd) begin
//        led <= 1'b1;
//        end
//        else if (res_inter) begin
//        led <= 1'b0;
//        end
//    end
//end
//------------------------------------------------ 1
always @(posedge clk or posedge rst)
begin
    if(rst) begin
        state<=`IDLE;
        caecoif_ctrl_r <= 0;
    end
    else begin
        state <= next_state;
        if (state == `CTRL_DM ||state == `CTRL)
            caecoif_ctrl_r <= caecoif_ctrl;
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
                next_state = `IDLE; 
            end
            `WDA0_DM: begin
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
    in_valid     = 1'b0;
    caecoif_ctrl = 0;
    data         = 16'h0;
    
    case(state)
        `IDLE: begin 
            in_valid     = 1'b0;
            data         = 16'h0;           
        end
        `WDA0: begin 
            in_valid     = 1'b1;
            data         = { wdata[23:16] ,wdata[31:24], wdata[7:0] ,wdata[15:8] }; 
        end
        `WDA0_DM: begin 
            in_valid     = 1'b1;
            data         = { dm_wdata[23:16] ,dm_wdata[31:24], dm_wdata[7:0] ,dm_wdata[15:8] }; 
        end
        `CTRL: begin 
            in_valid     = 1'b0;
            caecoif_ctrl = wdata;
            data         = 16'h0;   
        end
        `CTRL_DM: begin
            in_valid     = 1'b0;
            caecoif_ctrl = dm_wdata;
            data         = 16'h0;
        end
        `WAIT_DM: begin
            in_valid     = 1'b0;
            data         = 16'h0;
        end
    endcase
end
endmodule

