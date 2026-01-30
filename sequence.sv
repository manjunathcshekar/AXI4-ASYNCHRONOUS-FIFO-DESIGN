class dummy_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(dummy_seq)

    transaction tr;
    int no_of_tr;

    function new(string name = "dummy_sequence");
        super.new(name);
        `uvm_info("Dummy sequence", "Constructed dummy_seq", UVM_HIGH)
    endfunction

    // using a setter funciton to set no_of_tr dynamically from uvm_test. Can be replaced uvm_config_db as well.
    function void set_no_of_tr(int no_of_tr);
        this.no_of_tr = no_of_tr;
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        if (no_of_tr == 0)
            no_of_tr = 4; // default pattern: 2 writes + 2 periph reads

        // first write
        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'hDEAD_BEEF;
        finish_item(tr);

        // second write
        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'hFEED_CAFE;
        finish_item(tr);

        // peripheral read #1
        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);

        // peripheral read #2
        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);
    endtask

endclass
