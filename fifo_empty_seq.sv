class fifo_empty_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(fifo_empty_seq)

    transaction tr;

    function new(string name = "fifo_empty_seq");
        super.new(name);
        `uvm_info("FIFO Empty Sequence", "Constructed fifo_empty_seq", UVM_HIGH)
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        // Attempt to read when FIFO is empty
        // This is a NEGATIVE/STATUS check: read must be BLOCKED when FIFO is empty.
        // The driver will *not* wait forever; it will skip issuing rd_en if rd_empty is asserted.
        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);

        // Write one item to FIFO
        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'hBEEFCAFE;
        finish_item(tr);

        #100ns;

        // Now read should succeed
        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);

        `uvm_info("FIFO Empty Sequence", "FIFO empty sequence completed", UVM_MEDIUM)
    endtask

endclass

