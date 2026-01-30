class basic_rw_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(basic_rw_seq)

    transaction tr;

    function new(string name = "basic_rw_seq");
        super.new(name);
        `uvm_info("Basic RW Sequence", "Constructed basic_rw_seq", UVM_HIGH)
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        // Write transaction: write data to FIFO
        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'hA5A5A5A5;
        finish_item(tr);

        // Small delay to allow write to complete
        #100ns;

        // Read transaction: read from FIFO via peripheral interface
        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);

        `uvm_info("Basic RW Sequence", "Basic read-write sequence completed", UVM_MEDIUM)
    endtask

endclass

