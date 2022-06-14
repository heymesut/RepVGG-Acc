// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 20:00
// Last Modified : 2022/06/14 19:28
// File Name     : omap_biu.v
// Description   : output feature map bus interface unit
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module omap_biu
(
input              clk,
input              rst_n,

// control signal
input  [7:0]       in_ch,
input  [7:0]       out_ch,
input  [15:0]      map_size,
input  [31:0]      omap_base_addr,
input              in_ch_cnt,

// omap biu to arbiter req signal
output reg         omap_biu2arb_req,
output [31:0]      omap_biu2arb_addr,
output [31:0]      omap_biu2arb_data,
output             omap_biu2arb_vld,
input              omap_biu2arb_rdy,

// omap biu to arbiter rsp signal
input              arb2omap_biu_vld,
output wire        arb2omap_biu_rdy,

// map merger to omap biu signal
input  [31:0]      map_merger2omap_biu_data,
input              map_merger2omap_biu_vld,
output             map_merger2omap_biu_rdy

);

// addr generation
wire omap_biu_hdshk_in = map_merger2omap_biu_rdy & map_merger2omap_biu_vld;

reg [19:0] omap_biu2arb_cnt;
always @(posedge clk) begin
  if(!rst_n) begin
    omap_biu2arb_cnt <= 20'b0;
  end
  else
    if(omap_biu2arb_vld && omap_biu2arb_rdy)
      if(omap_biu2arb_cnt==20'd200703) begin
        omap_biu2arb_cnt <= 20'b0;
      end
      else
        omap_biu2arb_cnt <= omap_biu2arb_cnt + 1;
    else
      omap_biu2arb_cnt <= omap_biu2arb_cnt;
end

assign omap_biu2arb_addr = omap_base_addr + (omap_biu2arb_cnt << 2);

// omap_biu output pipe stage
wire omap_biu_vld_out  = omap_biu_hdshk_in;
wire omap_biu_rdy_out;
assign map_merger2omap_biu_rdy = omap_biu_rdy_out;

sirv_gnrl_pipe_stage #(
  .CUT_READY(0),
  .DP(1),
  .DW(32)
) omap_biu2arb_data_pipe_stage(
  .i_vld(omap_biu_vld_out),
  .i_rdy(omap_biu_rdy_out),
  .i_dat(map_merger2omap_biu_data),

  .o_vld(omap_biu2arb_vld),
  .o_rdy(omap_biu2arb_rdy),
  .o_dat(omap_biu2arb_data),

  .clk(clk),
  .rst_n(rst_n)
);

// receive counter
reg [11:0] receive_cnt;
always@(posedge clk)
begin
    if(!rst_n) begin
        receive_cnt <= 12'b0;
    end
    else begin
        if(receive_cnt == 12'd3135 & arb2omap_biu_vld & arb2omap_biu_rdy) begin
            receive_cnt <= 12'b0;
        end
        else if(arb2omap_biu_vld & arb2omap_biu_rdy) begin
            receive_cnt <= receive_cnt + 1;
        end
    end
end

// omap_biu2arb_req
always @(posedge clk) begin
  if(!rst_n)
    omap_biu2arb_req <= 1'b0;
  else
    if(receive_cnt == 12'd3135 & arb2omap_biu_vld & arb2omap_biu_rdy)
      omap_biu2arb_req <= 1'b0;
    else
      if(in_ch_cnt)
        omap_biu2arb_req <= 1'b1;
      else
        omap_biu2arb_req <= omap_biu2arb_req;
end

// arb2omap_biu_rdy
assign arb2omap_biu_rdy = 1'b1;

endmodule

