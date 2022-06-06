// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 19:34
// Last Modified : 2022/06/04 22:21
// File Name     : weight_biu.v
// Description   : weights bus interface unit
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut          1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module weight_biu
(
input              clk,
input              rst_n,

// control signal
input              weight_start,
output reg         weight_done,
input  [7:0]       in_ch,
input  [7:0]       out_ch,
input  [31:0]      weight3_base_addr,
input  [31:0]      weight1_base_addr,
input  [7:0]       out_ch_cnt,

// weight biu to arbiter req signal
output reg  [31:0]  weight_biu2arb_addr,
output reg          weight_biu2arb_vld,
output reg          weight_biu2arb_req,
input               weight_biu2arb_rdy,

// weight biu to arbiter rsp signal
input  [31:0]      arb2weight_biu_addr,
input  [31:0]      arb2weight_biu_data,
input              arb2weight_biu_vld,
output wire        arb2weight_biu_rdy,

// weight biu to mac array signal
output  wire    [31:0]  weight_waddr,
output  wire    [31:0]  weight_wdata,
output  wire            weight_wen

);

reg [1:0]   nextstate;
reg [1:0]   state;
reg [7:0]   cnt;
reg [7:0]   receive_cnt;

// FSM nextstate
always@(posedge clk)
begin
    if(!rst_n) begin
        nextstate <= 2'b0;
    end
    else begin
        case(state)
            2'b00:  begin
                        if(weight_start == 1'b1) begin
                            nextstate <= 2'b01;
                        end
                    end
            2'b01:  begin
                        if(cnt == 8'h47 & arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            nextstate <= 2'b10;
                        end
                    end
            2'b10:  begin
                        if(cnt == 8'h07 & arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            nextstate <= 2'b00;
                        end
                    end
            default:begin
                        nextstate <= 2'b00;
                    end
        endcase
    end
end

// FSM state
always@(posedge clk)
begin
    if(!rst_n) begin
        state <= 2'b0;
    end
    else begin
        state <= nextstate;
    end
end

// counter
always@(posedge clk)
begin
    if(!rst_n) begin
        cnt <= 8'b0;
    end
    else begin
        case(state)
            2'b01:  begin
                        if(cnt == 8'h47 & arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            cnt <= 8'h0;
                        end
                        else if(arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            cnt <= cnt+1;
                        end
                    end
            2'b10:  begin
                        if(cnt == 8'h07 & arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            cnt <= 8'h0;
                        end
                        else if(arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            cnt <= cnt+1;
                        end
                    end
            default:begin
                        cnt <= 8'b0;
                    end
        endcase
    end
end

// weight_biu2arb_addr
// fetch 3*3 weight first, then 1*1 weight
always@(posedge clk)
begin
    if(!rst_n) begin
        weight_biu2arb_addr <= 32'h0;
    end
    else begin
        case(state)
            2'b00:  begin
                        if(nextstate == 2'b01) begin
                            weight_biu2arb_addr <= weight3_base_addr + out_ch * 12'h240;
                        end
                    end
            2'b01:  begin
                        if(cnt == 8'h47 & arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            weight_biu2arb_addr <= weight1_base_addr + out_ch * 12'h020;
                        end
                        else if(arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            weight_biu2arb_addr <= weight_biu2arb_addr + 4'h4;
                        end
                    end
            2'b10:  begin
                        if(cnt == 8'h07 & arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            weight_biu2arb_addr <= 32'h0;
                        end
                        else if(arb2weight_biu_vld & arb2weight_biu_rdy) begin
                            weight_biu2arb_addr <= weight_biu2arb_addr + 4'h4;
                        end
                    end
            default:begin
                        weight_biu2arb_addr <= 32'h0;
                    end
        endcase
    end
end

// weight_biu2arb_req
always@(posedge clk)
begin
    if(!rst_n) begin
        weight_biu2arb_req <= 1'b0;
    end
    else begin
        if(weight_start) begin
            weight_biu2arb_req <= 1'b1;
        end
        else if(state == 2'b10 & nextstate == 2'b00) begin
            weight_biu2arb_req <= 1'b0;
        end
    end
end

// weight_biu2arb_vld
always@(posedge clk)
begin
    if(!rst_n) begin
        weight_biu2arb_vld <= 1'b0;
    end
    else begin
        if(weight_biu2arb_req) begin
            weight_biu2arb_vld <= 1'b1;
        end
        else if(state == 2'b10 & nextstate == 2'b00) begin
            weight_biu2arb_vld <= 1'b0;
        end
    end
end

// arb2weight_biu_rdy
assign arb2weight_biu_rdy = 1'b1;

// receive counter
always@(posedge clk)
begin
    if(!rst_n) begin
        receive_cnt <= 8'b0;
    end
    else begin
        if(receive_cnt == 8'h4f & arb2weight_biu_vld & arb2weight_biu_rdy) begin
            receive_cnt <= 8'b0;
        end
        else if(arb2weight_biu_vld & arb2weight_biu_rdy) begin
            receive_cnt <= receive_cnt + 1;
        end
    end
end

// weight_waddr
// the first bit stands for 3*3(0) or 1*1(1)
// the 2nd~9th bit stands for the number of channel
assign weight_waddr[31]     = (receive_cnt < 8'h47) ? 0 : 1;
assign weight_waddr[30:23]  = out_ch_cnt;
wire [31:0] weight3_addr;
wire [31:0] weight1s_addr;
assign weight3_addr = arb2weight_biu_addr - weight3_base_addr;
assign weight1_addr = arb2weight_biu_addr - weight1_base_addr;
assign weight_waddr[22:0]   = (receive_cnt < 8'h47) ? weight3_addr[22:0] : weight1_addr[22:0];

// weight_wdata
assign weight_wdata = arb2weight_biu_data;

// weight_wen
assign weight_wen = arb2weight_biu_vld & arb2weight_biu_rdy;

// weight_done
always@(posedge clk)
begin
    if(!rst_n) begin
        weight_done <= 1'b0;
    end
    else begin
        if(weight_done == 1'b1) begin
            weight_done <= 1'b0;
        end
        else if(receive_cnt == 8'h4f & arb2weight_biu_vld & arb2weight_biu_rdy) begin
            weight_done <= 1'b1;
        end
    end
end

endmodule

