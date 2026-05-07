class full_write_full_read_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(full_write_full_read_seq)

    transaction tr;
    int fifo_depth = 8;

    function new(string name = "full_write_full_read_seq");
        super.new(name);
        `uvm_info("FWFR Sequence", "Constructed full_write_full_read_seq", UVM_HIGH)
    endfunction

    task body();
        uvm_event ev_write_done;
        uvm_event ev_read_done;

        ev_write_done = uvm_event_pool::get_global("FWFR_WRITE_DONE");
        ev_read_done  = uvm_event_pool::get_global("FWFR_READ_DONE");

        tr = transaction::type_id::create("tr");

        // Write until FIFO reaches full (bounded by fifo_depth)
        for (int i = 0; i < fifo_depth; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hF00D_0000 + i;
            finish_item(tr);
            #50ns;
        end

        ev_write_done.trigger();

        // Read until FIFO becomes empty (bounded by fifo_depth)
        for (int i = 0; i < fifo_depth; i++) begin
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #50ns;
        end

        ev_read_done.trigger();
    endtask

endclass

