package scoreboard_pkg;

    import refmodel_pkg :: output_data;

    class scoreboard;
        string name;
        mailbox #(output_data) ref2scb;
        mailbox #(output_data) mon2scb;
        int success_cnt;
        int failure_cnt;
        output_data refout;
        output_data monout;
        event e_check;

        function new(string name, mailbox #(output_data) ref2scb, mailbox #(output_data) mon2scb, event e_check);
            this.name = name;
            this.ref2scb = ref2scb;
            this.mon2scb = mon2scb;
            this.success_cnt = 0;
            this.failure_cnt = 0;
            this.e_check = e_check;
        endfunction

        task run();
            forever begin
                @e_check;
                if(ref2scb.num()>0 & mon2scb.num()>0) begin
                    $display("scoreboard comparing");
                    ref2scb.get(refout);
                    mon2scb.get(monout);
                    if(refout.data == monout.data) begin
                        success_cnt = success_cnt + 1;
                    end
                    else begin
                        failure_cnt = failure_cnt + 1;
                        $display("Scoreboard : failed! at %t", $time);
                        $display("Scoreboard receive %b from refmodel", refout.data);
                        $display("Scoreboard receive %b from monitor", monout.data);
                    end
                end
                else if(ref2scb.num()==0 & mon2scb.num()==0) begin
                    break;
                end
            end
            report();
        endtask

        task report();  // report check result
            $display("the success rate is %d", 100*success_cnt/(success_cnt+failure_cnt));
            $display("success number is %d", success_cnt);
            $display("failure number is %d", failure_cnt);
        endtask
    endclass: scoreboard

endpackage: scoreboard_pkg