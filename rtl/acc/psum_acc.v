// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 20:55
// Last Modified : 2022/06/04 22:21
// File Name     : psum_acc.v
// Description   : psum accumulator unit with psum buffer
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module psum_acc
(
input                       clk,
input                       rst_n,

// mac array to psum acc signal
input  [31:0]               mac_array2psum_acc_addr,
input  [63:0]               mac_array2psum_acc_data,
input                       mac_array2psum_acc_vld,
output                      mac_array2psum_acc_rdy,

// psum acc to map_merger signal
output [63:0]               psum_acc2map_merger_data,
output                      psum_acc2map_merger_vld,
input                       psum_acc2map_merger_rdy
);

endmodule

