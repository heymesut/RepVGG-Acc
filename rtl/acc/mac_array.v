// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 20:04
// Last Modified : 2022/06/04 22:21
// File Name     : mac_array.v
// Description   : mac array, including 32 3x3 conv systolic arrays, 32 1x1 conv units and adder tree
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module mac_array
(

input                  clk,
input                  rst_n,

// control signal
input                  conv_start,
output                 conv_done,
output [7:0]           out_ch_cnt,
input  [7:0]           in_ch,
input  [7:0]           out_ch,
input  [15:0]          map_size,

// weight biu to mac array signal
input  [31:0]          weight_waddr,
input  [31:0]          weight_wdata,
input                  weight_wen,

// mac array to imap buf signal
output [31:0]          imap_raddr,
output                 imap_ren,
input  [63:0]          imap_rdata,

// mac array to psum acc signal
output [31:0]          mac_array2psum_acc_addr,
output [63:0]          mac_array2psum_acc_data, // [8 bit identity, 24 bit 1x1 psum, 32 bit 3x3 psum]
output                 mac_array2psum_acc_vld,
input                  mac_array2psum_acc_rdy

);

endmodule

