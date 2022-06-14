// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/08 16:23
// Last Modified : 2022/06/14 22:30
// File Name     : mac_array_wlu.v
// Description   : mac array weights load unit
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/08   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

`define ARRAY_NUM 32

module mac_array_wlu
(
input                                 clk,
input                                 rst_n,

// weight biu to mac array signal
input  [31:0]                         weight_waddr,
input  [31:0]                         weight_wdata,
input                                 weight_wen,

// to weight buffer in every pe
output [(`ARRAY_NUM/4)*32-1:0]        weight_load,
output [`ARRAY_NUM*10-1:0]            weight_load_en,
output [1:0]                          weight_load_sel
);

// waddr[31]: 3x3 or 1x1
// waddr[30:23] : out_ch
// waddr[3:0]: in_ch
// waddr[9:6]: offset in 2D 3x3 kernel

genvar i;
generate
  for(i=0; i<(`ARRAY_NUM/4); i=i+1) begin: weight_load_gen
     assign weight_load[i*32+:32] = (weight_waddr[2:0]==i) ? weight_wdata : 32'b0;
  end
endgenerate



wire [9:0] weight_load_en_base;
assign weight_load_en_base[9] = weight_waddr[31] & weight_wen;
assign weight_load_en_base[8:0] = (weight_waddr[31] ? 9'b0 : (1<<weight_waddr[9:6])) & {9{weight_wen}};

genvar j;
generate
  for(j=0; j<(`ARRAY_NUM/4); j=j+1) begin: weight_load_en_gen
     assign weight_load_en[(j*4)*10+:10] = (weight_waddr[2:0]==j) ? weight_load_en_base : 10'b0;
     assign weight_load_en[(j*4+1)*10+:10] = (weight_waddr[2:0]==j) ? weight_load_en_base : 10'b0;
     assign weight_load_en[(j*4+2)*10+:10] = (weight_waddr[2:0]==j) ? weight_load_en_base : 10'b0;
     assign weight_load_en[(j*4+3)*10+:10] = (weight_waddr[2:0]==j) ? weight_load_en_base : 10'b0;
  end
endgenerate



// ping pong exchange
reg weight_load_sel_base;
always @(posedge clk) begin
  if(!rst_n)
    weight_load_sel_base <= 1'b0;
  else
    if(weight_waddr[3:0]==4'd15 && weight_waddr[31])
      weight_load_sel_base <= ~weight_load_sel_base;
    else
      weight_load_sel_base <= weight_load_sel_base;
end

assign weight_load_sel = {weight_load_sel_base, weight_waddr[3]};

endmodule


