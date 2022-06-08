// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 20:04
// Last Modified : 2022/06/08 20:54
// File Name     : mac_array.v
// Description   : mac array, including 32 3x3 conv systolic arrays, 32 1x1 conv units and adder tree
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

module mac_array
(

input                  clk,
input                  rst_n,

// control signal
input                  conv_start,
output                 conv_done,
output [7:0]           out_ch_cnt,
output                 omap_write_req,
input  [7:0]           in_ch,
input  [7:0]           out_ch,
input  [15:0]          map_size,

// weight biu to mac array signal
input  [31:0]          weight_waddr,
input  [31:0]          weight_wdata,
input                  weight_wen,

// mac array to imap buf signal
output [31:0]          imap_raddr,
output                 imap_ren,
input  [`ARRAY_NUM*8-1:0] imap_rdata,

// mac array to psum acc signal
output [31:0]          mac_array2psum_acc_info,
output [63:0]          mac_array2psum_acc_data, // [8 bit identity, 24 bit 1x1 psum, 32 bit 3x3 psum]
output                 mac_array2psum_acc_vld,
input                  mac_array2psum_acc_rdy

);


/*autowire*/
//Start of automatic wire
//Define assign wires here
//Define instance wires here
wire                            pipe_en                     ;
wire [9:0]                      pe_en                       ;
wire [(`ARRAY_NUM/4)*32-1:0]    weight_load                 ;
wire [`ARRAY_NUM*10-1:0]        weight_load_en              ;
wire [1:0]                      weight_load_sel             ;
wire [1:0]                      weight_sel                  ;
wire [`ARRAY_NUM*8-1:0]         imap_in                     ;
wire [4:0]                      identity_sel                ;
wire [31:0]                     psum_3x3                    ;
wire [23:0]                     psum_1x1                    ;
wire [7:0]                      identity                    ;
wire                            in_ch_cnt                   ;
//End of automatic wire
assign mac_array2psum_acc_data = {identity, psum_1x1, psum_3x3};

mac_array_core mac_array_core_u(
/*autoinst*/
        .clk                    (clk                                   ), //input
        .rst_n                  (rst_n                                 ), //input
        .pipe_en                (pipe_en                               ), //input
        .pe_en                  (pe_en[9:0]                            ), //input
        .weight_load            (weight_load[(`ARRAY_NUM/4)*32-1:0]    ), //input
        .weight_load_en         (weight_load_en[`ARRAY_NUM*10-1:0]     ), //input
        .weight_load_sel        (weight_load_sel[1:0]                  ), //input
        .weight_sel             (weight_sel[1:0]                       ), //input
        .imap_in                (imap_in[`ARRAY_NUM*8-1:0]             ), //input
        .identity_sel           (identity_sel[4:0]                     ), //input
        .psum_3x3               (psum_3x3[31:0]                        ), //output
        .psum_1x1               (psum_1x1[23:0]                        ), //output
        .identity               (identity[7:0]                         )  //output
    );

mac_array_fsm mac_array_fsm_u(
/*autoinst*/
        .clk                        (clk                              ), //input
        .rst_n                      (rst_n                            ), //input
        .conv_start                 (conv_start                       ), //input
        .mac_array2psum_acc_rdy     (mac_array2psum_acc_rdy           ), //input
        .out_ch_cnt                 (out_ch_cnt[7:0]                  ), //output
        .in_ch_cnt                  (in_ch_cnt                        ), //output
        .omap_write_req             (omap_write_req                   ), //output
        .mac_array2psum_acc_vld     (mac_array2psum_acc_vld           ), //output
        .conv_done                  (conv_done                        ), //output
        .pipe_en                    (pipe_en                          ), //output
        .pe_en                      (pe_en[9:0]                       ), //output
        .weight_sel                 (weight_sel[1:0]                  ), //output
        .imap_raddr                 (imap_raddr[31:0]                 ), //output
        .imap_ren                   (imap_ren                         ), //output
        .mac_array2psum_acc_info    (mac_array2psum_acc_info[31:0]    ), //output
        .identity_sel               (identity_sel[4:0]                )  //output
    );

mac_array_wlu mac_array_wlu_u(
/*autoinst*/
        .clk                    (clk                                   ), //input
        .rst_n                  (rst_n                                 ), //input
        .weight_waddr           (weight_waddr[31:0]                    ), //input
        .weight_wdata           (weight_wdata[31:0]                    ), //input
        .weight_wen             (weight_wen                            ), //input
        .weight_load            (weight_load[(`ARRAY_NUM/4)*32-1:0]    ), //output
        .weight_load_en         (weight_load_en[`ARRAY_NUM*10-1:0]     ), //output
        .weight_load_sel        (weight_load_sel[1:0]                  )  //output
    );

endmodule

