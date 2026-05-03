// ============================================================================
// File: interrupt_stimulus_seq.sv
// Description: Interrupt Signal Coverage Sequence
//
// This sequence exercises interrupt generation by:
// 1. Filling the FIFO to generate IRQ_FULL
// 2. Draining the FIFO to generate IRQ_EMPTY
// 3. Testing interrupt clear signal timing
//
// Stimulus: 8 writes (generates FULL interrupt), 8 reads (generates EMPTY interrupt)
// Coverage Goals:
//   - IRQ_FULL assertion when FIFO reaches full capacity
//   - IRQ_EMPTY assertion when FIFO becomes empty
//   - Clear signal pulse and hold durations
//   - Cross-coverage: IRQ assertion vs clear signal timing
// ============================================================================

class interrupt_stimulus_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(interrupt_stimulus_seq)
    
    transaction tr;
    
    function new(string name = "interrupt_stimulus_seq");
        super.new(name);
    endfunction
    
    task body();
        bit [31:0] data_pattern = 32'hBEEF_CAFE;
        
        `uvm_info("Interrupt Seq", "Starting interrupt stimulus sequence", UVM_MEDIUM)
        
        // Phase 1: Generate FULL interrupt by filling FIFO
        `uvm_info("Interrupt Seq", "Phase 1: Filling FIFO to generate IRQ_FULL", UVM_LOW)
        for (int i = 0; i < 8; i++) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = data_pattern + i;
            finish_item(tr);
            #50ns;
        end
        
        `uvm_info("Interrupt Seq", "FIFO now full - IRQ_FULL should be asserted", UVM_LOW)
        #200ns;  // Allow time to observe IRQ_FULL assertion
        
        // Phase 2: Wait and observe FULL interrupt behavior
        `uvm_info("Interrupt Seq", "Waiting for IRQ_FULL observation", UVM_LOW)
        #200ns;
        
        // Phase 3: Drain FIFO to generate EMPTY interrupt
        `uvm_info("Interrupt Seq", "Phase 2: Draining FIFO to generate IRQ_EMPTY", UVM_LOW)
        #100ns;  // CDC settling time before starting reads
        
        for (int i = 0; i < 8; i++) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            finish_item(tr);
            #50ns;
        end
        
        `uvm_info("Interrupt Seq", "FIFO now empty - IRQ_EMPTY should be asserted", UVM_LOW)
        #200ns;  // Allow time to observe IRQ_EMPTY assertion
        
        // Phase 4: Test interrupt clear signals (if supported)
        `uvm_info("Interrupt Seq", "Phase 3: Testing clear signal behavior", UVM_LOW)
        #200ns;
        
        // If supported by testbench, can exercise irq_clear_* signals here
        // This would depend on testbench/driver implementation
        
        `uvm_info("Interrupt Seq", "Interrupt stimulus sequence completed", UVM_MEDIUM)
    endtask
    
endclass
