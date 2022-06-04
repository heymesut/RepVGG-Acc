// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 19:47
// Last Modified : 2022/06/04 22:21
// File Name     : imap_biu.v
// Description   : input feature map bus interface unit
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module imap_biu
(
input              clk,
input              rst_n,

// control signal
input              imap_start,
output             imap_done,
input  [7:0]       in_ch,
input  [7:0]       out_ch,
input  [15:0]      map_size,
input  [31:0]      imap_base_addr,

// imap biu to arbiter req signal
output [31:0]      imap_biu2arb_addr,
output             imap_biu2arb_vld,
input              imap_biu2arb_rdy,

// imap biu to arbiter rsp signal
input  [31:0]      arb2imap_biu_addr,
input  [31:0]      arb2imap_biu_data,
input              arb2imap_biu_vld,
output             arb2imap_biu_rdy,

// imap biu to mac array signal
output [31:0]      imap_waddr,
output [31:0]      imap_wdata,
output             imap_wen

);

endmodule

