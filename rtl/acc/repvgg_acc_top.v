// +FHDR----------------------------------------------------------------------------
// Project Name  : IC_Design
// Author        : Heymesut
// Created On    : 2022/06/04 21:34
// Last Modified : 2022/06/12 16:30
// File Name     : repvgg_acc_top.v
// Description   : RepVGG accelerator top module
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

module repvgg_acc_top
(
input                           clk,
input                           rst_n,

// icb slave
input                           icb_cmd_valid,
output                          icb_cmd_ready,
input                           icb_cmd_read,
input       [31:0]              icb_cmd_addr,
input       [31:0]              icb_cmd_wdata,
input       [3:0]               icb_cmd_wmask,

output                          icb_rsp_valid,
input                           icb_rsp_ready,
output      [31:0]              icb_rsp_rdata,
output                          icb_rsp_err,

// icb master
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

/*autowire*/
//Start of automatic wire
//Define assign wires here
//Define instance wires here
wire [31:0]                 IN_ADDR                         ;
wire [31:0]                 W3_ADDR                         ;
wire [31:0]                 W1_ADDR                         ;
wire [31:0]                 OUT_ADDR                        ;
wire [31:0]                 START                           ;
wire [31:0]                 MAPSIZE                         ;
wire [31:0]                 ICH                             ;
wire [31:0]                 OCH                             ;
wire [31:0]                 DONE                            ;
wire                        acc_done                        ;
wire                        weight_biu2arb_req              ;
wire [31:0]                 weight_biu2arb_addr             ;
wire                        weight_biu2arb_vld              ;
wire                        weight_biu2arb_rdy              ;
wire [31:0]                 arb2weight_biu_addr             ;
wire [31:0]                 arb2weight_biu_data             ;
wire                        arb2weight_biu_vld              ;
wire                        arb2weight_biu_rdy              ;
wire                        imap_biu2arb_req                ;
wire [31:0]                 imap_biu2arb_addr               ;
wire                        imap_biu2arb_vld                ;
wire                        imap_biu2arb_rdy                ;
wire [31:0]                 arb2imap_biu_addr               ;
wire [31:0]                 arb2imap_biu_data               ;
wire                        arb2imap_biu_vld                ;
wire                        arb2imap_biu_rdy                ;
wire                        omap_biu2arb_req                ;
wire [31:0]                 omap_biu2arb_addr               ;
wire [31:0]                 omap_biu2arb_data               ;
wire                        omap_biu2arb_vld                ;
wire                        omap_biu2arb_rdy                ;
wire [7:0]                  in_ch                           ;
wire [7:0]                  out_ch                          ;
wire [15:0]                 map_size                        ;
wire                        acc_start                       ;
wire                        weight_start                    ;
wire [7:0]                  weight_och_cnt                  ;
wire                        weight_done                     ;
wire                        imap_start                      ;
wire                        imap_done                       ;
wire                        conv_start                      ;
wire                        conv_done                       ;
wire [7:0]                  out_ch_cnt                      ;
wire [31:0]                 weight_waddr                    ;
wire [31:0]                 weight_wdata                    ;
wire                        weight_wen                      ;
wire [31:0]                 imap_raddr                      ;
wire                        imap_ren                        ;
wire [`ARRAY_NUM*8-1:0]     imap_rdata                      ;
wire [31:0]                 mac_array2psum_acc_info         ;
wire [63:0]                 mac_array2psum_acc_data         ;
wire                        mac_array2psum_acc_vld          ;
wire                        mac_array2psum_acc_rdy          ;
wire [63:0]                 psum_acc2map_merger_data        ;
wire                        psum_acc2map_merger_vld         ;
wire                        psum_acc2map_merger_rdy         ;
wire [31:0]                 map_merger2omap_biu_data        ;
wire                        map_merger2omap_biu_vld         ;
wire                        map_merger2omap_biu_rdy         ;
wire [31:0]                 omap_base_addr                  ;
wire [31:0]                 weight3_base_addr               ;
wire [31:0]                 weight1_base_addr               ;
wire [31:0]                 imap_base_addr                  ;
wire [31:0]                 imap_waddr                      ;
wire [63:0]                 imap_wdata                      ;
wire                        imap_wen                        ;
//End of automatic wire

assign imap_base_addr = IN_ADDR;
assign weight3_base_addr = W3_ADDR;
assign weight1_base_addr = W1_ADDR;
assign omap_base_addr = OUT_ADDR;
assign in_ch = ICH;
assign out_ch = OCH;
assign map_size = MAPSIZE;
assign acc_start = START;

// slave interface
icb_slave icb_slave_u(
/*autoinst*/
        .icb_cmd_valid          (icb_cmd_valid                  ), //input
        .icb_cmd_ready          (icb_cmd_ready                  ), //output
        .icb_cmd_read           (icb_cmd_read                   ), //input
        .icb_cmd_addr           (icb_cmd_addr[31:0]             ), //input
        .icb_cmd_wdata          (icb_cmd_wdata[31:0]            ), //input
        .icb_cmd_wmask          (icb_cmd_wmask[3:0]             ), //input
        .icb_rsp_valid          (icb_rsp_valid                  ), //output
        .icb_rsp_ready          (icb_rsp_ready                  ), //input
        .icb_rsp_rdata          (icb_rsp_rdata[31:0]            ), //output
        .icb_rsp_err            (icb_rsp_err                    ), //output
        .clk                    (clk                            ), //input
        .rst_n                  (rst_n                          ), //input
        .IN_ADDR                (IN_ADDR[31:0]                  ), //output
        .W3_ADDR                (W3_ADDR[31:0]                  ), //output
        .W1_ADDR                (W1_ADDR[31:0]                  ), //output
        .OUT_ADDR               (OUT_ADDR[31:0]                 ), //output
        .START                  (START[31:0]                    ), //output
        .MAPSIZE                (MAPSIZE[31:0]                  ), //output
        .ICH                    (ICH[31:0]                      ), //output
        .OCH                    (OCH[31:0]                      ), //output
        .DONE                   (DONE[31:0]                     ), //output
        .acc_done               (acc_done                       )  //input
    );

// master interface
icb_master icb_master_u(
/*autoinst*/
        .clk                    (clk                            ), //input
        .rst_n                  (rst_n                          ), //input
        .weight_biu2arb_req     (weight_biu2arb_req             ), //input
        .weight_biu2arb_addr    (weight_biu2arb_addr[31:0]      ), //input
        .weight_biu2arb_vld     (weight_biu2arb_vld             ), //input
        .weight_biu2arb_rdy     (weight_biu2arb_rdy             ), //output
        .arb2weight_biu_addr    (arb2weight_biu_addr[31:0]      ), //output
        .arb2weight_biu_data    (arb2weight_biu_data[31:0]      ), //output
        .arb2weight_biu_vld     (arb2weight_biu_vld             ), //output
        .arb2weight_biu_rdy     (arb2weight_biu_rdy             ), //input
        .imap_biu2arb_req       (imap_biu2arb_req               ), //input
        .imap_biu2arb_addr      (imap_biu2arb_addr[31:0]        ), //input
        .imap_biu2arb_vld       (imap_biu2arb_vld               ), //input
        .imap_biu2arb_rdy       (imap_biu2arb_rdy               ), //output
        .arb2imap_biu_addr      (arb2imap_biu_addr[31:0]        ), //output
        .arb2imap_biu_data      (arb2imap_biu_data[31:0]        ), //output
        .arb2imap_biu_vld       (arb2imap_biu_vld               ), //output
        .arb2imap_biu_rdy       (arb2imap_biu_rdy               ), //input
        .omap_biu2arb_req       (omap_biu2arb_req               ), //input
        .omap_biu2arb_addr      (omap_biu2arb_addr[31:0]        ), //input
        .omap_biu2arb_data      (omap_biu2arb_data[31:0]        ), //input
        .omap_biu2arb_vld       (omap_biu2arb_vld               ), //input
        .omap_biu2arb_rdy       (omap_biu2arb_rdy               ), //output
        .acc_icb_cmd_valid      (acc_icb_cmd_valid              ), //output
        .acc_icb_cmd_ready      (acc_icb_cmd_ready              ), //input
        .acc_icb_cmd_addr       (acc_icb_cmd_addr[31:0]         ), //output
        .acc_icb_cmd_read       (acc_icb_cmd_read               ), //output
        .acc_icb_cmd_wdata      (acc_icb_cmd_wdata[31:0]        ), //output
        .acc_icb_cmd_wmask      (acc_icb_cmd_wmask[3:0]         ), //output
        .acc_icb_rsp_valid      (acc_icb_rsp_valid              ), //input
        .acc_icb_rsp_ready      (acc_icb_rsp_ready              ), //output
        .acc_icb_rsp_err        (acc_icb_rsp_err                ), //input
        .acc_icb_rsp_rdata      (acc_icb_rsp_rdata[31:0]        )  //input
    );

// control
main_fsm main_fsm_u(
/*autoinst*/
        .clk                    (clk                            ), //input
        .rst_n                  (rst_n                          ), //input
        .in_ch                  (in_ch[7:0]                     ), //input
        .out_ch                 (out_ch[7:0]                    ), //input
        .map_size               (map_size[15:0]                 ), //input
        .acc_start              (acc_start                      ), //input
        .acc_done               (acc_done                       ), //output
        .weight_start           (weight_start                   ), //output
        .weight_och_cnt         (weight_och_cnt[7:0]            ), //output
        .weight_done            (weight_done                    ), //input
        .imap_start             (imap_start                     ), //output
        .imap_done              (imap_done                      ), //input
        .conv_start             (conv_start                     ), //output
        .conv_done              (conv_done                      ), //input
        .out_ch_cnt             (out_ch_cnt[7:0]                )  //input
    );

// main datapath
mac_array mac_array_u(
/*autoinst*/
        .clk                        (clk                              ), //input
        .rst_n                      (rst_n                            ), //input
        .conv_start                 (conv_start                       ), //input
        .conv_done                  (conv_done                        ), //output
        .out_ch_cnt                 (out_ch_cnt[7:0]                  ), //output
        .in_ch                      (in_ch[7:0]                       ), //input
        .out_ch                     (out_ch[7:0]                      ), //input
        .map_size                   (map_size[15:0]                   ), //input
        .weight_waddr               (weight_waddr[31:0]               ), //input
        .weight_wdata               (weight_wdata[31:0]               ), //input
        .weight_wen                 (weight_wen                       ), //input
        .imap_raddr                 (imap_raddr[31:0]                 ), //output
        .imap_ren                   (imap_ren                         ), //output
        .imap_rdata                 (imap_rdata[`ARRAY_NUM*8-1:0]     ), //input
        .mac_array2psum_acc_info    (mac_array2psum_acc_info[31:0]    ), //output
        .mac_array2psum_acc_data    (mac_array2psum_acc_data[63:0]    ), //output
        .mac_array2psum_acc_vld     (mac_array2psum_acc_vld           ), //output
        .mac_array2psum_acc_rdy     (mac_array2psum_acc_rdy           )  //input
    );

psum_acc psum_acc_u(
/*autoinst*/
        .clk                         (clk                               ), //input
        .rst_n                       (rst_n                             ), //input
        .mac_array2psum_acc_info     (mac_array2psum_acc_info[31:0]     ), //input
        .mac_array2psum_acc_data     (mac_array2psum_acc_data[63:0]     ), //input
        .mac_array2psum_acc_vld      (mac_array2psum_acc_vld            ), //input
        .mac_array2psum_acc_rdy      (mac_array2psum_acc_rdy            ), //output
        .psum_acc2map_merger_data    (psum_acc2map_merger_data[63:0]    ), //output
        .psum_acc2map_merger_vld     (psum_acc2map_merger_vld           ), //output
        .psum_acc2map_merger_rdy     (psum_acc2map_merger_rdy           )  //input
    );

map_merger map_merger_u(
/*autoinst*/
        .clk                         (clk                               ), //input
        .rst_n                       (rst_n                             ), //input
        .psum_acc2map_merger_data    (psum_acc2map_merger_data[63:0]    ), //input
        .psum_acc2map_merger_vld     (psum_acc2map_merger_vld           ), //input
        .psum_acc2map_merger_rdy     (psum_acc2map_merger_rdy           ), //output
        .map_merger2omap_biu_data    (map_merger2omap_biu_data[31:0]    ), //output
        .map_merger2omap_biu_vld     (map_merger2omap_biu_vld           ), //output
        .map_merger2omap_biu_rdy     (map_merger2omap_biu_rdy           )  //input
    );

omap_biu omap_biu_u(
/*autoinst*/
        .clk                         (clk                               ), //input
        .rst_n                       (rst_n                             ), //input
        .in_ch                       (in_ch[7:0]                        ), //input
        .out_ch                      (out_ch[7:0]                       ), //input
        .map_size                    (map_size[15:0]                    ), //input
        .omap_base_addr              (omap_base_addr[31:0]              ), //input
        .conv_start                  (conv_start                        ), //input
        .omap_biu2arb_req            (omap_biu2arb_req                  ), //output
        .omap_biu2arb_addr           (omap_biu2arb_addr[31:0]           ), //output
        .omap_biu2arb_data           (omap_biu2arb_data[31:0]           ), //output
        .omap_biu2arb_vld            (omap_biu2arb_vld                  ), //output
        .omap_biu2arb_rdy            (omap_biu2arb_rdy                  ), //input
        .map_merger2omap_biu_data    (map_merger2omap_biu_data[31:0]    ), //input
        .map_merger2omap_biu_vld     (map_merger2omap_biu_vld           ), //input
        .map_merger2omap_biu_rdy     (map_merger2omap_biu_rdy           )  //output
    );

// weight and imap bus interface
weight_biu weight_biu_u(
/*autoinst*/
        .clk                    (clk                            ), //input
        .rst_n                  (rst_n                          ), //input
        .weight_start           (weight_start                   ), //input
        .weight_done            (weight_done                    ), //output
        .in_ch                  (in_ch[7:0]                     ), //input
        .out_ch                 (out_ch[7:0]                    ), //input
        .weight3_base_addr      (weight3_base_addr[31:0]        ), //input
        .weight1_base_addr      (weight1_base_addr[31:0]        ), //input
        .weight_och_cnt         (weight_och_cnt[7:0]            ), //input
        .weight_biu2arb_addr    (weight_biu2arb_addr[31:0]      ), //output
        .weight_biu2arb_vld     (weight_biu2arb_vld             ), //output
        .weight_biu2arb_req     (weight_biu2arb_req             ), //output
        .weight_biu2arb_rdy     (weight_biu2arb_rdy             ), //input
        .arb2weight_biu_addr    (arb2weight_biu_addr[31:0]      ), //input
        .arb2weight_biu_data    (arb2weight_biu_data[31:0]      ), //input
        .arb2weight_biu_vld     (arb2weight_biu_vld             ), //input
        .arb2weight_biu_rdy     (arb2weight_biu_rdy             ), //output
        .weight_waddr           (weight_waddr[31:0]             ), //output
        .weight_wdata           (weight_wdata[31:0]             ), //output
        .weight_wen             (weight_wen                     )  //output
    );

imap_biu imap_biu_u(
/*autoinst*/
        .clk                    (clk                            ), //input
        .rst_n                  (rst_n                          ), //input
        .imap_start             (imap_start                     ), //input
        .imap_done              (imap_done                      ), //output
        .in_ch                  (in_ch[7:0]                     ), //input
        .out_ch                 (out_ch[7:0]                    ), //input
        .map_size               (map_size[15:0]                 ), //input
        .imap_base_addr         (imap_base_addr[31:0]           ), //input
        .imap_biu2arb_req       (imap_biu2arb_req               ), //output
        .imap_biu2arb_addr      (imap_biu2arb_addr[31:0]        ), //output
        .imap_biu2arb_vld       (imap_biu2arb_vld               ), //output
        .imap_biu2arb_rdy       (imap_biu2arb_rdy               ), //input
        .arb2imap_biu_addr      (arb2imap_biu_addr[31:0]        ), //input
        .arb2imap_biu_data      (arb2imap_biu_data[31:0]        ), //input
        .arb2imap_biu_vld       (arb2imap_biu_vld               ), //input
        .arb2imap_biu_rdy       (arb2imap_biu_rdy               ), //output
        .imap_waddr             (imap_waddr[31:0]               ), //output
        .imap_wdata             (imap_wdata[63:0]               ), //output
        .imap_wen               (imap_wen                       )  //output
    );

// imap buffer
imap_buf imap_buf_u(
/*autoinst*/
        .clk                    (clk                             ), //input
        .rst_n                  (rst_n                           ), //input
        .imap_waddr             (imap_waddr[31:0]                ), //input
        .imap_wdata             (imap_wdata[63:0]                ), //input
        .imap_wen               (imap_wen                        ), //input
        .imap_raddr             (imap_raddr[31:0]                ), //input
        .imap_ren               (imap_ren                        ), //input
        .imap_rdata             (imap_rdata[`ARRAY_NUM*8-1:0]    )  //output
    );

endmodule

