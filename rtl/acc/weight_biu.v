// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 19:34
// Last Modified : 2022/06/04 22:21
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
output             weight_done,
input  [7:0]       in_ch,
input  [7:0]       out_ch,
input  [31:0]      weight3_base_addr,
input  [31:0]      weight1_base_addr,
input  [7:0]       out_ch_cnt,

// weight biu to arbiter req signal
output [31:0]      weight_biu2arb_addr,
output             weight_biu2arb_vld,
input              weight_biu2arb_rdy,

// weight biu to arbiter rsp signal
input  [31:0]      arb2weight_biu_addr,
input  [31:0]      arb2weight_biu_data,
input              arb2weight_biu_vld,
output             arb2weight_biu_rdy,

// weight biu to mac array signal
output [31:0]      weight_waddr,
output [31:0]      weight_wdata,
output             weight_wen

);

endmodule

