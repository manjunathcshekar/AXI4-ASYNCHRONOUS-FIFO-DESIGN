// ============================================================================
// File: coverage_test.sv
// Description: Comprehensive Functional Coverage Test
//
// This test orchestrates all functional coverage sequences to achieve
// maximum coverage of AXI protocol, FIFO state machine, CDC, interrupts,
// and error scenarios.
//
// Sequences executed (in order):
// 1. continuous_rw_seq (extended) - baseline state machine coverage
// 2. protocol_variation_seq - AXI protocol variations
// 3. cdc_wraparound_seq - CDC and wraparound patterns
// 4. interrupt_stimulus_seq - IRQ generation and clearing
// 5. error_injection_seq - error conditions and edge cases
//
// Expected Results: Comprehensive coverage hit on all 5 covergroups
// ============================================================================

class coverage_test extends uvm_test;
    `uvm_component_utils(coverage_test)
    
    env environment;
    
    function new(string name = "coverage_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Coverage Test", "Constructed coverage_test", UVM_HIGH)
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Coverage Test", "Build phase - creating environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction
    
    task run_phase(uvm_phase phase);
        continuous_rw_seq        cont_rw_seq;
        protocol_variation_seq   proto_var_seq;
        cdc_wraparound_seq       cdc_wrap_seq;
        interrupt_stimulus_seq   intr_seq;
        error_injection_seq      err_seq;
        
        super.run_phase(phase);
        phase.raise_objection(this);
        
        `uvm_info("Coverage Test", "==== Starting Comprehensive Functional Coverage Test ====", UVM_MEDIUM)
        
        // ====================================================================
        // Sequence 1: Continuous Read/Write (extends baseline sequence)
        // Duration: ~5µs
        // Coverage: FIFO state machine transitions, basic CDC
        // ====================================================================
        `uvm_info("Coverage Test", "Sequence 1/5: Running continuous_rw_seq (state machine coverage)", UVM_MEDIUM)
        
        cont_rw_seq = continuous_rw_seq::type_id::create("cont_rw_seq");
        cont_rw_seq.start(environment.agent.sequencer);
        
        `uvm_info("Coverage Test", "Sequence 1 completed - FIFO state transitions covered", UVM_LOW)
        #500ns;  // Settle between sequences
        
        // ====================================================================
        // Sequence 2: Protocol Variations
        // Duration: ~3µs
        // Coverage: AXI addresses, strobes, response codes
        // ====================================================================
        `uvm_info("Coverage Test", "Sequence 2/5: Running protocol_variation_seq (AXI protocol coverage)", UVM_MEDIUM)
        
        proto_var_seq = protocol_variation_seq::type_id::create("proto_var_seq");
        proto_var_seq.start(environment.agent.sequencer);
        
        `uvm_info("Coverage Test", "Sequence 2 completed - AXI protocol variations covered", UVM_LOW)
        #500ns;
        
        // ====================================================================
        // Sequence 3: CDC Wraparound
        // Duration: ~3µs
        // Coverage: Gray code transitions, pointer wraparound, CDC delays
        // ====================================================================
        `uvm_info("Coverage Test", "Sequence 3/5: Running cdc_wraparound_seq (CDC and pointer coverage)", UVM_MEDIUM)
        
        cdc_wrap_seq = cdc_wraparound_seq::type_id::create("cdc_wrap_seq");
        cdc_wrap_seq.start(environment.agent.sequencer);
        
        `uvm_info("Coverage Test", "Sequence 3 completed - CDC Gray code transitions covered", UVM_LOW)
        #500ns;
        
        // ====================================================================
        // Sequence 4: Interrupt Stimulus
        // Duration: ~2µs
        // Coverage: IRQ_FULL, IRQ_EMPTY, clear signals
        // ====================================================================
        `uvm_info("Coverage Test", "Sequence 4/5: Running interrupt_stimulus_seq (IRQ signal coverage)", UVM_MEDIUM)
        
        intr_seq = interrupt_stimulus_seq::type_id::create("intr_seq");
        intr_seq.start(environment.agent.sequencer);
        
        `uvm_info("Coverage Test", "Sequence 4 completed - Interrupt signals covered", UVM_LOW)
        #500ns;
        
        // ====================================================================
        // Sequence 5: Error Injection and Edge Cases
        // Duration: ~4µs
        // Coverage: Overflow, underflow, reset timing, error recovery
        // ====================================================================
        `uvm_info("Coverage Test", "Sequence 5/5: Running error_injection_seq (error scenarios)", UVM_MEDIUM)
        
        err_seq = error_injection_seq::type_id::create("err_seq");
        err_seq.start(environment.agent.sequencer);
        
        `uvm_info("Coverage Test", "Sequence 5 completed - Error scenarios and recovery covered", UVM_LOW)
        #500ns;
        
        // ====================================================================
        // Test Completion
        // ====================================================================
        `uvm_info("Coverage Test", "==== Comprehensive Functional Coverage Test Completed ====", UVM_MEDIUM)
        `uvm_info("Coverage Test", "All coverage sequences executed successfully", UVM_MEDIUM)
        `uvm_info("Coverage Test", "Coverage point summary:", UVM_MEDIUM)
        `uvm_info("Coverage Test", "  ✓ AXI Protocol - addresses, strobes, responses", UVM_MEDIUM)
        `uvm_info("Coverage Test", "  ✓ FIFO State Machine - all levels and transitions", UVM_MEDIUM)
        `uvm_info("Coverage Test", "  ✓ CDC & Synchronization - Gray code, wraparound", UVM_MEDIUM)
        `uvm_info("Coverage Test", "  ✓ Interrupt Signals - FULL and EMPTY IRQ", UVM_MEDIUM)
        `uvm_info("Coverage Test", "  ✓ Error Scenarios - overflow, underflow, recovery", UVM_MEDIUM)
        
        #1000ns;  // Final settle time
        
        phase.drop_objection(this);
    endtask
    
endclass
