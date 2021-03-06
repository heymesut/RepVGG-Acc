package refmodel_pkg;

    import generator_pkg :: convdata;
    
    class output_data;
        logic [31:0] data;
    endclass

    class refmodel;
        string name;
        mailbox #(convdata) gen2ref;
        mailbox #(output_data) ref2scb;
        convdata conv_data;

        logic signed [7:0] weight3 [63:0][63:0][2:0][2:0];
        logic signed [7:0] weight1 [63:0][63:0];
        logic signed [7:0] imap [63:0][57:0][57:0];
        int w_och_cnt;
        int w_ich_cnt;
        int w_c;
        int w_r;
        int weight_cnt;
        int imap_col_cnt;
        int imap_row_cnt;
        int imap_ch_cnt;
        logic signed [31:0] omap3 [63:0][56:1][56:1];
        logic signed [31:0] omap1 [63:0][56:1][56:1];
        logic signed [31:0] outmap [63:0][56:1][56:1];
        output_data out;

        function new(string name="refmodel", mailbox #(convdata) gen2ref, mailbox #(output_data) ref2scb);
            this.name = name;
            this.gen2ref = gen2ref;
            this.ref2scb = ref2scb;
            this.w_och_cnt = 0;
            this.w_ich_cnt = 0;
            this.w_c = 0;
            this.w_r = 0;
            this.imap_col_cnt = 1;
            this.imap_row_cnt = 1;
            this.imap_ch_cnt = 0;
            initial_data();
        endfunction

        task initial_data();
            for(int och=0;och<64;och++) begin
                for(int ich=0;ich<64;ich++) begin
                    for(int r=0;r<3;r++) begin
                        for(int c=0;c<3;c++) begin
                            weight3[och][ich][r][c] = 0;
                        end
                    end
                end
            end
            for(int och=0;och<64;och++) begin
                for(int ich=0;ich<64;ich++) begin
                    weight1[och][ich] = 0;
                end
            end
            for(int ich=0;ich<64;ich++) begin
                for(int row=0;row<58;row++) begin
                    for(int col=0;col<58;col++) begin
                        imap[ich][row][col] = 0;
                    end
                end
            end
            for(int och=0;och<64;och++) begin
                for(int row=1;row<57;row++) begin
                    for(int col=1;col<57;col++) begin
                        omap3[och][row][col] = 0;
                        omap1[och][row][col] = 0;
                        outmap[och][row][col] = 0;
                    end
                end
            end
        endtask

        task get_data();
            while(gen2ref.try_peek(conv_data)) begin
                gen2ref.get(conv_data);
                if(conv_data.data_type == 0) begin
                    if(weight_cnt < 36864) begin
                        weight3[w_och_cnt][w_ich_cnt][w_r][w_c] = conv_data.data;
                        w_c ++;
                        weight_cnt ++;
                        if(w_c == 3) begin
                            w_c = 0;
                            w_r ++;
                            if(w_r == 3) begin
                                w_r = 0;
                                w_ich_cnt ++;
                                if(w_ich_cnt == 64) begin
                                    w_ich_cnt = 0;
                                    w_och_cnt ++;
                                    if(w_och_cnt == 64) begin
                                        w_och_cnt = 0;
                                    end
                                end
                            end
                        end
                    end
                    else begin
                        weight1[w_och_cnt][w_ich_cnt] = conv_data.data;
                        w_ich_cnt ++;
                        if(w_ich_cnt == 64) begin
                            w_ich_cnt = 0;
                            w_och_cnt ++;
                            if(w_och_cnt == 64) begin
                                w_och_cnt = 0;
                            end
                        end
                    end
                end
                else begin
                    imap[imap_ch_cnt][imap_row_cnt][imap_col_cnt] = conv_data.data;
                    imap_ch_cnt ++;
                    if(imap_ch_cnt == 64) begin
                        imap_ch_cnt = 0;
                        imap_col_cnt ++;
                        if(imap_col_cnt == 57) begin
                            imap_col_cnt = 1;
                            imap_row_cnt ++;
                            if(imap_row_cnt == 57) begin
                                imap_row_cnt = 1;
                            end
                        end
                    end
                end
            end
        endtask

        task mac();
            for(int och=0;och<64;och++) begin
                for(int row=1;row<57;row++) begin
                    for(int col=1;col<57;col++) begin
                        for(int ich=0;ich<64;ich++) begin
                            omap3[och][row][col] = omap3[och][row][col] + weight3[och][ich][0][0] * imap[ich][row-1][col-1] + weight3[och][ich][0][1] * imap[ich][row-1][col] + weight3[och][ich][0][2] * imap[ich][row-1][col+1] + weight3[och][ich][1][0] * imap[ich][row][col-1] + weight3[och][ich][1][1] * imap[ich][row][col] + weight3[och][ich][1][2] * imap[ich][row][col+1] + weight3[och][ich][2][0] * imap[ich][row+1][col-1] + weight3[och][ich][2][1] * imap[ich][row+1][col] + weight3[och][ich][2][2] * imap[ich][row+1][col+1]; 
                        end
                    end
                end
            end
            for(int och=0;och<64;och++) begin
                for(int row=1;row<57;row++) begin
                    for(int col=1;col<57;col++) begin
                        for(int ich=0;ich<64;ich++) begin
                            omap1[och][row][col] = omap1[och][row][col] + weight1[och][ich] * imap[ich][row+1][col+1];
                        end
                    end
                end
            end
            for(int och=0;och<64;och++) begin
                for(int row=1;row<57;row++) begin
                    for(int col=1;col<57;col++) begin
                        outmap[och][row][col] = imap[och][row][col] + omap1[och][row][col] + omap3[och][row][col];
                    end
                end
            end
        endtask

        task send_output();
            for(int och=0;och<64;och++) begin
                for(int row=1;row<57;row++) begin
                    for(int col=1;col<57;col++) begin
                        out = new();
                        out.data[31:24] = 8'b0000_0000;
                        out.data[23:16] = outmap[och][row][col][24:17];
                        out.data[15:8]  = omap3[och][row][col][24:17];
                        out.data[7:0]   = omap1[och][row][col][21:14];
                        ref2scb.put(out);
                    end
                end
            end
        endtask

        task run();
            $display("start getting data");
            get_data();
            $display("perform mac");
            // $display("weight3 0 is %b", weight3[0][0][0][0]);
            // $display("weight1 0 is %b", weight1[0][0]);
            // $display("input 0 is %b", imap[0][1][1]);
            mac();
            $display("send output");
            send_output();
            $display("refmodel finished");
        endtask

    endclass: refmodel

endpackage: refmodel_pkg