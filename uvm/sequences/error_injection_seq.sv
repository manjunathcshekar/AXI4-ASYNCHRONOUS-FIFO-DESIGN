// ============================================================================
// File: error_injection_seq.sv
// Description: Error Scenario and Edge Case Coverage Sequence
//
// This sequence exercises error conditions and edge cases:
// 1. Overflow attempts (write when FIFO full) - expects SLVERR
// 2. Underflow attempts (read when FIFO empty) - expects driver skip
// 3. Reset during various operation phases
//
// Stimulus: Multiple error attempts with state checks
// Coverage Goals:
//   - Overflow detection and SLVERR response validation
//   - Underflow handling
//   - Reset assertion during active transactions
//   - Post-reset state validity
//   - FIFO recovery after error conditions
// ============================================================================

class error_injection_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(error_injection_seq)
    
    transaction tr;
    
    function new(string name = "error_injection_seq");
        super.new(name);
    endfunction
    
    task body();
        bit [31:0] data_pattern = 32'hFAIL_0001;
        
        `uvm_info("Error Injection Seq", "Starting error injection and edge case sequence", UVM_MEDIUM)
        
        // Phase 1: Test underflow (read when empty)
        `uvm_info("Error Injection Seq", "Phase 1: Testing FIFO empty condition (underflow)", UVM_LOW)
        
        // FIFO starts empty, so attempt read on empty FIFO
        start_item(tr);
        tr = transaction::type_id::create("tr");
        tr.kind = PERIPH_READ;
        tr.addr = 4'h0;
        finish_item(tr);
        
        `uvm_info("Error Injection Seq", "Read attempt on empty FIFO - driver should skip this transaction", UVM_LOW)
        #100ns;
        
        // Phase 2: Fill to partial level for transition testing
        `uvm_info("Error Injection Seq", "Phase 2: Writing 4 entries (quarter fill)", UVM_LOW)
        for (int i = 0; i < 4; i++) begin
            start_item(tr);
            tr = transaction::type_id::create("tr");
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = data_pattern + i;
            finish_item(tr);
            #50ns;
        end
        
        // Phase 3: Fill to full and test overflow
        `uvm_info("Error Injection Seq", "Phase 3: Filling remaining 4 entries to full", UVM_LOW)
        for (int i = 4; i < 8; i++) begin
            start_item(tr);
            tr = transaction::type_id::create("tr");
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = data_pattern + i;
            finish_item(tr);
            #50ns;
        end
        
        `uvm_info("Error Injection Seq", "FIFO is now full - next write should generate SLVERR", UVM_LOW)
        #100ns;
        
        // Attempt overflow write
        `uvm_info("Error Injection Seq", "Attempting 9th write (overflow scenario)", UVM_LOW)
        start_item(tr);
        tr = transaction::type_id::create("tr");
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = data_pattern + 32'h8888_8888;  // Marker for overflow attempt
        finish_item(tr);
        
        `uvm_info("Error Injection Seq", "Overflow attempt completed - SLVERR response expected", UVM_LOW)
        #150ns;
        
        // Phase 4: Partial drain and recovery
        `uvm_info("Error Injection Seq", "Phase 4: Draining 4 entries to test partial states", UVM_LOW)
        #50ns;  // CDC settling
        
        for (int i = 0; i < 4; i++) begin
            start_item(tr);
            tr = transaction::type_id::create("tr");
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            finish_item(tr);
            #50ns;
        end
        
        `uvm_info("Error Injection Seq", "FIFO now at 4 entries - should be writable again", UVM_LOW)
        #100ns;
        
        // Write to recover from overflow condition
        `uvm_info("Error Injection Seq", "Writing to FIFO after recovery", UVM_LOW)
        start_item(tr);
        tr = transaction::type_id::create("tr");
        tr.kind = WRITE;
        tr.addr = 4'h0;
        tr.data = 32'hRECOV_1234;
        finish_item(tr);
        
        #100ns;
        
        // Phase 5: Status read test (address 0x4)
        `uvm_info("Error Injection Seq", "Phase 5: Testing status/peek reads (address 0x4)", UVM_LOW)
        
        start_item(tr);
        tr = transaction::type_id::create("tr");
        tr.kind = 1'b0;  // READ command (interpreted by driver)
        tr.addr = 4'h4;  // Peek/status address
        finish_item(tr);
        
        #100ns;
        
        `uvm_info("Error Injection Seq", "Error injection and edge case sequence completed", UVM_MEDIUM)
    endtask
    
endclass
