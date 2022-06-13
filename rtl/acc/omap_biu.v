// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 20:00
// Last Modified : 2022/06/09 22:16
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
input              conv_start,

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

wire [31:0] omap_biu_addr_out = omap_biu_hdshk_in ?
                              ((omap_biu2arb_addr==(20'd200703+omap_base_addr)) ?
                                omap_base_addr : omap_biu2arb_addr+1) : omap_biu2arb_addr;

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

sirv_gnrl_pipe_stage #(
  .CUT_READY(0),
  .DP(1),
  .DW(32)
) omap_biu2arb_addr_pipe_stage(
  .i_vld(omap_biu_vld_out),
  .i_rdy(omap_biu_rdy_out),
  .i_dat(omap_biu_addr_out),

  .o_vld(omap_biu2arb_vld),
  .o_rdy(omap_biu2arb_rdy),
  .o_dat(omap_biu2arb_addr),

  .clk(clk),
  .rst_n(rst_n)
);


// omap_biu2arb_req
// when conv_start is triggered, set req; when the whole omap is transferred, reset req
always @(posedge clk) begin
  if(!rst_n)
    omap_biu2arb_req <= 1'b0;
  else
    if(conv_start)
      omap_biu2arb_req <= 1'b1;
    else
      if(omap_biu2arb_addr==(20'd200703+omap_base_addr))
        omap_biu2arb_req <= 1'b0;
      else
        omap_biu2arb_req <= omap_biu2arb_req;
end

// arb2omap_biu_rdy
assign arb2omap_biu_rdy = 1'b1;

endmodule

