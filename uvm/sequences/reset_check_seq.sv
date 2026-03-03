class reset_check_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(reset_check_seq)

    transaction tr;

    function new(string name = "reset_check_seq");
        super.new(name);
        `uvm_info("Reset Check Sequence", "Constructed reset_check_seq", UVM_HIGH)
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        // Attempt a read immediately after reset.
        // If FIFO is not empty due to bad reset, this read may succeed and scoreboard will flag mismatch.
        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);

        // Write then read one item after reset (expected must be preloaded by test)
        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'hCAFE_BABE;
        finish_item(tr);

        #100ns;

        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);
    endtask

endclass

