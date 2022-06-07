package monitor_pkg;

    import generator_pkg :: convdata;
    import refmodel_pkg :: output_data;

    class monitor;
        string name;

        function new(string name = "monitor");
            this.name = name;
        endfunction
    endclass: monitor

endpackage: monitor_pkg