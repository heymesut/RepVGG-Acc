package generator_pkg;

    // data used in conv, including weights and input
    class convdata;
        rand logic signed [7:0] data;
        // data_type = 0 for weights / 1 for input
        int data_type;
    endclass: convdata

    class convdata_generator;
        string name;
        mailbox #(convdata) gen2drv;
        mailbox #(convdata) gen2ref;
        convdata conv_data;
        int weight_num = 64*64*10;
        int imap_num = 56*56*64;

        function new(string name="generator",mailbox #(convdata) gen2drv,mailbox #(convdata) gen2ref);
            this.name = name;
            this.gen2drv = gen2drv;
            this.gen2ref = gen2ref;
        endfunction

        task gen_convdata();
            $display("i am a running generator");
            // generator weights
            for(int i=0;i<weight_num;i++) begin
                conv_data = new();
                conv_data.randomize();
                conv_data.data_type = 0;
                gen2drv.put(conv_data);
                gen2ref.put(conv_data);
            end
            // generator imap
            for(int i=0;i<imap_num;i++) begin
                conv_data = new();
                conv_data.randomize();
                conv_data.data_type = 1;
                gen2drv.put(conv_data);
                gen2ref.put(conv_data);
            end
        endtask
    endclass: convdata_generator

endpackage: generator_pkg