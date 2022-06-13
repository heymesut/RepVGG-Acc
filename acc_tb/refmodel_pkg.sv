package refmodel_pkg;

    import generator_pkg :: convdata;
    
    class output_data;
        logic signed [7:0] data;
    endclass

    class refmodel;
        string name;
        mailbox #(convdata) gen2ref;
        mailbox #(output_data) ref2scb;
        convdata conv_data;

        logic signed [7:0] weight [63:0][63:0][2:0][2:0];
        logic signed [7:0] imap [63:0][57:0][57:0];
        int w_och_cnt;
        int w_ich_cnt;
        int w_c;
        int w_r;
        int weight_cnt;
        int imap_col_cnt;
        int imap_row_cnt;
        int imap_ch_cnt;
        logic signed [7:0] omap [63:0][56:1][56:1];
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
                            weight[och][ich][r][c] = 0;
                        end
                    end
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
                        omap[och][row][col] = 0;
                    end
                end
            end
        endtask

        task get_data();
            while(gen2ref.try_peek(conv_data)) begin
                gen2ref.get(conv_data);
                if(conv_data.data_type == 0) begin
                    weight[w_och_cnt][w_ich_cnt][w_r][w_c] = conv_data.data;
                    w_c ++;
                    if(w_c == 3) begin
                        w_c = 0;
                        w_r ++;
                    end
                    if(w_r == 3) begin
                        w_r = 0;
                        w_ich_cnt ++;
                    end
                    if(w_ich_cnt == 64) begin
                        w_ich_cnt = 0;
                        w_och_cnt ++;
                    end
                    if(w_och_cnt == 64) begin
                        w_och_cnt = 0;
                    end
                end
                else begin
                    imap[imap_ch_cnt][imap_row_cnt][imap_col_cnt] = conv_data.data;
                    imap_ch_cnt ++;
                    if(imap_ch_cnt == 64) begin
                        imap_ch_cnt = 0;
                        imap_col_cnt ++;
                    end
                    if(imap_col_cnt == 56) begin
                        imap_col_cnt = 0;
                        imap_row_cnt ++;
                    end
                    if(imap_row_cnt == 56) begin
                        imap_row_cnt = 0;
                    end
                end
            end
        endtask

        task mac();
            for(int och=0;och<64;och++) begin
                for(int row=1;row<57;row++) begin
                    for(int col=1;col<57;col++) begin
                        for(int ich=0;ich<64;ich++) begin
                            omap[och][row][col] = omap[och][row][col] + weight[och][ich][0][0] * imap[ich][row-1][col-1] + weight[och][ich][0][1] * imap[ich][row-1][col] + weight[och][ich][0][2] * imap[ich][row-1][col+1] + weight[och][ich][1][0] * imap[ich][row][col-1] + weight[och][ich][1][1] * imap[ich][row][col] + weight[och][ich][1][2] * imap[ich][row][col+1] + weight[och][ich][2][0] * imap[ich][row+1][col-1] + weight[och][ich][2][1] * imap[ich][row+1][col] + weight[och][ich][2][2] * imap[ich][row+1][col+1]; 
                        end
                    end
                end
            end
        endtask

        task send_output();
            for(int och=0;och<64;och++) begin
                for(int row=1;row<57;row++) begin
                    for(int col=1;col<57;col++) begin
                        out = new();
                        out.data = omap[och][row][col];
                        ref2scb.put(out);
                    end
                end
            end
        endtask

        task run();
            get_data();
            mac();
            send_output();
        endtask

    endclass: refmodel

endpackage: refmodel_pkg