// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/06 09:04
// Last Modified : 2022/06/08 09:34
// File Name     : mac_array_core.v
// Description   : mac array core, including 32 systolic arrays and two adder_tree_ichs
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/06   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

`define ARRAY_NUM 32

module mac_array_core
(
input                                   clk,
input                                   rst_n,

input                                   pipe_en,
input   [9:0]                           pe_en,

input   [(`ARRAY_NUM/4)*32-1:0]         weight_load,
input   [`ARRAY_NUM*10-1:0]             weight_load_en,
input   [1:0]                           weight_load_sel,

input   [1:0]                           weight_sel,
input   [`ARRAY_NUM*8-1:0]              imap_in,

input   [4:0]                           identity_sel,

output  [31:0]                          psum_3x3,
output  [23:0]                          psum_1x1,
output  [7:0]                           identity
);

wire [32*32-1:0] psum_3x3_ch;
wire [32*16-1:0] product_1x1_ch;
wire [7:0]  identity_ch [31:0];


// 32 systolic arrays
genvar i;
generate
  for(i=0; i<`ARRAY_NUM; i=i+1) begin: conv_array
    systolic_array conv_array(
      .clk(clk),
      .rst_n(rst_n),

      .pipe_en(pipe_en),
      .pe_en(pe_en),

      .weight_load(weight_load[i*8+:8]),
      .weight_load_en(weight_load_en[i*10+:10]),
      .weight_load_sel(weight_load_sel),

      .weight_sel(weight_sel),
      .imap_in(imap_in[i*8+:8]),

      .psum_3x3(psum_3x3_ch[i*32+:32]),
      .product_1x1(product_1x1_ch[i*16+:16]),
      .identity(identity_ch[i])
    );
  end
endgenerate

// 3x3 adder tree
adder_tree_ich #(32, 32) adder_tree_ich_3x3(
  .clk(clk),
  .rst_n(rst_n),

  .pipe_en(pipe_en),
  .psum_ch(psum_3x3_ch),

  .psum(psum_3x3)
);

// 1x1 adder tree
adder_tree_ich #(16, 24) adder_tree_ich_1x1(
  .clk(clk),
  .rst_n(rst_n),

  .pipe_en(pipe_en),
  .psum_ch(product_1x1_ch),

  .psum(psum_1x1)
);

// to sysn with psum, delay 3 cycle
wire [7:0] identity_d [3:0];
assign identity_d[0] = identity_ch[identity_sel];
assign identity = identity_d[3];

genvar k;
generate
  for(k=0; k<3; k=k+1) begin: identity_delay
    sirv_gnrl_dfflr #(8) identity_delay_dff(pipe_en, identity_d[k], identity_d[k+1], clk, rst_n);
  end
endgenerate

endmodule

