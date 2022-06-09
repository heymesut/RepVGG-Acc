// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 20:50
// Last Modified : 2022/06/09 22:06
// File Name     : imap_buf.v
// Description   : input feature map buffer with 7 SRAMs
//
//
// ---------------------------------------------------------------------------------
// Modification History:
// Date         By              Version                 Change Description
// ---------------------------------------------------------------------------------
// 2022/06/04   Heymesut        1.0                     Original
// -FHDR----------------------------------------------------------------------------
`timescale 1ns/1ps

`define ARRAY_NUM 32

module imap_buf
(
input               clk,
input               rst_n,

// imap biu to imap buf signal
input  [31:0]       imap_waddr,
input  [63:0]       imap_wdata,
input               imap_wen,

// imap buf to mac array signal
input  [31:0]       imap_raddr,
input               imap_ren,
output reg [`ARRAY_NUM*8-1:0] imap_rdata
);

localparam BLOCK_SIZE = 56*56;

wire [31:0] sram_raddr[3:0];
genvar j;
generate
  for(j=0; j<4; j=j+1) begin: sram_raddr_gen
    assign sram_raddr[j] = (2*j+imap_raddr[12])*BLOCK_SIZE + imap_raddr[11:0];
  end
endgenerate

wire [31:0] sram_waddr = imap_waddr;
wire [6:0] sram_cs;
genvar k;
generate
  for(k=0; k<7; k=k+1) begin: sram_cs_gen
    assign sram_cs[k] = (((sram_waddr[14:12]==k) & (imap_wen))    |
                         ((sram_raddr[0][14:12]==k) & (imap_ren)) |
                         ((sram_raddr[1][14:12]==k) & (imap_ren)) |
                         ((sram_raddr[2][14:12]==k) & (imap_ren)) |
                         ((sram_raddr[3][14:12]==k) & (imap_ren)));
  end
endgenerate

wire [11:0] sram_addr [6:0];
wire [63:0] sram_dout [6:0];
genvar i;
generate
  for(i=0; i<7; i=i+1) begin: sram_addr_gen
    assign sram_addr[i] = ((sram_waddr[11:0] & {12{imap_wen}}) |
                           (sram_raddr[0][11:0] & {12{(sram_raddr[0][14:12]==i) & (imap_ren)}}) |
                           (sram_raddr[1][11:0] & {12{(sram_raddr[1][14:12]==i) & (imap_ren)}}) |
                           (sram_raddr[2][11:0] & {12{(sram_raddr[2][14:12]==i) & (imap_ren)}}) |
                           (sram_raddr[3][11:0] & {12{(sram_raddr[3][14:12]==i) & (imap_ren)}}));
    sram_32kb_4kx64 imap_sram_buf (
      .clk(clk),
      .din(imap_wdata),
      .addr(sram_addr[i]),
      .cs(sram_cs[i]),
      .we(imap_wen),
      .wem(8'hff),
      .dout(sram_dout[i])
    );
  end
endgenerate

integer m;
always @(*) begin
  imap_rdata = 0;
  for(m=6; m>=0; m=m-1) begin
    if(sram_cs[m]) begin
      imap_rdata = (imap_rdata << 64);
      imap_rdata[63:0] = sram_dout[m];
    end
  end
end

endmodule

