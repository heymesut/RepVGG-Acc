// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 21:43
// Last Modified : 2022/06/09 22:14
// File Name     : icb_master.v
// Description   : icb master interface with an arbiter
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module icb_master
(
input                           clk,
input                           rst_n,

// weight biu to arbiter req signal
input                           weight_biu2arb_req,
input [31:0]                    weight_biu2arb_addr,
input                           weight_biu2arb_vld,
output  wire                    weight_biu2arb_rdy,

// weight biu to arbiter rsp signal
output  reg [31:0]                  arb2weight_biu_addr,
output  [31:0]                  arb2weight_biu_data,
output                          arb2weight_biu_vld,
input                           arb2weight_biu_rdy,

// imap biu to arbiter req signal
input                           imap_biu2arb_req,
input [31:0]                    imap_biu2arb_addr,
input                           imap_biu2arb_vld,
output                          imap_biu2arb_rdy,

// imap biu to arbiter rsp signal
output  reg [31:0]                  arb2imap_biu_addr,
output  [31:0]                  arb2imap_biu_data,
output                          arb2imap_biu_vld,
input                           arb2imap_biu_rdy,

// omap biu to arbiter req signal
input                           omap_biu2arb_req,
input [31:0]                    omap_biu2arb_addr,
input [31:0]                    omap_biu2arb_data,
input                           omap_biu2arb_vld,
output                          omap_biu2arb_rdy,

// icb master interface
output                          acc_icb_cmd_valid,
input                           acc_icb_cmd_ready,
output [31:0]                   acc_icb_cmd_addr,
output                          acc_icb_cmd_read,
output [31:0]                   acc_icb_cmd_wdata,
output [3:0]                    acc_icb_cmd_wmask,

input                           acc_icb_rsp_valid,
output                          acc_icb_rsp_ready,
input                           acc_icb_rsp_err  ,
input  [31:0]                   acc_icb_rsp_rdata
);

reg [2:0] nextstate;
reg [2:0] state;
wire fifo_empty;
wire fifo_full;
reg [31:0] fifo [15:0];
reg [4:0] input_cnt;
reg [4:0] output_cnt;

// arbiter FSM nextstate
always@(posedge clk)
begin
    if(!rst_n) begin
        nextstate <= 3'b0;
    end
    else begin
        case(state)
            3'b000: begin
                        if(omap_biu2arb_req) begin
                            nextstate <= 3'b001;
                        end
                        else if(weight_biu2arb_req) begin
                            nextstate <= 3'b010;
                        end
                        else if(imap_biu2arb_req) begin
                            nextstate <= 3'b100;
                        end
                    end
            3'b001: begin
                        if(!omap_biu2arb_req) begin
                            nextstate <= 3'b000;
                        end
                        else begin
                            nextstate <= 3'b001;
                        end
                    end
            3'b010: begin
                        if(!weight_biu2arb_req & fifo_empty) begin
                            nextstate <= 3'b000;
                        end
                        else begin
                            nextstate <= 3'b010;
                        end
                    end
            3'b100: begin
                        if(imap_biu2arb_req & fifo_empty) begin
                            nextstate <= 3'b000;
                        end
                        else begin
                            nextstate <= 3'b100;
                        end
                    end
            default:begin
                        nextstate <= 3'b0;
                    end
        endcase
    end
end

// arbiter FSM state
always@(posedge clk)
begin
    if(!rst_n) begin
        state <= 3'b0;
    end
    else begin
        state <= nextstate;
    end
end

// fifo
// fifo stores the addr of weight/input
integer i;
always@(posedge clk)
begin
    if(!rst_n) begin
        for(i=0;i<16;i=i+1) begin
            fifo[i] <= 32'h0;
        end
    end
    else begin
        case(state)
            3'b010: begin
                        if(weight_biu2arb_vld & weight_biu2arb_rdy) begin
                            fifo[input_cnt[3:0]] <= weight_biu2arb_addr;
                        end
                    end
            3'b100: begin
                        if(imap_biu2arb_vld & imap_biu2arb_rdy) begin
                            fifo[input_cnt[3:0]] <= imap_biu2arb_addr;
                        end
                    end
            default:begin
                        for(i=0;i<16;i=i+1) begin
                            fifo[i] <= 32'h0;
                        end
                    end
        endcase
    end
end

// fifo input counter
always@(posedge clk)
begin
    if(!rst_n) begin
        input_cnt <= 5'b0;
    end
    else begin
        case(state)
            3'b010: begin
                        if(weight_biu2arb_vld & weight_biu2arb_rdy) begin
                            input_cnt <= input_cnt + 1;
                        end
                    end
            3'b100: begin
                        if(imap_biu2arb_vld & imap_biu2arb_rdy) begin
                            input_cnt <= input_cnt + 1;
                        end
                    end
            default:begin
                        input_cnt <= 5'b0;
                    end
        endcase
    end
end

// fifo output counter
always@(posedge clk)
begin
    if(!rst_n) begin
        output_cnt <= 5'b0;
    end
    else begin
        case(state)
            3'b010: begin
                        if(arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            output_cnt <= output_cnt + 1;
                        end
                    end
            3'b100: begin
                        if(arb2imap_biu_vld & arb2imap_biu_rdy) begin
                            output_cnt <= output_cnt + 1;
                        end
                    end
            default:begin
                        output_cnt <= 5'b0;
                    end
        endcase
    end
end

// fifo_empty
assign fifo_empty = (input_cnt == output_cnt) ? 1 : 0;

// fifo_full
assign fifo_full = ((input_cnt[3:0] == output_cnt[3:0]) & (input_cnt[4] != output_cnt[4])) ? 1 : 0;

// weight biu to arbiter req signal
// weight_biu2arb_rdy
assign weight_biu2arb_rdy = (state == 3'b010) ? 1 : 0;

// weight biu to arbiter rsp signal
// arb2weight_biu_addr
always@(posedge clk)
begin
    if(!rst_n) begin
        arb2weight_biu_addr <= 32'b0;
    end
    else begin
        if(state == 3'b010) begin
            arb2weight_biu_addr <= fifo[output_cnt];
        end
        else begin
            arb2weight_biu_addr <= 32'b0;
        end
    end
end

// arb2weight_biu_data
assign arb2weight_biu_data = (arb2weight_biu_vld & arb2weight_biu_rdy) ? acc_icb_rsp_rdata : 0;

// arb2weight_biu_vld
assign arb2weight_biu_vld = (state == 3'b010 & acc_icb_rsp_valid & acc_icb_rsp_ready) ? 1 : 0;

// imap biu to arbiter req signal
// imap_biu2arb_rdy
assign imap_biu2arb_rdy = (state == 3'b100) ? 1 : 0;

// imap biu to arbiter rsp signal
// arb2imap_biu_addr
always@(posedge clk)
begin
    if(!rst_n) begin
        arb2imap_biu_addr <= 32'b0;
    end
    else begin
        if(state == 3'b010) begin
            arb2imap_biu_addr <= fifo[output_cnt];
        end
        else begin
            arb2imap_biu_addr <= 32'b0;
        end
    end
end

// arb2imap_biu_data
assign arb2imap_biu_data = (arb2imap_biu_vld & arb2imap_biu_rdy) ? acc_icb_rsp_rdata : 0;

// arb2weight_biu_vld
assign arb2imap_biu_vld = (state == 3'b100 & acc_icb_rsp_valid & acc_icb_rsp_ready) ? 1 : 0;

// omap biu to arbiter req signal
// omap_biu2arb_rdy
assign omap_biu2arb_rdy = (state == 3'b001) ? 1 : 0;

// icb master interface
// acc_icb_cmd_valid
assign acc_icb_cmd_valid = (state == 3'b001) ? (omap_biu2arb_rdy & omap_biu2arb_vld) : ((state == 3'b010) ? (weight_biu2arb_vld & weight_biu2arb_rdy) : ((state == 3'b100) ? (imap_biu2arb_vld & imap_biu2arb_rdy) : 0));

// acc_icb_cmd_addr
assign acc_icb_cmd_addr = (state == 3'b001) ? omap_biu2arb_addr : ((state == 3'b010) ? weight_biu2arb_addr : ((state == 3'b010) ? imap_biu2arb_addr : 0));

// acc_icb_cmd_read
assign acc_icb_cmd_read = (state == 3'b010 | state == 3'b100) ? 1 : 0;

// acc_icb_cmd_wdata
assign acc_icb_cmd_wdata = (state == 3'b001) ? omap_biu2arb_data : 0;

// acc_icb_cmd_wmask
assign acc_icb_cmd_wmask = 4'b0;

// acc_icb_rsp_ready
assign acc_icb_rsp_ready = (state == 3'b001 | state == 3'b010 | state == 3'b100) ? 1 : 0;


endmodule

