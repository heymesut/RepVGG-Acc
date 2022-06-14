package env_pkg;

    import generator_pkg :: * ;
    import driver_pkg :: * ;
    import refmodel_pkg :: * ;
    import scoreboard_pkg :: * ;
    import monitor_pkg :: * ;

    class env_agent;
        string name;
        convdata_generator gen;
        icb_driver drv;
        refmodel refm;
        scoreboard scb;
        monitor mon;
        mailbox #(convdata) gen2drv;
        mailbox #(convdata) gen2ref;
        mailbox #(output_data) ref2scb;
        mailbox #(output_data) mon2scb;
        event e_check;

        function new(string name = "env_agent");
            this.name = name;
            this.gen2drv = new();
            this.gen2ref = new();
            this.ref2scb = new();
            this.mon2scb = new();
            this.gen  = new("generator", gen2drv, gen2ref);
            this.drv  = new("driver", gen2drv);
            this.refm = new("refmodel", gen2ref, ref2scb);
            this.scb  = new("scoreboard", ref2scb, mon2scb, e_check);
            this.mon  = new("monitor", mon2scb, e_check);
        endfunction

        function void set_interface(virtual icb_intf intf_master, virtual icb_intf intf_slave);
            drv.set_interface(intf_master, intf_slave);
            mon.set_interface(intf_master);
        endfunction

        task run();
            $display("driver initialization");
            drv.initial_data();
            $display("start running");
            fork
                gen.gen_convdata();
                drv.run();
                refm.run();
                mon.run();
                scb.run();
            join_any
        endtask

        task report();
            scb.report();
        endtask
    endclass: env_agent

    class env_test;

        string name;
        env_agent agent;

        function new(string name="env_test");
            this.name = name;
            this.agent = new("env_agent");
        endfunction

        function set_interface(virtual icb_intf intf_master, virtual icb_intf intf_slave);
            agent.set_interface(intf_master, intf_slave);
        endfunction

        task run();
            agent.run();
        endtask

        task report();
            agent.report();
        endtask
    endclass: env_test
endpackage: env_pkg