// icb interface
interface icb_intf(input clk , input rst_n);

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

    clocking cb @(posedge clk);
        default input #1ns output #1ns;
        
        input   icb_cmd_valid;
        output  icb_cmd_ready;
        input   icb_cmd_read;
        input   icb_cmd_addr;
        input   icb_cmd_wdata;
        input   icb_cmd_wmask;
        output  icb_rsp_valid;
        input   icb_rsp_ready;
        output  icb_rsp_rdata;
        output  icb_rsp_err;
    endclocking 

endinterface