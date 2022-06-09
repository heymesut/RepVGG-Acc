// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 21:36
// Last Modified : 2022/06/09 22:15
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
output reg             acc_done,

output reg             weight_start,
output [7:0]           weight_och_cnt,
input                  weight_done,

output reg             imap_start,
input                  imap_done,

output reg             conv_start,
input                  conv_done,

input  [7:0]           out_ch_cnt

);

localparam idle = 2'b00;
localparam wsetup = 2'b01;
localparam isetup = 2'b10;
localparam conv = 2'b11;

//////////////////////////////////
//
// FSM
//
//////////////////////////////////

reg [1:0] state;
reg [1:0] next_state;

always @(posedge clk) begin
  if(!rst_n)
    state <= idle;
  else
    state <= next_state;
end

always @(*) begin
  case (state)
    idle: begin
      if(acc_start)
        next_state = wsetup;
      else
        next_state = idle;
    end

    wsetup: begin
      if(weight_done)
        next_state = isetup;
      else
        next_state = wsetup;
    end

    isetup: begin
      if(imap_done)
        next_state = conv;
      else
        next_state = isetup;
    end

    conv: begin
      if(conv_done)
        next_state = idle;
      else
        next_state = conv;
    end

    default: begin
      next_state = idle;
    end
  endcase
end

/////////////////////////////////
//
// FSM Output
//
/////////////////////////////////

// weight_start
reg [7:0] out_ch_cnt_d;
always @(posedge clk) begin
  if(!rst_n)
    out_ch_cnt_d <= 8'b0;
  else
    out_ch_cnt_d <= out_ch_cnt;
end

always @(posedge clk) begin
  if(!rst_n)
    weight_start <= 1'b0;
  else
    if(weight_start==1'b1)
      weight_start <= 1'b0;
    else
      if(((state==idle) && (next_state==wsetup)) || ((state==isetup) && (next_state==conv)) || ((out_ch_cnt!=out_ch_cnt_d) && (out_ch_cnt<63)))
        weight_start <= 1'b1;
      else
       weight_start <= weight_start;
end

// weight_och_cnt
assign weight_och_cnt = (state==wsetup) ? 8'b0 : (out_ch_cnt + 1);

// imap_start
always @(posedge clk) begin
  if(!rst_n)
    imap_start <= 1'b0;
  else
    if(imap_start)
      imap_start <= 1'b0;
    else
      if((state==wsetup) && (next_state==isetup))
        imap_start <= 1'b1;
      else
        imap_start <= imap_start;
end

// conv_start
always @(posedge clk) begin
  if(!rst_n)
    conv_start <= 1'b0;
  else
    if(conv_start)
      conv_start <= 1'b0;
    else
      if((state==isetup) && (next_state==conv))
        conv_start <= 1'b1;
      else
        conv_start <= conv_start;
end

// acc_done
always @(posedge clk) begin
  if(!rst_n)
    acc_done <= 1'b0;
  else
    if(acc_done)
      acc_done <= 1'b0;
    else
      if(conv_done)
        acc_done <= 1'b1;
      else
        acc_done <= acc_done;
end

endmodule

