// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 21:43
// Last Modified : 2022/06/05 15:00
// File Name     : icb_master.v
// Description   : icb master interface with an arbiter
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module icb_master
(
input                           clk,
input                           rst_n,

// weight biu to arbiter req signal
input                           weight_biu2arb_req,
input [31:0]                    weight_biu2arb_addr,
input                           weight_biu2arb_vld,
output                          weight_biu2arb_rdy,

// weight biu to arbiter rsp signal
output  [31:0]                  arb2weight_biu_addr,
output  [31:0]                  arb2weight_biu_data,
output                          arb2weight_biu_vld,
input                           arb2weight_biu_rdy,

// imap biu to arbiter req signal
input                           imap_biu2arb_req,
input [31:0]                    imap_biu2arb_addr,
input                           imap_biu2arb_vld,
output                          imap_biu2arb_rdy,

// imap biu to arbiter rsp signal
output  [31:0]                  arb2imap_biu_addr,
output  [31:0]                  arb2imap_biu_data,
output                          arb2imap_biu_vld,
input                           arb2imap_biu_rdy,

// omap biu to arbiter req signal
input                           omap_biu2arb_req,
input [31:0]                    omap_biu2arb_addr,
input [31:0]                    omap_biu2arb_data,
input                           omap_biu2arb_vld,
output                          omap_biu2arb_rdy,

// icb master interface
output                          acc_icb_cmd_valid,
input                           acc_icb_cmd_ready,
output [31:0]                   acc_icb_cmd_addr,
output                          acc_icb_cmd_read,
output [31:0]                   acc_icb_cmd_wdata,
output [3:0]                    acc_icb_cmd_wmask,

input                           acc_icb_rsp_valid,
output                          acc_icb_rsp_ready,
input                           acc_icb_rsp_err  ,
input  [31:0]                   acc_icb_rsp_rdata
);

endmodule

