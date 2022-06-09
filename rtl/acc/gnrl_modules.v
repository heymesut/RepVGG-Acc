// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/09 21:48
// Last Modified : 2022/06/09 21:58
// File Name     : gnrl_modules.v
// Description   : general modules from sirv
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/09   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

// ===========================================================================
//
// Description:
//  Verilog module sirv_gnrl DFF with Load-enable and Reset
//  Default reset value is 0
//
// ===========================================================================

module sirv_gnrl_dfflr # (
  parameter DW = 32
) (

  input               lden,
  input      [DW-1:0] dnxt,
  output     [DW-1:0] qout,

  input               clk,
  input               rst_n
);

reg [DW-1:0] qout_r;

always @(posedge clk or negedge rst_n)
begin : DFFLR_PROC
  if (rst_n == 1'b0)
    qout_r <= {DW{1'b0}};
  else if (lden == 1'b1)
    qout_r <=  dnxt;
end

assign qout = qout_r;

endmodule

// ===========================================================================
//
// Description:
//  Verilog module sirv_gnrl DFF with Load-enable, no reset
//
// ===========================================================================

module sirv_gnrl_dffl # (
  parameter DW = 32
) (

  input               lden,
  input      [DW-1:0] dnxt,
  output     [DW-1:0] qout,

  input               clk
);

reg [DW-1:0] qout_r;

always @(posedge clk)
begin : DFFL_PROC
  if (lden == 1'b1)
    qout_r <=  dnxt;
end

assign qout = qout_r;

endmodule

// ===========================================================================
//
// Description:
//  Verilog module sirv_gnrl DFF with Reset, no load-enable
//  Default reset value is 0
//
// ===========================================================================

module sirv_gnrl_dffr # (
  parameter DW = 32
) (

  input      [DW-1:0] dnxt,
  output     [DW-1:0] qout,

  input               clk,
  input               rst_n
);

reg [DW-1:0] qout_r;

always @(posedge clk or negedge rst_n)
begin : DFFR_PROC
  if (rst_n == 1'b0)
    qout_r <= {DW{1'b0}};
  else
    qout_r <=  dnxt;
end

assign qout = qout_r;

endmodule


//=====================================================================
//
//
// Description:
//  The simulation model of SRAM
//
// ====================================================================
module sirv_sim_ram
#(parameter DP = 512,
  parameter FORCE_X2ZERO = 0,
  parameter DW = 32,
  parameter MW = 4,
  parameter AW = 32
)
(
  input             clk,
  input  [DW-1  :0] din,
  input  [AW-1  :0] addr,
  input             cs,
  input             we,
  input  [MW-1:0]   wem,
  output [DW-1:0]   dout
);

    reg [DW-1:0] mem_r [0:DP-1];
    reg [AW-1:0] addr_r;
    wire [MW-1:0] wen;
    wire ren;

    assign ren = cs & (~we);
    assign wen = ({MW{cs & we}} & wem);



    genvar i;

    always @(posedge clk)
    begin
        if (ren) begin
            addr_r <= addr;
        end
    end

    generate
      for (i = 0; i < MW; i = i+1) begin :mem
        if((8*i+8) > DW ) begin: last
          always @(posedge clk) begin
            if (wen[i]) begin
               mem_r[addr][DW-1:8*i] <= din[DW-1:8*i];
            end
          end
        end
        else begin: non_last
          always @(posedge clk) begin
            if (wen[i]) begin
               mem_r[addr][8*i+7:8*i] <= din[8*i+7:8*i];
            end
          end
        end
      end
    endgenerate

  wire [DW-1:0] dout_pre;
  assign dout_pre = mem_r[addr_r];

  generate
   if(FORCE_X2ZERO == 1) begin: force_x_to_zero
      for (i = 0; i < DW; i = i+1) begin:force_x_gen
          `ifndef SYNTHESIS//{
         assign dout[i] = (dout_pre[i] === 1'bx) ? 1'b0 : dout_pre[i];
          `else//}{
         assign dout[i] = dout_pre[i];
          `endif//}
      end
   end
   else begin:no_force_x_to_zero
     assign dout = dout_pre;
   end
  endgenerate


endmodule


// pipeline stage
module sirv_gnrl_pipe_stage # (
  // When the depth is 1, the ready signal may relevant to next stage's ready, hence become logic
  // chains. Use CUT_READY to control it
  parameter CUT_READY = 0,
  parameter DP = 1,
  parameter DW = 32
) (
  input           i_vld,
  output          i_rdy,
  input  [DW-1:0] i_dat,
  output          o_vld,
  input           o_rdy,
  output [DW-1:0] o_dat,

  input           clk,
  input           rst_n
);

  genvar i;
  generate //{

  if(DP == 0) begin: dp_eq_0//{ pass through

      assign o_vld = i_vld;
      assign i_rdy = o_rdy;
      assign o_dat = i_dat;

  end//}
  else begin: dp_gt_0//{

      wire vld_set;
      wire vld_clr;
      wire vld_ena;
      wire vld_r;
      wire vld_nxt;

      // The valid will be set when input handshaked
      assign vld_set = i_vld & i_rdy;
      // The valid will be clr when output handshaked
      assign vld_clr = o_vld & o_rdy;

      assign vld_ena = vld_set | vld_clr;
      assign vld_nxt = vld_set | (~vld_clr);

      sirv_gnrl_dfflr #(1) vld_dfflr (vld_ena, vld_nxt, vld_r, clk, rst_n);

      assign o_vld = vld_r;

      sirv_gnrl_dffl #(DW) dat_dfflr (vld_set, i_dat, o_dat, clk);

      if(CUT_READY == 1) begin:cut_ready//{
          // If cut ready, then only accept when stage is not full
          assign i_rdy = (~vld_r);
      end//}
      else begin:no_cut_ready//{
          // If not cut ready, then can accept when stage is not full or it is popping
          assign i_rdy = (~vld_r) | vld_clr;
      end//}
  end//}
  endgenerate//}


endmodule


