// ============================================================================
// File: cdc_wraparound_seq.sv
// Description: CDC and Pointer Wraparound Coverage Sequence
//
// This sequence exercises Gray code pointer transitions and wraparound
// conditions by performing multiple FIFO fill/drain cycles. The goal is to
// exercise all Gray code bit transitions and capture wraparound events at
// FIFO boundaries (0, 4, 8).
//
// Stimulus: 24 write/read pairs (3 complete cycles through 8-entry FIFO)
// Coverage Goals:
//   - All Gray code bit transitions (all 4 bits for write and read pointers)
//   - Pointer wraparound at boundaries (0, 4, 8)
//   - CDC synchronization delays
// ============================================================================

class cdc_wraparound_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(cdc_wraparound_seq)
    
    transaction tr;
    
    function new(string name = "cdc_wraparound_seq");
        super.new(name);
    endfunction
    
    task body();
        bit [31:0] data_pattern = 32'hDEAD_BEEF;
        
        `uvm_info("CDC Wraparound Seq", "Starting CDC wraparound sequence (3 FIFO cycles)", UVM_MEDIUM)
        
        // Perform 3 complete FIFO cycles (24 transactions total)
        for (int cycle = 0; cycle < 3; cycle++) begin
            // Fill phase: Write 8 entries
            for (int i = 0; i < 8; i++) begin
                tr = transaction::type_id::create("tr");
                start_item(tr);
                tr.kind = WRITE;
                tr.addr = 4'h0;
                tr.data = data_pattern + (cycle * 8) + i;
                finish_item(tr);
                #20ns;  // Small delay between writes to observe Gray transitions
            end
            
            `uvm_info("CDC Wraparound Seq", $sformatf("Cycle %0d: FIFO full, starting drain phase", cycle), UVM_LOW)
            
            // Drain phase: Read 8 entries  
            // Delay to allow CDC settling between write and read domains
            #100ns;
            
            for (int i = 0; i < 8; i++) begin
                tr = transaction::type_id::create("tr");
                start_item(tr);
                tr.kind = PERIPH_READ;
                tr.addr = 4'h0;
                finish_item(tr);
                #20ns;  // Small delay between reads
            end
            
            `uvm_info("CDC Wraparound Seq", $sformatf("Cycle %0d: FIFO empty, restarting", cycle), UVM_LOW)
            
            // Delay between cycles to allow full CDC settling
            #100ns;
        end
        
        `uvm_info("CDC Wraparound Seq", "CDC wraparound sequence completed - all pointer bits should have transitioned", UVM_MEDIUM)
    endtask
    
endclass
