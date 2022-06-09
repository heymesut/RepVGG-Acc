// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/06 00:26
// Last Modified : 2022/06/09 11:43
// File Name     : adder_tree_ich.v
// Description   : adder tree for ich accumulation
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/06   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module adder_tree_ich
#(
parameter IN_WIDTH = 32,
parameter PSUM_WIDTH = 32
)
(
input                       clk,
input                       rst_n,

input                       pipe_en,
input  [IN_WIDTH*32-1:0]    psum_ch,
output [PSUM_WIDTH-1:0]               psum
);

wire signed [PSUM_WIDTH-1:0] psum_s1 [15:0];
wire [PSUM_WIDTH-1:0] psum_s2 [7:0];
wire [PSUM_WIDTH-1:0] psum_s3 [3:0];
wire [PSUM_WIDTH-1:0] psum_s4 [1:0];
wire [PSUM_WIDTH-1:0] psum_s5;

// adder tree, stage 1
genvar i1;
generate
  for(i1=0; i1<16; i1=i1+1) begin: adder_stage1
    assign psum_s1[i1] = psum_ch[2*i1*IN_WIDTH+:IN_WIDTH] + psum_ch[(2*i1+1)*IN_WIDTH+:IN_WIDTH];
  end
endgenerate

// adder tree, stage 2
genvar i2;
generate
  for(i2=0; i2<8; i2=i2+1) begin: adder_stage2
    assign psum_s2[i2] = psum_s1[2*i2] + psum_s1[2*i2+1];
  end
endgenerate

// adder tree, dff pipe1
wire [PSUM_WIDTH-1:0] psum_s2_r [7:0];
genvar j;
generate
  for(j=0; j<8; j=j+1) begin: dff_pipe1
    sirv_gnrl_dfflr #(PSUM_WIDTH) dff_pipe1(pipe_en, psum_s2[j], psum_s2_r[j], clk, rst_n);
  end
endgenerate

// adder tree, stage 3
genvar i3;
generate
  for(i3=0; i3<4; i3=i3+1) begin: adder_stage3
    assign psum_s3[i3] = psum_s2_r[2*i3] + psum_s2_r[2*i3+1];
  end
endgenerate

// adder tree, stage 4
assign psum_s4[0] = psum_s3[0] + psum_s3[1];
assign psum_s4[1] = psum_s3[2] + psum_s3[3];

// adder tree, dff pipe2
wire [PSUM_WIDTH-1:0] psum_s4_r [1:0];
sirv_gnrl_dfflr #(PSUM_WIDTH) dff_pipe2_0(pipe_en, psum_s4[0], psum_s4_r[0], clk, rst_n);
sirv_gnrl_dfflr #(PSUM_WIDTH) dff_pipe2_1(pipe_en, psum_s4[1], psum_s4_r[1], clk, rst_n);

// adder tree, stage 5
assign psum_s5 = psum_s4_r[0] + psum_s4_r[1];

// adder tree, dff pipe3
wire [PSUM_WIDTH-1:0] psum_s5_r;
assign psum = psum_s5_r;
sirv_gnrl_dfflr #(PSUM_WIDTH) dff_pipe3(pipe_en, psum_s5, psum_s5_r, clk, rst_n);

endmodule

