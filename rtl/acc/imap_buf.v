// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 20:50
// Last Modified : 2022/06/04 22:21
// File Name     : imap_buf.v
// Description   : input feature map buffer with 7 SRAMs
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module imap_buf
(
input               clk,
input               rst_n,

// imap biu to imap buf signal
input  [31:0]       imap_waddr,
input  [31:0]       imap_wdata,
input               imap_wen,

// imap buf to mac array signal
input  [31:0]       imap_raddr,
input               imap_ren,
output [63:0]       imap_rdata
);

endmodule

