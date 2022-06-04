// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 21:03
// Last Modified : 2022/06/04 22:21
// File Name     : map_merger.v
// Description   : merge 3x3 omap, 1x1 omap and identity map with quantization
//                 and activation
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module map_merger
(
input                       clk,
input                       rst_n,

// psum acc to map_merger signal
input  [63:0]               psum_acc2map_merger_data,
input                       psum_acc2map_merger_vld,
output                      psum_acc2map_merger_rdy,

// map merger to omap biu signal
output  [31:0]              map_merger2omap_biu_data,
output                      map_merger2omap_biu_vld,
input                       map_merger2omap_biu_rdy
);


endmodule

