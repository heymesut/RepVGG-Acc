// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/08 10:57
// Last Modified : 2022/06/14 23:26
// File Name     : mac_array_fsm.v
// Description   : mac array control
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/08   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

module mac_array_fsm
(
input                         clk,
input                         rst_n,

input                         conv_start,

input                         mac_array2psum_acc_rdy,

output reg [7:0]              out_ch_cnt,
output reg                    in_ch_cnt,

output                        mac_array2psum_acc_vld,
output reg                    conv_done,

output                        pipe_en,
output     [9:0]              pe_en,
output     [1:0]              weight_sel,

output     [31:0]             imap_raddr,
output                        imap_ren,

output     [31:0]             mac_array2psum_acc_info,

output     [4:0]              identity_sel
);

localparam idle            = 4'b0000;
localparam array_setup     = 4'b0001;
localparam conv_s0         = 4'b0010;
localparam conv_s1         = 4'b0011;
localparam conv_s2         = 4'b0100;
localparam conv_s3         = 4'b0101;
localparam conv_s4         = 4'b0110;
localparam conv_s5         = 4'b0111;
localparam conv_s6         = 4'b1000;
localparam conv_s7         = 4'b1001;
localparam conv_s8         = 4'b1010;
localparam array_cool_down = 4'b1011;

localparam NOCH = 8'd64;

///////////////////
//
// Mac Array FSM
//
///////////////////
reg [3:0] state;
reg [3:0] next_state;
always @ (posedge clk) begin
  if(!rst_n)
    state <= idle;
  else
    state <= next_state;
end


reg [5:0]  setup_cnt;
reg [5:0]  conv_col_cnt;
reg [5:0]  conv_row_cnt;
reg [11:0] imap_cnt;
reg [11:0] omap_cnt;
reg [6:0]  omap_ch_cnt;

always @(*) begin
  case (state)
    idle: begin
      if (conv_start)
       next_state = array_setup;
      else
       next_state = idle;
    end

    array_setup: begin
      if(setup_cnt == 'd58 && pipe_en)
        next_state = conv_s0;
      else
        next_state = array_setup;
    end

    conv_s0: begin
      if((conv_col_cnt=='d0) && (conv_row_cnt=='d0) && pipe_en)
        next_state = conv_s1;
      else
        next_state = conv_s0;
    end

    conv_s1: begin
      if((conv_col_cnt=='d54) && (conv_row_cnt=='d0) && pipe_en)
        next_state = conv_s2;
      else
        next_state = conv_s1;
    end

    conv_s2: begin
      if((conv_col_cnt=='d55) && (conv_row_cnt=='d0) && pipe_en)
        next_state = conv_s3;
      else
        next_state = conv_s2;
    end

    conv_s3: begin
      if((conv_col_cnt=='d0) && (conv_row_cnt>'d0) && (conv_row_cnt<'d55) && pipe_en)
        next_state = conv_s4;
      else
        next_state = conv_s3;
    end

    conv_s4: begin
      if((conv_col_cnt=='d54) && (conv_row_cnt>'d0) && (conv_row_cnt<'d55) && pipe_en)
        next_state = conv_s5;
      else
        next_state = conv_s4;
    end

    conv_s5: begin
      if((conv_col_cnt=='d55) && (conv_row_cnt>'d0) && (conv_row_cnt<'d54) && pipe_en)
        next_state = conv_s3;
      else
        if((conv_col_cnt=='d55) && (conv_row_cnt=='d54) && pipe_en)
          next_state = conv_s6;
        else
          next_state = conv_s5;
    end

    conv_s6: begin
      if((conv_col_cnt=='d0) && (conv_row_cnt=='d55) && pipe_en)
        next_state = conv_s7;
      else
        next_state = conv_s6;
    end

    conv_s7: begin
      if((conv_col_cnt=='d54) && (conv_row_cnt=='d55) && pipe_en)
        next_state = conv_s8;
      else
        next_state = conv_s7;
    end

    conv_s8: begin
      if((conv_col_cnt=='d55) && (conv_row_cnt=='d55) && (out_ch_cnt<(NOCH-1) || (out_ch_cnt==(NOCH-1) && in_ch_cnt==1'b0)) && pipe_en)
        next_state = conv_s0;
      else
        if((conv_col_cnt=='d55) && (conv_row_cnt=='d55) && (out_ch_cnt==(NOCH-1)) && (in_ch_cnt==1'b1) && pipe_en)
          next_state = array_cool_down;
        else
          next_state = conv_s8;
    end

    array_cool_down: begin
      if((omap_cnt=='d3135) && (omap_ch_cnt==(2*NOCH-1)) && pipe_en) // fmap size:  56x56, in_ch: 64/32, out_ch: 64
        next_state = idle;
      else
        next_state = array_cool_down;
    end

    default: begin
      next_state = idle;
    end
  endcase
end


/////////////////////
//
// counter
//
//////////////////////

wire array_en = (state!=idle) && (state!=array_setup) && (state!=array_cool_down);

// setup_cnt
always @(posedge clk) begin
  if(!rst_n)
    setup_cnt <= 6'd0;
  else
    if((state==array_setup) && pipe_en) begin
      if(setup_cnt==6'd58)
        setup_cnt <= 6'd0;
      else
        setup_cnt <= setup_cnt + 1;
    end
    else
      setup_cnt <= setup_cnt;
end

// conv_col_cnt
always @(posedge clk) begin
  if(!rst_n)
    conv_col_cnt <= 6'd0;
  else
    if(array_en && pipe_en) begin
      if(conv_col_cnt==6'd55)
        conv_col_cnt <= 6'd0;
      else
        conv_col_cnt <= conv_col_cnt + 1;
    end
    else
      conv_col_cnt <= conv_col_cnt;
end

// conv_row_cnt
always @(posedge clk) begin
  if(!rst_n)
    conv_row_cnt <= 6'd0;
  else
    if((conv_col_cnt==6'd55) && array_en && pipe_en) begin
      if(conv_row_cnt==6'd55)
        conv_row_cnt <= 6'd0;
      else
        conv_row_cnt <= conv_row_cnt + 1;
    end
    else
      conv_row_cnt <= conv_row_cnt;
end

// in_ch_cnt
always @(posedge clk) begin
  if(!rst_n)
    in_ch_cnt <= 1'b0;
  else
    if((conv_row_cnt==6'd55) && (conv_col_cnt==6'd55) && array_en && pipe_en)
      in_ch_cnt <= ~in_ch_cnt;
   else
      in_ch_cnt <= in_ch_cnt;
end

// out_ch_cnt
always @(posedge clk) begin
  if(!rst_n)
    out_ch_cnt <= 8'd0;
  else
    if((in_ch_cnt==1'b1) && (conv_row_cnt==6'd55) && (conv_col_cnt==6'd55) && array_en && pipe_en)
      if(out_ch_cnt==(NOCH-1))
        out_ch_cnt <= 8'd0;
      else
        out_ch_cnt <= out_ch_cnt + 1;
    else
      out_ch_cnt <= out_ch_cnt;
end


// imap_cnt
always @(posedge clk) begin
  if(!rst_n)
    imap_cnt <= 12'd0;
  else
    if(imap_ren) begin
      if(imap_cnt==12'd3135)
        imap_cnt <= 12'd0;
      else
        imap_cnt <= imap_cnt + 1;
    end
    else
      imap_cnt <= imap_cnt;
end


// omap_cnt
always @(posedge clk) begin
  if(!rst_n)
    omap_cnt <= 12'b0;
  else
    if(mac_array2psum_acc_vld && mac_array2psum_acc_rdy) begin
      if(omap_cnt=='d3135)
        omap_cnt <= 'd0;
      else
        omap_cnt <= omap_cnt + 1;
    end
end

// omap_ch_cnt
always @(posedge clk) begin
  if(!rst_n)
    omap_ch_cnt <= 7'b0;
  else
    if(mac_array2psum_acc_vld && mac_array2psum_acc_rdy && omap_cnt=='d3135) begin
      if(omap_ch_cnt==(2*NOCH-1))
        omap_ch_cnt <= 'd0;
      else
        omap_ch_cnt <= omap_ch_cnt + 1;
    end
end

////////////////////
//
// FSM output
//
////////////////////

// conv done
// when the calculation of the last output channel is done, trigger conv_done
// for 1 cycle
always @(posedge clk) begin
  if(!rst_n)
    conv_done <= 1'b0;
  else
    if(conv_done == 1'b1)
      conv_done <= 1'b0;
    else
      if(state==array_cool_down && next_state==idle)
        conv_done <= 1'b1;
      else
        conv_done <= conv_done;
end




// mac_array2psum_acc_vld
// active when mac_array2psum_acc_data is valid
wire mac_array_out_vld;
assign mac_array_out_vld = array_en;

// to sync with mac_array2psum_acc_data, delay 6 cycles
wire mac_array_out_vld_d [6:0];
assign mac_array_out_vld_d[0] = mac_array_out_vld;
assign mac_array2psum_acc_vld = mac_array_out_vld_d[6];
genvar i;
generate
  for(i=0; i<6; i=i+1) begin: vld_delay
    sirv_gnrl_dfflr #(1) vld_delay_dff(pipe_en, mac_array_out_vld_d[i], mac_array_out_vld_d[i+1], clk, rst_n);
  end
endgenerate

// pipe_en
assign pipe_en = (state!=idle) && mac_array2psum_acc_rdy;

// pe_en
assign pe_en = ((state==conv_s0) ? 10'b1000011011 : (
                (state==conv_s1) ? 10'b1000111111 : (
                (state==conv_s2) ? 10'b1000110110 : (
                (state==conv_s3) ? 10'b1011011011 : (
                (state==conv_s4) ? 10'b1111111111 : (
                (state==conv_s5) ? 10'b1110110110 : (
                (state==conv_s6) ? 10'b1011011000 : (
                (state==conv_s7) ? 10'b1111111000 : (
                (state==conv_s8) ? 10'b1110110000 :
                10'b0000000000)))))))));
// weight_sel
assign weight_sel = {out_ch_cnt[0], in_ch_cnt};

// imap_ren
assign imap_ren = (state!=idle) && (state!=array_cool_down) && pipe_en;

// imap_raddr
assign imap_raddr[12] = in_ch_cnt;
assign imap_raddr[11:0] = imap_cnt;

// mac_array2psum_acc_addr
assign mac_array2psum_acc_info[13] = out_ch_cnt[5]; // 0: out_ch 0~31, 1: out_ch 32~63
assign mac_array2psum_acc_info[12] = omap_ch_cnt[0];  // 0: the 1st input channel group, 1: the 2nd input channel group
assign mac_array2psum_acc_info[11:0] = omap_cnt; // offset in the 2D output feature map

// identity_sel
assign identity_sel = out_ch_cnt[4:0];

endmodule

