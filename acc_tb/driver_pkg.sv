`define IN_ADDR_ADDR    32'h00000000
`define W3_ADDR_ADDR    32'h00000004
`define W1_ADDR_ADDR    32'h00000008
`define OUT_ADDR_ADDR   32'h0000000c
`define START_ADDR      32'h00000010
`define MAPSIZE_ADDR    32'h00000014
`define ICH_ADDR        32'h00000018
`define OCH_ADDR        32'h0000001c
`define DONE_ADDR       32'h00000020

package driver_pkg;

    import generator_pkg :: convdata;

    class icb_driver;
        string name;
        local virtual icb_intf intf_master;
        local virtual icb_intf intf_slave;
        mailbox #(convdata) gen2drv;
        convdata element;
        logic   [31:0]  weight3 [2**18-1:0];
        logic   [31:0]  weight1 [2**18-1:0];
        logic   [31:0]  imap    [2**18-1:0];

        function new(string name="icb_driver", mailbox #(convdata) gen2drv);
            this.name = name;
            this.gen2drv = gen2drv;
            initial_data();
        endfunction

        function void set_interface(virtual icb_intf intf_master, virtual icb_intf intf_slave);
            if(intf_master == null | intf_slave == null)
                $error("interface handle is NULL");
            else
                this.intf_master = intf_master;
                this.intf_slave = intf_slave;
        endfunction

        // initialize the stored data
        task initial_data();
            for(int i=0;i<2**18;i++) begin
                this.weight3[i] = 32'h0;
                this.weight1[i] = 32'h0;
                this.imap[i]    = 32'h0;
            end
        endtask

        // store the data into sram
        task store_data();
            int weight_position=0;
            int imap_position=0;
            int weight_cnt=0;
            int weight_position_cnt=0;
            int weight_popsition=0;
            int weight_bit_cnt=0;
            int weight_ch_cnt=0;
            int weight_line_cnt=0;
            int imap_cnt=0;
            int imap_bit_cnt=0;
            if(gen2drv.num()>0) begin
                gen2drv.get(element);
                if(element.data_type == 0) begin
                    if(weight_cnt < 36864) begin
                        // receive weight3
                        weight_ch_cnt = (weight_cnt - (weight_cnt%576)) / 576;
                        weight_position = weight_ch_cnt * 144 + weight_position_cnt * 16 + weight_line_cnt;
                        case(weight_bit_cnt)
                            0: weight3[weight_position][31:24] = element.data;
                            1: weight3[weight_position][23:16] = element.data;
                            2: weight3[weight_position][15:8]  = element.data;
                            3: weight3[weight_position][7:0]   = element.data;
                        endcase
                        weight_cnt ++;
                        weight_position_cnt ++;
                        if(weight_position_cnt == 9) begin
                            weight_position_cnt = 0;
                            weight_bit_cnt ++;
                            if(weight_bit_cnt == 4) begin
                                weight_bit_cnt = 0;
                                weight_line_cnt ++;
                                if(weight_line_cnt == 16) begin
                                    weight_line_cnt = 0;
                                end
                            end
                        end
                    end
                    else begin
                        // receive weight1
                        weight_ch_cnt = ((weight_cnt -36864)- ((weight_cnt -36864)%576)) / 64;
                        weight_position = weight_ch_cnt * 16 + weight_line_cnt;
                        case(weight_bit_cnt)
                            0: weight1[weight_position][31:24] = element.data;
                            1: weight1[weight_position][23:16] = element.data;
                            2: weight1[weight_position][15:8]  = element.data;
                            3: weight1[weight_position][7:0]   = element.data;
                        endcase
                        weight_cnt ++;
                        weight_bit_cnt ++;
                        if(weight_bit_cnt == 4) begin
                            weight_bit_cnt = 0;
                            weight_line_cnt ++;
                            if(weight_line_cnt == 16) begin
                                weight_line_cnt = 0;
                            end
                        end
                    end
                end
                else if(element.data_type == 1) begin
                    imap_bit_cnt = imap_cnt%4;
                    imap_position = (imap_cnt - imap_bit_cnt) / 4;
                    case(imap_bit_cnt)
                        0: imap[imap_position][31:24] = element.data;
                        1: imap[imap_position][23:16] = element.data;
                        2: imap[imap_position][15:8]  = element.data;
                        3: imap[imap_position][7:0]   = element.data;
                    endcase
                    imap_cnt ++;
                end
            end
        endtask

        // setting the configuration of acc
        task acc_initialize();
            write_reg(`ICH_ADDR, 32'd64);
            write_reg(`OCH_ADDR, 32'd64);
            write_reg(`MAPSIZE_ADDR, 32'd56);
            write_reg(`IN_ADDR_ADDR, 32'h0000_0000);
            write_reg(`W3_ADDR_ADDR, 32'h1000_0000);
            write_reg(`W1_ADDR_ADDR, 32'h2000_0000);
            write_reg(`OUT_ADDR_ADDR, 32'h3000_0000);
            write_reg(`START_ADDR, 32'b1);
        endtask

        task run();
            acc_initialize();
            forever begin
                intf_slave.icb_cmd_ready <= 1'b1;
                intf_slave.icb_rsp_err <= 1'b0;
                @(posedge intf_slave.clk)
                if(intf_slave.icb_cmd_ready & intf_slave.icb_cmd_ready) begin
                    if(intf_slave.icb_cmd_read == 1) begin
                        intf_slave.icb_rsp_valid <= 1'b1;
                        case(intf_slave.icb_cmd_addr[31:28])
                            4'b0000: intf_slave.icb_rsp_rdata <= imap[intf_slave.icb_cmd_addr[27:0]];
                            4'b0001: intf_slave.icb_rsp_rdata <= weight3[intf_slave.icb_cmd_addr[27:0]];
                            4'b0010: intf_slave.icb_rsp_rdata <= weight1[intf_slave.icb_cmd_addr[27:0]];
                        endcase
                    end
                    else begin
                        intf_slave.icb_rsp_valid <= 1'b1;
                    end
                end
                else begin
                    intf_slave.icb_rsp_valid <= 1'b0;
                end
            end
        endtask

        // wirte reg
        task write_reg ;
            input  [31:0]    addr;
            input  [31:0]   wdata;
            begin
                @(posedge intf_master.clk) ;
                intf_master.icb_cmd_addr   <= addr;
                intf_master.icb_cmd_valid  <= 1'b1;
                intf_master.icb_cmd_read   <= 1'b0;
                intf_master.icb_cmd_wdata  <= wdata;
                intf_master.icb_cmd_wmask  <= 4'b0;
                @(intf_master.icb_cmd_valid & intf_master.icb_cmd_ready) ;
                @(posedge intf_master.clk) ;
                intf_master.icb_cmd_valid  <= 1'b0;
                intf_master.icb_rsp_ready  <= 1'b1;
            end
        endtask

        // read reg
        // not needed
    endclass
endpackage: driver_pkg