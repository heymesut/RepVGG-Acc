// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 20:00
// Last Modified : 2022/06/04 22:21
// File Name     : omap_biu.v
// Description   : output feature map bus interface unit
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module omap_biu
(
input              clk,
input              rst_n,

// control signal
input  [7:0]       in_ch,
input  [7:0]       out_ch,
input  [15:0]      map_size,
input  [31:0]      omap_base_addr,
input  [7:0]       out_ch_cnt,

// omap biu to arbiter req signal
output [31:0]      omap_biu2arb_addr,
output [31:0]      omap_biu2arb_data,
output             omap_biu2arb_vld,
input              omap_biu2arb_rdy,

// map merger to omap biu signal
input  [31:0]      map_merger2omap_biu_data,
input              map_merger2omap_biu_vld,
output             map_merger2omap_biu_rdy

);

endmodule

