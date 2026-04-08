// Alternating Pattern Sequence with Variable Timing
// Tests state machine transitions by varying operation timing
// Targets: FIFO State Machine (92%), Error Scenarios (75%)

class alternating_pattern_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(alternating_pattern_seq)

    transaction tr;
    int num_pairs = 32;

    function new(string name = "alternating_pattern_seq");
        super.new(name);
        `uvm_info("Alternating Pattern Sequence", "Constructed alternating_pattern_seq", UVM_HIGH)
    endfunction

    function void set_num_pairs(int n);
        num_pairs = n;
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        `uvm_info("ALT_PATTERN", "Phase 1: Tight write-read pairs (tests FIFO transitions)", UVM_MEDIUM)
        // Phase 1: Tight coupling - write immediately followed by read
        for (int i = 0; i < num_pairs; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hA05A_0000 + i;
            finish_item(tr);
            #2ns;  // Very tight coupling

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #2ns;
        end

        #100ns;  // Clear pipeline

        `uvm_info("ALT_PATTERN", "Phase 2: Loose write-read pairs (tests empty/full flags)", UVM_MEDIUM)
        // Phase 2: Loose coupling - write then long gap before read
        for (int i = 0; i < (num_pairs/2); i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h10A5_0000 + i;
            finish_item(tr);
            #50ns;  // Large gap - tests full flag behavior

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #50ns;
        end

        #100ns;

        `uvm_info("ALT_PATTERN", "Phase 3: Read-dominant pattern (tests empty flag)", UVM_MEDIUM)
        // Phase 3: Read-dominant pattern
        for (int i = 0; i < num_pairs; i++) begin
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #6ns;

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #6ns;

            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h0DAD_0000 + i;
            finish_item(tr);
            #6ns;
        end

        #100ns;

        `uvm_info("ALT_PATTERN", "Phase 4: Random delay pattern (stresses CDC synchronizers)", UVM_MEDIUM)
        // Phase 4: Variable delay pattern
        for (int i = 0; i < (num_pairs/2); i++) begin
            int delay;
            
            if (i % 4 == 0)      delay = 3;   // Very tight
            else if (i % 4 == 1) delay = 15;  // Medium
            else if (i % 4 == 2) delay = 40;  // Loose
            else                 delay = 60;  // Very loose

            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hBAAD_0000 + i;
            finish_item(tr);
            #(delay);

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #(delay);
        end

        `uvm_info("ALT_PATTERN", "Alternating pattern test completed", UVM_MEDIUM)
    endtask

endclass
