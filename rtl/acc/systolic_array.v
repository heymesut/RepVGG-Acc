// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/05 16:52
// Last Modified : 2022/06/06 10:44
// File Name     : systolic_array.v
// Description   : systolic array, including 3x3 systolic array with adder
//                 tree, 1x1 conv unit and identity path (#pe is 10)
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/05   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

`define LINE_BUF_LEN 56

module systolic_array
(
input                        clk,
input                        rst_n,

input                        pipe_en,
input  [9:0]                 pe_en,

input  [7:0]                 weight_load,
input  [9:0]                 weight_load_en,
input  [1:0]                 weight_load_sel,

input  [1:0]                 weight_sel,
input  [7:0]                 imap_in,

output [31:0]                psum_3x3,
output [15:0]                product_1x1,
output [7:0]                 identity
);


// 3x3 systolic array
wire [7:0] imap_pipe [(`LINE_BUF_LEN*2+3):0];
assign imap_pipe[0] = imap_in;

wire [9*16-1:0] product_3x3;

genvar i0;
generate
  for(i0=0; i0<3; i0=i0+1) begin: _1st_line_pe
    basic_pe _1st_line_pe(
      .clk(clk),
      .rst_n(rst_n),

      .pe_en(pe_en[i0]),
      .pipe_en(pipe_en),

      .weight_load(weight_load),
      .weight_load_en(weight_load_en[i0]),
      .weight_load_sel(weight_load_sel),

      .weight_sel(weight_sel),
      .imap_in(imap_pipe[i0]),
      .imap_out(imap_pipe[i0+1]),

      .product(product_3x3[i0*16+:16])
    );
  end
endgenerate


genvar j0;
generate
  for(j0=3; j0<`LINE_BUF_LEN; j0=j0+1) begin: _1st_line_shift_reg
    sirv_gnrl_dfflr #(8) _1st_line_shift_reg(pipe_en, imap_pipe[j0], imap_pipe[j0+1], clk, rst_n);
  end
endgenerate

genvar i1;
generate
  for(i1=0; i1<3; i1=i1+1) begin: _2nd_line_pe
    basic_pe _2nd_line_pe(
      .clk(clk),
      .rst_n(rst_n),

      .pe_en(pe_en[i1+3]),
      .pipe_en(pipe_en),

      .weight_load(weight_load),
      .weight_load_en(weight_load_en[i1+3]),
      .weight_load_sel(weight_load_sel),

      .weight_sel(weight_sel),
      .imap_in(imap_pipe[i1+`LINE_BUF_LEN]),
      .imap_out(imap_pipe[i1+`LINE_BUF_LEN+1]),

      .product(product_3x3[(i1+3)*16+:16])
    );
  end
endgenerate


genvar j1;
generate
  for(j1=3+`LINE_BUF_LEN; j1<(`LINE_BUF_LEN*2); j1=j1+1) begin: _2nd_line_shift_reg
    sirv_gnrl_dfflr #(8) _2nd_line_shift_reg(pipe_en, imap_pipe[j1], imap_pipe[j1+1], clk, rst_n);
  end
endgenerate

genvar i2;
generate
  for(i2=0; i2<3; i2=i2+1) begin: _3rd_line_pe
    basic_pe _3rd_line_pe(
      .clk(clk),
      .rst_n(rst_n),

      .pe_en(pe_en[i2+6]),
      .pipe_en(pipe_en),

      .weight_load(weight_load),
      .weight_load_en(weight_load_en[i2+6]),
      .weight_load_sel(weight_load_sel),

      .weight_sel(weight_sel),
      .imap_in(imap_pipe[i2+2*`LINE_BUF_LEN]),
      .imap_out(imap_pipe[i2+2*`LINE_BUF_LEN+1]),

      .product(product_3x3[(i2+6)*16+:16])
    );
  end
endgenerate

// adder tree
adder_tree_3x3 adder_tree_3x3_u (
  .clk(clk),
  .rst_n(rst_n),

  .pipe_en(pipe_en),
  .product_3x3(product_3x3),
  .psum_3x3(psum_3x3)
);

// 1x1 conv unit
wire [15:0] product_1x1_o;
wire [15:0] product_1x1_d1;
wire [15:0] product_1x1_d2;

basic_pe _1x1_pe(
  .clk(clk),
  .rst_n(rst_n),

  .pe_en(pe_en[9]),
  .pipe_en(pipe_en),

  .weight_load(weight_load),
  .weight_load_en(weight_load_en[9]),
  .weight_load_sel(weight_load_sel),

  .weight_sel(weight_sel),
  .imap_in(imap_pipe[`LINE_BUF_LEN+1]), // to sync with conv3x3
  .imap_out(),

  .product(product_1x1_o)
);

// to sync with psum_3x3, delay 2 cycles
sirv_gnrl_dfflr #(16) product_1x1_dff_d1(pipe_en, product_1x1_o, product_1x1_d1, clk, rst_n);
sirv_gnrl_dfflr #(16) product_1x1_dff_d2(pipe_en, product_1x1_d1, product_1x1_d2, clk, rst_n);
assign product_1x1 = product_1x1_d2;

// identity path
// to sync with psum_3x3, delay 4 cycles
wire [7:0] identity_d[4:0];
assign identity_d[0] = imap_pipe[`LINE_BUF_LEN+1];
assign identity = identity_d[4];

genvar k;
generate
  for(k=0; k<4; k=k+1) begin: identity_delay
    sirv_gnrl_dfflr #(8) identity_delay_dff(pipe_en, identity_d[k], identity_d[k+1], clk, rst_n);
  end
endgenerate


endmodule

