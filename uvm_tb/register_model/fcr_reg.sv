package fcr_reg;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class fcr_reg extends uvm_reg;
        rand uvm_reg_field rx_fifo;
        rand uvm_reg_field tx_fifo;
        rand uvm_reg_field threshold_fifo;

        virtual function void build();
            rx_fifo = uvm_reg_field::type_id::create("rx_fifo");
            rx_fifo.configure(this, 1, 1, "WO", 0, 1'b0, 1, 0, 0);

            tx_fifo = uvm_reg_field::type_id::create("tx_fifo");
            tx_fifo.configure(this, 1, 2, "WO", 0, 1'b0, 1, 0, 0);

            threshold_fifo = uvm_reg_field::type_id::create("threshold");
            threshold_fifo.configure(this, 2, 6, "WO", 0, 'b0, 1, 1, 0);
        endfunction

        function new(input string name = "fcr_reg");
            super.new(name, 32, UVM_NO_COVERAGE);
        endfunction

    endclass

    class reg_model extends uvm_reg_block;
        
        rand fcr_reg fcr;

        function new(input string name = "reg_model");
            super.new(name, UVM_NO_COVERAGE);
        endfunction //new()

        virtual function void build();
            default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN, 0);
            fcr = fcr_reg::type_id::create("fcr", get_full_name());
            fcr.configure(this, null, "");
            fcr.build();
            default_map.add_reg(fcr, 'h8, "RW");
        endfunction

        `uvm_object_utils(reg_model)

    endclass //reg_block extends uvm_reg_block
endpackage