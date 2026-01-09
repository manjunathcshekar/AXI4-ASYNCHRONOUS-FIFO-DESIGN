class fifo_full_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(fifo_full_seq)

    transaction tr;
    int fifo_depth = 8;  // FIFO depth from DUT parameter

    function new(string name = "fifo_full_seq");
        super.new(name);
        `uvm_info("FIFO Full Sequence", "Constructed fifo_full_seq", UVM_HIGH)
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        // Fill FIFO completely (8 writes for depth=8)
        for (int i = 0; i < fifo_depth; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h1000 + i;  // Unique data for each write
            finish_item(tr);
            #50ns;  // Small delay between writes
        end

        // Attempt one extra write when FIFO should be full
        // This should result in SLVERR response (handled by driver/monitor)
        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'hDEADBEEF;  // Extra write data
        finish_item(tr);

        `uvm_info("FIFO Full Sequence", $sformatf("FIFO full sequence completed: %0d writes + 1 overflow", fifo_depth), UVM_MEDIUM)
    endtask

endclass

