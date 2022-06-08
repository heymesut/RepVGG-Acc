// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 19:47
// Last Modified : 2022/06/08 21:29
// File Name     : imap_biu.v
// Description   : input feature map bus interface unit
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module imap_biu
(
input              clk,
input              rst_n,

// control signal
input              imap_start,
output reg         imap_done,
input  [7:0]       in_ch,
input  [7:0]       out_ch,
input  [15:0]      map_size,
input  [31:0]      imap_base_addr,

// imap biu to arbiter req signal
output  reg         imap_biu2arb_req,
output  reg [31:0]  imap_biu2arb_addr,
output  reg         imap_biu2arb_vld,
input               imap_biu2arb_rdy,

// imap biu to arbiter rsp signal
input  [31:0]      arb2imap_biu_addr,
input  [31:0]      arb2imap_biu_data,
input              arb2imap_biu_vld,
output wire        arb2imap_biu_rdy,

// imap biu to mac array signal
output  wire    [31:0]  imap_waddr,
output  wire    [63:0]  imap_wdata,
output  wire            imap_wen

);

reg [1:0]   nextstate;
reg [1:0]   state;
reg [15:0]  cnt;
reg [15:0]  receive_cnt;
reg [31:0]  former_bits;

// FSM nextstate
always@(posedge clk)
begin
    if(!rst_n) begin
        nextstate <= 2'b0;
    end
    else begin
        case(state)
            2'b00:  begin
                        if(imap_start == 1'b1) begin
                            nextstate <= 2'b01;
                        end
                    end
            2'b01:  begin
                        if(cnt == 16'hc3ff & arb2imap_biu_vld & arb2imap_biu_rdy) begin
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
        cnt <= 16'b0;
    end
    else begin
        case(state)
            2'b01:  begin
                        if(cnt == 16'hc3ff & arb2imap_biu_vld & arb2imap_biu_rdy) begin
                            cnt <= 16'h0;
                        end
                        else if(arb2imap_biu_vld & arb2imap_biu_rdy) begin
                            cnt <= cnt+1;
                        end
                    end
            default:begin
                        cnt <= 16'b0;
                    end
        endcase
    end
end

// imap_biu2arb_addr
always@(posedge clk)
begin
    if(!rst_n) begin
        imap_biu2arb_addr <= 32'h0;
    end
    else begin
        case(state)
            2'b00:  begin
                        if(nextstate == 2'b01) begin
                            imap_biu2arb_addr <= imap_base_addr;
                        end
                    end
            2'b01:  begin
                        if(cnt == 16'hc3ff) begin
                            imap_biu2arb_addr <= 32'h0;
                        end
                        else if(arb2imap_biu_vld & arb2imap_biu_rdy) begin
                            imap_biu2arb_addr <= imap_biu2arb_addr + 4'h4;
                        end
                    end
            default:begin
                        imap_biu2arb_addr <= 32'h0;
                    end
        endcase
    end
end

// imap_biu2arb_req
always@(posedge clk)
begin
    if(!rst_n) begin
        imap_biu2arb_req <= 1'b0;
    end
    else begin
        if(imap_start) begin
            imap_biu2arb_req <= 1'b1;
        end
        else if(state == 2'b01 & nextstate == 2'b00) begin
            imap_biu2arb_req <= 1'b0;
        end
    end
end

// imap_biu2arb_vld
always@(posedge clk)
begin
    if(!rst_n) begin
        imap_biu2arb_vld <= 1'b0;
    end
    else begin
        if(imap_biu2arb_req) begin
            imap_biu2arb_vld <= 1'b1;
        end
        else if(state == 2'b01 & nextstate == 2'b00) begin
            imap_biu2arb_vld <= 1'b0;
        end
    end
end

// arb2imap_biu_rdy
assign arb2imap_biu_rdy = 1'b1;

// receive counter
always@(posedge clk)
begin
    if(!rst_n) begin
        receive_cnt <= 16'b0;
    end
    else begin
        if(receive_cnt == 16'hc3ff & arb2imap_biu_vld & arb2imap_biu_rdy) begin
            receive_cnt <= 16'b0;
        end
        else if(arb2imap_biu_vld & arb2imap_biu_rdy) begin
            receive_cnt <= receive_cnt + 1;
        end
    end
end

// former bits
// first 32bits should be stored, waiting for the latter 32bits to make up 64bits
always@(posedge clk)
begin
    if(!rst_n) begin
        former_bits <= 32'b0;
    end
    else begin
        if(receive_cnt[0] == 1'b0 & arb2imap_biu_vld & arb2imap_biu_rdy) begin
            former_bits <= arb2imap_biu_data;
        end
    end
end

// imap_waddr
assign imap_waddr = receive_cnt[15:4] + (receive_cnt[2:1] * 2'b10 + receive_cnt[3]) * 16'hc400;

// imap_wdata
assign imap_wdata[63:32] = former_bits;
assign imap_wdata[31:0]  = arb2imap_biu_data;

// imap_wen
assign imap_wen = receive_cnt[0] & arb2imap_biu_vld & arb2imap_biu_rdy;

// imap_done
always@(posedge clk)
begin
    if(!rst_n) begin
        imap_done <= 1'b0;
    end
    else begin
        if(imap_done == 1'b1) begin
            imap_done <= 1'b0;
        end
        else if(receive_cnt == 16'hc3ff & arb2imap_biu_vld & arb2imap_biu_rdy) begin
            imap_done <= 1'b1;
        end
    end
end

endmodule

