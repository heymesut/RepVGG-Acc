// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 21:36
// Last Modified : 2022/06/04 21:42
// File Name     : main_fsm.v
// Description   : accelerator main fsm
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module main_fsm
(
input                  clk,
input                  rst_n,

// setting from register
input  [7:0]           in_ch,
input  [7:0]           out_ch,
input  [15:0]          map_size,

// control signal
input                  acc_start,
output                 acc_done,

output                 weight_start,
input                  weight_done,

output                 imap_start,
input                  imap_done,

output                 conv_start,
input                  conv_done,

input  [7:0]           out_ch_cnt

);

endmodule

