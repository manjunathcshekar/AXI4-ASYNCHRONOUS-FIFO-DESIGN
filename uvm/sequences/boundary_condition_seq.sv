// Boundary Condition Sequence
// Tests edge cases and corner scenarios
// Targets: Error Scenarios (75%), AXI Protocol (85%), FIFO State Machine (92%)

class boundary_condition_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(boundary_condition_seq)

    transaction tr;
    int stress_count = 20;

    function new(string name = "boundary_condition_seq");
        super.new(name);
        `uvm_info("Boundary Condition Sequence", "Constructed boundary_condition_seq", UVM_HIGH)
    endfunction

    function void set_stress_count(int n);
        stress_count = n;
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        `uvm_info("BOUNDARY", "Scenario 1: Single write followed by multiple reads", UVM_MEDIUM)
        // Only one write, then many reads - tests if FIFO properly empties
        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'hA1BC_DEFB;
        finish_item(tr);
        #20ns;

        for (int i = 0; i < 5; i++) begin
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #10ns;
        end

        #100ns;

        `uvm_info("BOUNDARY", "Scenario 2: Many writes followed by single read", UVM_MEDIUM)
        // Multiple writes then only one read - tests if FIFO holds data
        for (int i = 0; i < 5; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hFEDC_0000 + i;
            finish_item(tr);
            #10ns;
        end
        #20ns;

        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);

        #100ns;

        `uvm_info("BOUNDARY", "Scenario 3: Address switching with interleaved operations", UVM_MEDIUM)
        // Tests if address switching affects FIFO behavior
        for (int i = 0; i < stress_count; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = (i % 2) ? 4'h4 : 4'h0;
            tr.data = 32'h1ADD_0000 + i;
            finish_item(tr);
            #12ns;

            if (i % 3 == 0) begin
                start_item(tr);
                tr.kind = PERIPH_READ;
                tr.addr = 4'h0;
                tr.data = 32'h0;
                finish_item(tr);
                #12ns;
            end
        end

        #100ns;

        `uvm_info("BOUNDARY", "Scenario 4: Back-to-back operations (timing stress)", UVM_MEDIUM)
        // Minimal delay between operations
        for (int i = 0; i < stress_count; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hBABE_0000 + i;
            finish_item(tr);
            #1ns;  // Minimal delay - stress CDC synchronizers

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #1ns;
        end

        #100ns;

        `uvm_info("BOUNDARY", "Scenario 5: Large data value stress", UVM_MEDIUM)
        // Tests with extreme data values
        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'hFFFF_FFFF;  // All ones
        finish_item(tr);
        #20ns;

        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);
        #20ns;

        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'h0000_0000;  // All zeros
        finish_item(tr);
        #20ns;

        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);
        #20ns;

        start_item(tr);
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'h5555_AAAA;  // Alternating bits
        finish_item(tr);
        #20ns;

        start_item(tr);
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        tr.data = 32'h0;
        finish_item(tr);

        `uvm_info("BOUNDARY", "Boundary condition test completed", UVM_MEDIUM)
    endtask

endclass
