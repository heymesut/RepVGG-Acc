package monitor_pkg;

    import generator_pkg :: convdata;
    import refmodel_pkg :: output_data;

    class monitor;
        string name;
        local virtual icb_intf intf;
        mailbox #(output_data) mon2scb;
        output_data output;

        function new(string name = "monitor", mailbox #(output_data) mon2scb);
            this.name = name;
            this.mon2scb = mon2scb;
        endfunction

        function void set_interface(virtual icb_intf intf);
            if(intf == numm)
                $error("interface handle is NULL");
            else
                this.intf = intf;
        endfunction

        task run();
            forever begin
                @(posedge intf.clk);
                if(intf.icb_cmd_valid & intf.icb_cmd_ready & !intf.read) begin
                    output = new();
                    output.data = intf.icb_cmd_wdata;
                    mon2scb.put(output);
                end
            end
        endtask
    endclass: monitor

endpackage: monitor_pkg