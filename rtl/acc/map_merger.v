// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 21:03
// Last Modified : 2022/06/09 13:06
// File Name     : map_merger.v
// Description   : merge 3x3 omap, 1x1 omap and identity map with quantization
//                 and activation
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module map_merger
(
input                       clk,
input                       rst_n,

// psum acc to map_merger signal
input  [63:0]               psum_acc2map_merger_data,
input                       psum_acc2map_merger_vld,
output                      psum_acc2map_merger_rdy,

// map merger to omap biu signal
output  [31:0]              map_merger2omap_biu_data,
output                      map_merger2omap_biu_vld,
input                       map_merger2omap_biu_rdy
);


// merge map
wire signed [7:0] identity = psum_acc2map_merger_data[63:56];
wire signed [23:0] map_1x1 = psum_acc2map_merger_data[55:32];
wire signed [31:0] map_3x3 = psum_acc2map_merger_data[31:0];
wire signed [31:0] merge_result = identity + map_3x3 + map_1x1;

// activation
wire [31:0] act_merge = (merge_result[31]==0) ? merge_result : 32'b0;

// quantization
wire [7:0] quan_3x3 = map_3x3[31:24];
wire [7:0] quan_1x1 = map_1x1[23:16];
wire [7:0] quan_merge = act_merge[31:24];

wire [31:0] map_merger_data_out =  {8'b0, quan_merge, quan_3x3, quan_1x1};

// output pipe stage
wire map_merger_vld_out = psum_acc2map_merger_vld & psum_acc2map_merger_rdy;

wire map_merger_rdy_out;

assign psum_acc2map_merger_rdy = map_merger_rdy_out;

sirv_gnrl_pipe_stage #(
  .CUT_READY(0),
  .DP(1),
  .DW(32)
) map_merger2omap_biu_data_pipe_stage(
  .i_vld(map_merger_vld_out),
  .i_rdy(map_merger_rdy_out),
  .i_dat(map_merger_data_out),

  .o_vld(map_merger2omap_biu_vld),
  .o_rdy(map_merger2omap_biu_rdy),
  .o_dat(map_merger2omap_biu_data),

  .clk(clk),
  .rst_n(rst_n)
);

endmodule

