// ============================================================
// COMPREHENSIVE COVERAGE TEST
// ============================================================
// Runs a broad set of functional coverage sequences to maximize
// real coverage feedback from the DUT.
// Targets 95%+ functional coverage across all 5 covergroups.

class coverage_test_simple extends uvm_test;
    `uvm_component_utils(coverage_test_simple)

    env environment;

    function new(string name = "coverage_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        environment = env::type_id::create("environment", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        basic_rw_seq            basic_seq;
        fifo_full_seq           full_seq;
        fifo_empty_seq          empty_seq;
        continuous_rw_seq       cont_seq;
        protocol_variation_seq  proto_var_seq;
        cdc_wraparound_seq      cdc_wrap_seq;
        interrupt_stimulus_seq  intr_seq;
        error_injection_seq     err_seq;
        full_write_full_read_seq fwfr_seq;
        stress_load_seq         stress_seq;
        protocol_edge_case_seq  edge_seq;

        phase.raise_objection(this);

        `uvm_info("coverage_test", "==== Starting Comprehensive Functional Coverage Test ====", UVM_MEDIUM)

        // ----------------------------------------------------------------
        // Seq 1: Basic R/W – hits WRITE(0x0) + PERIPH_READ, FIFO partial
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 1/10: basic_rw_seq", UVM_MEDIUM)
        basic_seq = basic_rw_seq::type_id::create("basic_seq");
        basic_seq.start(environment.agent.sequencer);
        #200ns;

        // ----------------------------------------------------------------
        // Seq 2: Fill FIFO to full – hits WRITE(0x0) FIFO-full state,
        //        overflow attempt (SLVERR response on write)
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 2/10: fifo_full_seq", UVM_MEDIUM)
        full_seq = fifo_full_seq::type_id::create("full_seq");
        full_seq.start(environment.agent.sequencer);
        #200ns;

        // ----------------------------------------------------------------
        // Seq 3: Drain FIFO to empty – hits PERIPH_READ FIFO-empty state
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 3/10: fifo_empty_seq", UVM_MEDIUM)
        empty_seq = fifo_empty_seq::type_id::create("empty_seq");
        empty_seq.start(environment.agent.sequencer);
        #200ns;

        // ----------------------------------------------------------------
        // Seq 4: Continuous R/W – hits partial FIFO state for all kinds
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 4/10: continuous_rw_seq", UVM_MEDIUM)
        cont_seq = continuous_rw_seq::type_id::create("cont_seq");
        cont_seq.start(environment.agent.sequencer);
        #300ns;

        // ----------------------------------------------------------------
        // Seq 5: Protocol variations – hits WRITE(0x4), strobe 0x5/0xA/0xF,
        //        AXI_READ(0x0) and AXI_READ(0x4)
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 5/10: protocol_variation_seq", UVM_MEDIUM)
        proto_var_seq = protocol_variation_seq::type_id::create("proto_var_seq");
        proto_var_seq.start(environment.agent.sequencer);
        #300ns;

        // ----------------------------------------------------------------
        // Seq 6: CDC wraparound – multiple fill/drain cycles, all FIFO states
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 6/10: cdc_wraparound_seq", UVM_MEDIUM)
        cdc_wrap_seq = cdc_wraparound_seq::type_id::create("cdc_wrap_seq");
        cdc_wrap_seq.start(environment.agent.sequencer);
        #300ns;

        // ----------------------------------------------------------------
        // Seq 7: Interrupt stimulus – fill to full (FIFO-full state),
        //        drain to empty (FIFO-empty state)
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 7/10: interrupt_stimulus_seq", UVM_MEDIUM)
        intr_seq = interrupt_stimulus_seq::type_id::create("intr_seq");
        intr_seq.start(environment.agent.sequencer);
        #300ns;

        // ----------------------------------------------------------------
        // Seq 8: Error injection – overflow (SLVERR), underflow, recovery
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 8/10: error_injection_seq", UVM_MEDIUM)
        err_seq = error_injection_seq::type_id::create("err_seq");
        err_seq.start(environment.agent.sequencer);
        #300ns;

        // ----------------------------------------------------------------
        // Seq 9: Full write then full read – ensures all FIFO states seen
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 9/10: full_write_full_read_seq", UVM_MEDIUM)
        fwfr_seq = full_write_full_read_seq::type_id::create("fwfr_seq");
        fwfr_seq.start(environment.agent.sequencer);
        #300ns;

        // ----------------------------------------------------------------
        // Seq 10: Stress load – high-volume mixed transactions
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 10/11: stress_load_seq", UVM_MEDIUM)
        stress_seq = stress_load_seq::type_id::create("stress_seq");
        stress_seq.start(environment.agent.sequencer);
        #300ns;

        // ----------------------------------------------------------------
        // Seq 11: Protocol edge cases – WRITE to addr 0x4, AXI reads at 0x4
        // ----------------------------------------------------------------
        `uvm_info("coverage_test", "Seq 11/11: protocol_edge_case_seq", UVM_MEDIUM)
        edge_seq = protocol_edge_case_seq::type_id::create("edge_seq");
        edge_seq.start(environment.agent.sequencer);
        #300ns;

        `uvm_info("coverage_test", "==== Comprehensive Functional Coverage Test Completed ====", UVM_MEDIUM)

        phase.drop_objection(this);
    endtask

endclass : coverage_test_simple
