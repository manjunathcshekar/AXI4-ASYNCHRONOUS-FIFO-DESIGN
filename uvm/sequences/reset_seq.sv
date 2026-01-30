class reset_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(reset_seq)

    transaction tr;

    function new(string name = "reset_seq");
        super.new(name);
        `uvm_info("Reset Sequence", "Constructed reset_seq", UVM_HIGH)
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        // Write a few transactions to create active traffic
        for (int i = 0; i < 3; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h1111_1111 + i;
            finish_item(tr);
            #50ns;
        end

        // Note: Actual reset application is handled by testbench/DUT
        // This sequence just creates traffic that will be interrupted by reset
        // The test will coordinate reset timing

        `uvm_info("Reset Sequence", "Reset sequence completed (traffic generated)", UVM_MEDIUM)
    endtask

endclass

