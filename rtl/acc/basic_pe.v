// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/05 15:43
// Last Modified : 2022/06/09 11:44
// File Name     : basic_pe.v
// Description   : basic multiplication unit, including an 8-bit imap register,
//                 a multiplier and four 8-bit weight buffers
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/05   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module basic_pe
(
input                              clk,
input                              rst_n,

input                              pe_en,
input                              pipe_en,

input  signed [7:0]                weight_load,
input                              weight_load_en,
input  [1:0]                       weight_load_sel,

input  [1:0]                       weight_sel,
input signed [7:0]                 imap_in,
output signed [7:0]                       imap_out,

output signed [15:0]                      product
);

// imap shift register
wire [7:0] imap_r;
assign imap_out = imap_r;
sirv_gnrl_dfflr #(8) imap_shift_reg (pipe_en, imap_in, imap_r, clk, rst_n);


// 4 weight buffers
wire signed [7:0] weight0;
wire signed [7:0] weight1;
wire signed [7:0] weight2;
wire signed [7:0] weight3;

wire [3:0] weight_buf_len;
assign weight_buf_len[0] = (weight_load_sel == 2'b00) & weight_load_en;
assign weight_buf_len[1] = (weight_load_sel == 2'b01) & weight_load_en;
assign weight_buf_len[2] = (weight_load_sel == 2'b10) & weight_load_en;
assign weight_buf_len[3] = (weight_load_sel == 2'b11) & weight_load_en;

sirv_gnrl_dfflr #(8) weight_buf0 (weight_buf_len[0], weight_load, weight0, clk, rst_n);
sirv_gnrl_dfflr #(8) weight_buf1 (weight_buf_len[1], weight_load, weight1, clk, rst_n);
sirv_gnrl_dfflr #(8) weight_buf2 (weight_buf_len[2], weight_load, weight2, clk, rst_n);
sirv_gnrl_dfflr #(8) weight_buf3 (weight_buf_len[3], weight_load, weight3, clk, rst_n);


// multiplier
wire [3:0] weight_buf_ren;
assign weight_buf_ren[0] = (weight_sel == 2'b00);
assign weight_buf_ren[1] = (weight_sel == 2'b01);
assign weight_buf_ren[2] = (weight_sel == 2'b10);
assign weight_buf_ren[3] = (weight_sel == 2'b11);

wire signed [7:0] weight = ({8{weight_buf_ren[0]}} & weight0) |
                    ({8{weight_buf_ren[1]}} & weight1) |
                    ({8{weight_buf_ren[2]}} & weight2) |
                    ({8{weight_buf_ren[3]}} & weight3) ;

wire signed [15:0] product_r;
wire signed [15:0] product_nxt = pe_en ? (weight * imap_r) : 16'b0;
assign product = product_r;

sirv_gnrl_dffr #(16) product_dff (product_nxt, product_r, clk, rst_n);


endmodule

