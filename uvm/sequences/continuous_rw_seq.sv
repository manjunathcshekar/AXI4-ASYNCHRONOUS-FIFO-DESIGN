class continuous_rw_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(continuous_rw_seq)

    transaction tr;
    int num_iters = 50;

    function new(string name = "continuous_rw_seq");
        super.new(name);
        `uvm_info("Continuous RW Sequence", "Constructed continuous_rw_seq", UVM_HIGH)
    endfunction

    function void set_num_iters(int n);
        num_iters = n;
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        // Interleaved continuous write/read pattern (stable, scoreboard-friendly)
        for (int i = 0; i < num_iters; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hC0DE_0000 + i;
            finish_item(tr);

            #20ns;

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);

            #20ns;
        end
    endtask

endclass

