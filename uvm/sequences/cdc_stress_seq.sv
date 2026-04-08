// CDC (Clock Domain Crossing) Stress Test Sequence
// Tests Gray code synchronization and metastability scenarios
// Targets: CDC Synchronization coverage (currently 78%)

class cdc_stress_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(cdc_stress_seq)

    transaction tr;
    int num_cycles = 100;  // Number of CDC cycles to exercise

    function new(string name = "cdc_stress_seq");
        super.new(name);
        `uvm_info("CDC Stress Sequence", "Constructed cdc_stress_seq", UVM_HIGH)
    endfunction

    function void set_num_cycles(int n);
        num_cycles = n;
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        // Phase 1: Rapid writes to test write-side pointer synchronization
        `uvm_info("CDC_STRESS", "Starting rapid write phase (CDC write-side)", UVM_MEDIUM)
        for (int i = 0; i < num_cycles/2; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hAAAA_0000 + i;
            finish_item(tr);
            #5ns;  // Tight spacing to stress CDC synchronizers
        end

        // Phase 2: Wait for read clock domain to synchronize
        #100ns;

        // Phase 3: Rapid reads to test read-side pointer synchronization
        `uvm_info("CDC_STRESS", "Starting rapid read phase (CDC read-side)", UVM_MEDIUM)
        for (int i = 0; i < num_cycles/2; i++) begin
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #5ns;
        end

        // Phase 4: Interleaved mixed operations to test both pointers simultaneously
        `uvm_info("CDC_STRESS", "Starting mixed read/write phase", UVM_MEDIUM)
        for (int i = 0; i < (num_cycles/4); i++) begin
            // Write
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hBBBB_0000 + i;
            finish_item(tr);
            #10ns;

            // Read
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #10ns;
        end

        `uvm_info("CDC_STRESS", "CDC stress test completed", UVM_MEDIUM)
    endtask

endclass
