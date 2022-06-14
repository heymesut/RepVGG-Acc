// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : LKai-Xu
// Created On    : 2022/06/04 20:50
// Last Modified : 2022/06/13 14:13
// File Name     : icb_slave.v
// Description   : icb slave module
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   LKai-Xu         1.0                     Original
// -FHDR----------------------------------------------------------------------------


`define IN_ADDR_ADDR    12'h000
`define W3_ADDR_ADDR    12'h4
`define W1_ADDR_ADDR    12'h8
`define OUT_ADDR_ADDR   12'hc
`define START_ADDR      12'h10
`define MAPSIZE_ADDR    12'h14
`define ICH_ADDR        12'h18
`define OCH_ADDR        12'h1c
`define DONE_ADDR       12'h20

module icb_slave(
    // icb bus
    input               icb_cmd_valid,
    output  reg         icb_cmd_ready,
    input               icb_cmd_read,
    input       [31:0]  icb_cmd_addr,
    input       [31:0]  icb_cmd_wdata,
    input       [3:0]   icb_cmd_wmask,

    output  reg         icb_rsp_valid,
    input               icb_rsp_ready,
    output  reg [31:0]  icb_rsp_rdata,
    output              icb_rsp_err,

    // clk & rst_n
    input           clk,
    input           rst_n,

    // reg output
    output  reg [31:0]  IN_ADDR,
    output  reg [31:0]  W3_ADDR,
    output  reg [31:0]  W1_ADDR,
    output  reg [31:0]  OUT_ADDR,
    output  reg [31:0]  START,
    output  reg [31:0]  MAPSIZE,
    output  reg [31:0]  ICH,
    output  reg [31:0]  OCH,
    output  reg [31:0]  DONE,

    // finish signal from main_FSM
    input           acc_done
);

assign icb_rsp_err = 1'b0;

// cmd ready, icb_cmd_ready
always@(posedge clk)
begin
    if(!rst_n) begin
        icb_cmd_ready <= 1'b0;
    end
    else begin
        if(icb_cmd_valid & icb_cmd_ready) begin
            icb_cmd_ready <= 1'b0;
        end
        else if(icb_cmd_valid) begin
            icb_cmd_ready <= 1'b1;
        end
        else begin
            icb_cmd_ready <= icb_cmd_ready;
        end
    end
end

// ADDR and PARAM setting
always@(posedge clk)
begin
    if(!rst_n) begin
        IN_ADDR <= 32'h0;
        W3_ADDR <= 32'h0;
        W1_ADDR <= 32'h0;
        OUT_ADDR <= 32'h0;
        MAPSIZE <= 32'h0;
        ICH <= 32'h0;
        OCH <= 32'h0;
    end
    else begin
        if(icb_cmd_valid & icb_cmd_ready & !icb_cmd_read) begin
            case(icb_cmd_addr[11:0])
                `IN_ADDR_ADDR:  IN_ADDR <= icb_cmd_wdata;
                `W3_ADDR_ADDR:  W3_ADDR <= icb_cmd_wdata;
                `W1_ADDR_ADDR:  W1_ADDR <= icb_cmd_wdata;
                `OUT_ADDR_ADDR: OUT_ADDR<= icb_cmd_wdata;
                `MAPSIZE_ADDR:  MAPSIZE <= icb_cmd_wdata;
                `ICH_ADDR:  ICH <= icb_cmd_wdata;
                `OCH_ADDR:  OCH <= icb_cmd_wdata;
            endcase
        end
        else begin
            IN_ADDR <= IN_ADDR;
            W3_ADDR <= W3_ADDR;
            W1_ADDR <= W1_ADDR;
            OUT_ADDR<= OUT_ADDR;
            MAPSIZE <= MAPSIZE;
            ICH <= ICH;
            OCH <= OCH;
        end
    end
end

// START
always@(posedge clk)
begin
    if(!rst_n) begin
        START <= 32'h0;
    end
    else begin
        if(icb_cmd_valid & icb_cmd_ready & !icb_cmd_read & (icb_cmd_addr[11:0] == `START_ADDR)) begin
            START <= icb_cmd_wdata;
        end
        else if(START == 32'h0000_0001) begin
            START <= 32'h0;
        end
        else begin
            START <= START;
        end
    end
end

// DONE
always@(posedge clk)
begin
    if(!rst_n) begin
        DONE <= 32'h0;
    end
    else begin
        if(icb_cmd_valid & icb_cmd_ready & !icb_cmd_read & (icb_cmd_addr[11:0] == `DONE_ADDR)) begin
            DONE <= icb_cmd_wdata;
        end
        else if (acc_done) begin
            DONE <= 32'h1;
        end
        else begin
            DONE <= DONE;
        end
    end
end

// response valid, icb_rsp_valid
always@(posedge clk)
begin
    if(!rst_n) begin
        icb_rsp_valid <= 1'h0;
    end
    else begin
        if(icb_cmd_valid & icb_cmd_ready) begin
            icb_rsp_valid <= 1'h1;
        end
        else if(icb_rsp_valid & icb_rsp_ready) begin
            icb_rsp_valid <= 1'h0;
        end
        else begin
            icb_rsp_valid <= icb_rsp_valid;
        end
    end
end

// read data, icb_rsp_rdata
always@(posedge clk)
begin
    if(!rst_n) begin
        icb_rsp_rdata <= 32'h0;
    end
    else begin
        if(icb_cmd_valid & icb_cmd_ready & icb_cmd_read) begin
            case(icb_cmd_addr[11:0])
                `IN_ADDR_ADDR:  icb_rsp_rdata <= IN_ADDR;
                `W3_ADDR_ADDR:  icb_rsp_rdata <= W3_ADDR;
                `W1_ADDR_ADDR:  icb_rsp_rdata <= W1_ADDR;
                `OUT_ADDR_ADDR: icb_rsp_rdata <= OUT_ADDR;
                `START_ADDR:    icb_rsp_rdata <= START;
                `MAPSIZE_ADDR:  icb_rsp_rdata <= MAPSIZE;
                `ICH_ADDR:  icb_rsp_rdata <= ICH;
                `OCH_ADDR:  icb_rsp_rdata <= OCH;
                `DONE_ADDR: icb_rsp_rdata <= DONE;
            endcase
        end
        else begin
            icb_rsp_rdata <= 32'h0;
        end
    end
end

endmodule
