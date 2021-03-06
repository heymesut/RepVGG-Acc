// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 19:34
// Last Modified : 2022/06/14 11:39
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
input  [7:0]       weight_och_cnt,

// weight biu to arbiter req signal
output reg  [31:0]  weight_biu2arb_addr,
output reg          weight_biu2arb_vld,
output reg          weight_biu2arb_req,
input               weight_biu2arb_rdy,

// weight biu to arbiter rsp signal
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
reg [5:0]   receive_bit_cnt;
reg [3:0]   receive_ch_cnt;

// FSM nextstate
always@(*)
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
                        if(cnt == 8'd143 & weight_biu2arb_vld & weight_biu2arb_rdy) begin // 3x3 kenel: 64/4 * 9
                            nextstate <= 2'b10;
                        end
                    end
            2'b10:  begin
                        if(cnt == 8'd15 & weight_biu2arb_vld & weight_biu2arb_rdy) begin // 1x1 kelnel: 64/4
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
                        if(cnt == 8'd143 & weight_biu2arb_vld & weight_biu2arb_rdy) begin
                            cnt <= 8'h0;
                        end
                        else if(weight_biu2arb_vld & weight_biu2arb_rdy) begin
                            cnt <= cnt+1;
                        end
                    end
            2'b10:  begin
                        if(cnt == 8'd15 & weight_biu2arb_vld & weight_biu2arb_rdy) begin
                            cnt <= 8'h0;
                        end
                        else if(weight_biu2arb_vld & weight_biu2arb_rdy) begin
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
                            weight_biu2arb_addr <= weight3_base_addr + weight_och_cnt * 8'h90;
                        end
                    end
            2'b01:  begin
                        if(cnt == 8'd143 & weight_biu2arb_vld & weight_biu2arb_rdy) begin
                            weight_biu2arb_addr <= weight1_base_addr + weight_och_cnt * 8'h10;
                        end
                        else if(weight_biu2arb_vld & weight_biu2arb_rdy) begin
                            weight_biu2arb_addr <= weight_biu2arb_addr + 4'h4;
                        end
                    end
            2'b10:  begin
                        if(cnt == 8'd15 & weight_biu2arb_vld & weight_biu2arb_rdy) begin
                            weight_biu2arb_addr <= 32'h0;
                        end
                        else if(weight_biu2arb_vld & weight_biu2arb_rdy) begin
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
        else if(receive_cnt == 8'd159 & arb2weight_biu_vld & arb2weight_biu_rdy) begin
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
        if(state == 2'b10 & cnt == 8'd15 & weight_biu2arb_vld & weight_biu2arb_rdy) begin
            weight_biu2arb_vld <= 1'b0;
        end
        else if(weight_start) begin
            weight_biu2arb_vld <= 1'b1;
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
        if(receive_cnt == 8'd159 & arb2weight_biu_vld & arb2weight_biu_rdy) begin // 1x1 kernel and 3x3 kernel: 64/4*(3*3+1*1)
            receive_cnt <= 8'b0;
        end
        else if(arb2weight_biu_vld & arb2weight_biu_rdy) begin
            receive_cnt <= receive_cnt + 1;
        end
    end
end

// receive bit counter
// point to the location of weight in kernel
always@(posedge clk)
begin
    if(!rst_n) begin
        receive_bit_cnt <= 6'b0;
    end
    else begin
        if(receive_cnt <= 8'd143) begin
            if(receive_ch_cnt == 4'hf & arb2weight_biu_vld & arb2weight_biu_rdy) begin
                if(receive_bit_cnt == 4'h8) begin
                    receive_bit_cnt <= 0;
                end
                else begin
                    receive_bit_cnt <= receive_bit_cnt + 1;
                end
            end
        end
    end
end

// receive bit counter
// point to the number of input channel
always@(posedge clk)
begin
    if(!rst_n) begin
        receive_ch_cnt <= 4'b0;
    end
    else begin
        if(arb2weight_biu_vld & arb2weight_biu_rdy) begin
            receive_ch_cnt <= receive_ch_cnt + 1;
        end
    end
end


// weight_waddr
// the first bit stands for 3*3(0) or 1*1(1)
// the 2nd~9th bit stands for the number of channel
assign weight_waddr[31]     = (receive_cnt < 8'h90) ? 0 : 1;
assign weight_waddr[30:23]  = weight_och_cnt;
assign weight_waddr[5:0]    = receive_ch_cnt;
assign weight_waddr[11:6]   = receive_bit_cnt;
assign weight_waddr[22:12]  = 0;

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
        else if(receive_cnt == 8'd159 & arb2weight_biu_vld & arb2weight_biu_rdy) begin
            weight_done <= 1'b1;
        end
    end
end

endmodule

