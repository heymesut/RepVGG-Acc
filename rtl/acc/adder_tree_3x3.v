// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/05 23:37
// Last Modified : 2022/06/08 09:14
// File Name     : adder_tree_3x3.v
// Description   : adder tree in 3x3 systolic array
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/05   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module adder_tree_3x3
(
input                     clk,
input                     rst_n,

input                     pipe_en,
input  [9*16-1:0]         product_3x3,
output [31:0]             psum_3x3
);

wire [31:0] psum_s1 [3:0];
wire [31:0] psum_s2 [1:0];
wire [31:0] psum_s3;
wire [31:0] psum_s4;

// adder tree, stage 1
genvar i;
generate
  for(i=0; i<4; i=i+1) begin: adder_stage1
    assign psum_s1[i] = product_3x3[2*i*16+:16] + product_3x3[(2*i+1)*16+:16];
  end
endgenerate

// adder tree, stage 2
assign psum_s2[0] = psum_s1[0] + psum_s1[1];
assign psum_s2[1] = psum_s1[2] + psum_s1[3];

// adder tree, dff pipe1
wire [31:0] psum_s2_r [1:0];
wire [15:0] product_9 = product_3x3[8*16+:16];
wire [15:0] product_9_r;

sirv_gnrl_dfflr #(32) psum_dff_pipe1_0(pipe_en, psum_s2[0], psum_s2_r[0], clk, rst_n);
sirv_gnrl_dfflr #(32) psum_dff_pipe1_1(pipe_en, psum_s2[1], psum_s2_r[1], clk, rst_n);
sirv_gnrl_dfflr #(16) psum_dff_pipe1_product9(pipe_en, product_9, product_9_r, clk, rst_n);

// adder tree, stage 3
assign psum_s3 = psum_s2_r[0] + psum_s2_r[1];

// adder tree, stage 4
assign psum_s4 = psum_s3 + product_9_r;

// adder tree, dff pipe2
wire [31:0] psum_s4_r;
sirv_gnrl_dfflr #(32) psum_dff_pipe2_psum(pipe_en, psum_s4, psum_s4_r, clk, rst_n);
assign psum_3x3 = psum_s4_r;

endmodule

