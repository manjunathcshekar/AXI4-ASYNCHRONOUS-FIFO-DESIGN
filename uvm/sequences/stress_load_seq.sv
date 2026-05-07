// Stress Load Sequence
// High-volume transaction testing with specific patterns
// Targets: All covergroups with transaction volume and state coverage

class stress_load_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(stress_load_seq)

    transaction tr;
    int num_transactions = 500;  // Very high volume

    function new(string name = "stress_load_seq");
        super.new(name);
        `uvm_info("Stress Load Sequence", "Constructed stress_load_seq", UVM_HIGH)
    endfunction

    function void set_num_transactions(int n);
        num_transactions = n;
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        `uvm_info("STRESS_LOAD", "Phase 1: High-speed write burst", UVM_MEDIUM)
        for (int i = 0; i < num_transactions/2; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = (i % 2) ? 4'h4 : 4'h0;
            tr.data = 32'h5555_0000 + (i % 256);
            finish_item(tr);
            #2ns;  // Minimal delay - extreme stress
        end

        #200ns;

        `uvm_info("STRESS_LOAD", "Phase 2: High-speed read burst", UVM_MEDIUM)
        for (int i = 0; i < num_transactions/2; i++) begin
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #2ns;
        end

        #200ns;

        `uvm_info("STRESS_LOAD", "Phase 3: Interleaved write/read stress", UVM_MEDIUM)
        for (int i = 0; i < num_transactions/4; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hAAAA_0000 + (i % 128);
            finish_item(tr);
            #3ns;

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #3ns;
        end

        `uvm_info("STRESS_LOAD", "Stress load test completed", UVM_MEDIUM)
    endtask

endclass
