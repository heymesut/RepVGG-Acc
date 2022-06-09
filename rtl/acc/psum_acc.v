// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 20:55
// Last Modified : 2022/06/09 12:34
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
input  [31:0]               mac_array2psum_acc_info,
input  [63:0]               mac_array2psum_acc_data,
input                       mac_array2psum_acc_vld,
output                      mac_array2psum_acc_rdy,

// psum acc to map_merger signal
output [63:0]               psum_acc2map_merger_data,
output                      psum_acc2map_merger_vld,
input                       psum_acc2map_merger_rdy
);


// input handshake
wire psum_acc_vld_in = mac_array2psum_acc_vld;
wire psum_acc_rdy_in;
assign mac_array2psum_acc_rdy = psum_acc_rdy_in;
wire [63:0] psum_acc_data_in = mac_array2psum_acc_data;
wire [31:0] psum_acc_info_in = mac_array2psum_acc_info;


assign psum_acc_rdy_in = psum_acc_info_in[12] ? psum_acc_rdy_out : 1'b1;
wire psum_acc_hdshk_in = psum_acc_vld_in & psum_acc_rdy_in;

// psum accumulation

// the first input channel group: write to buffer; the second input channel
// group: read psum from buffer and add with psum_acc_data_in;
wire we = ~psum_acc_info_in[12];
wire cs = psum_acc_hdshk_in;
wire identity_sel = psum_acc_info_in[13];
wire [11:0] sram_addr = psum_acc_info_in[11:0];
wire [63:0] sram_dout;

// to sync with sram_dout, delay one cycle
wire [63:0] data_d;
wire        identity_sel_d;
wire ld_en = psum_acc_hdshk_in & psum_acc_info_in[12];
sirv_gnrl_dfflr #(64)  psum_acc_data_in_dff(ld_en, psum_acc_data_in, data_d, clk, rst_n);
sirv_gnrl_dfflr #(1)   psum_acc_info_in_dff(ld_en, identity_sel, identity_sel_d, clk, rst_n);

// accumulation
assign psum_acc_data_out[31:0] = data_d[31:0] + sram_dout[31:0];
assign psum_acc_data_out[55:32] = data_d[55:32] + sram_dout[55:32];
assign psum_acc_data_out[63:56] = identity_sel_d ? data_d[63:56] : sram_dout[63:56];

// psum buffer
sirv_sim_ram #(
  .DP(4096),
  .FORCE_X2ZERO(0),
  .DW(64),
  .MW(8),
  .AW(12)
) psum_sram_buf (
  .clk(clk),
  .din(psum_acc_data_in),
  .addr(sram_addr),
  .cs(cs),
  .we(we),
  .wem(8'hff),
  .dout(sram_dout)
);

// output pipe stage
reg  psum_acc_vld_out;
wire psum_acc_rdy_out;
wire [63:0] psum_acc_data_out;

sirv_gnrl_pipe_stage #(
  .CUT_READY(0),
  .DP(1),
  .DW(64)
) psum_acc2map_merger_data_pipe_stage(
  .i_vld(psum_acc_vld_out),
  .i_rdy(psum_acc_rdy_out),
  .i_dat(psum_acc_data_out),

  .o_vld(psum_acc2map_merger_vld),
  .o_rdy(psum_acc2map_merger_rdy),
  .o_dat(psum_acc2map_merger_data),

  .clk(clk),
  .rst_n(rst_n)
);

always @(posedge clk) begin
  if(!rst_n)
    psum_acc_vld_out <= 1'b0;
  else
    if(~psum_acc_info_in[12])
      psum_acc_vld_out <= 1'b0;
    else
      psum_acc_vld_out <= psum_acc_hdshk_in;
end

endmodule

