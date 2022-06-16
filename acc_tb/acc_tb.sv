`timescale 1ns/1ps

module tb_top();

    import env_pkg :: * ;
    
    reg     clk;
    reg     rst_n;

    logic           icb_cmd_valid   ;
    logic           icb_cmd_ready   ;
    logic           icb_cmd_read    ;
    logic   [31:0]  icb_cmd_addr    ;
    logic   [31:0]  icb_cmd_wdata   ;
    logic   [3:0]   icb_cmd_wmask   ;

    logic           icb_rsp_valid   ;
    logic           icb_rsp_ready   ;
    logic   [31:0]  icb_rsp_rdata   ;
    logic           icb_rsp_err     ;

    parameter      clk_period            = 10;

    icb_intf icb_master_intf(clk,rst_n);
    icb_intf icb_slave_intf(clk,rst_n);

    env_test env;

    repvgg_acc_top DUT(
        .clk(clk),
        .rst_n(rst_n),

        .icb_cmd_valid(icb_master_intf.icb_cmd_valid),
        .icb_cmd_ready(icb_master_intf.icb_cmd_ready),
        .icb_cmd_read(icb_master_intf.icb_cmd_read),
        .icb_cmd_addr(icb_master_intf.icb_cmd_addr),
        .icb_cmd_wdata(icb_master_intf.icb_cmd_wdata),
        .icb_cmd_wmask(icb_master_intf.icb_cmd_wmask),

        .icb_rsp_valid(icb_master_intf.icb_rsp_valid),
        .icb_rsp_ready(icb_master_intf.icb_rsp_ready),
        .icb_rsp_rdata(icb_master_intf.icb_rsp_rdata),
        .icb_rsp_err(icb_master_intf.icb_rsp_err),

        .acc_icb_cmd_valid(icb_slave_intf.icb_cmd_valid),
        .acc_icb_cmd_ready(icb_slave_intf.icb_cmd_ready),
        .acc_icb_cmd_read(icb_slave_intf.icb_cmd_read),
        .acc_icb_cmd_addr(icb_slave_intf.icb_cmd_addr),
        .acc_icb_cmd_wdata(icb_slave_intf.icb_cmd_wdata),
        .acc_icb_cmd_wmask(icb_slave_intf.icb_cmd_wmask),

        .acc_icb_rsp_valid(icb_slave_intf.icb_rsp_valid),
        .acc_icb_rsp_ready(icb_slave_intf.icb_rsp_ready),
        .acc_icb_rsp_rdata(icb_slave_intf.icb_rsp_rdata),
        .acc_icb_rsp_err(icb_slave_intf.icb_rsp_err)
    );

    always  #(clk_period/2)     clk = ~clk;

    initial begin
        $fsdbDumpfile("output.fsdb");
        $fsdbDumpvars(0,DUT,"+all");
        $fsdbDumpSVA;
    end

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        #10
        rst_n = 1'b1;
    end

    initial begin
        @(posedge rst_n);
        repeat(1) @(posedge clk);
        $display("new environment");
        env = new();
        env.set_interface(icb_master_intf, icb_slave_intf);
        $display("environment running");
        env.run();
        #30_000_000;
        $display("here");

        env.report();

        $display("**********Verification is done at %t!***************", $time) ;
        $finish;
    end

endmodule