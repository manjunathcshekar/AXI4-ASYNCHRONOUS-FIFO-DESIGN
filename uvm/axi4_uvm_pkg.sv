package axi4_uvm_pkg;
    timeunit 1ns; timeprecision 1ps;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // UVM components
    `include "sequences/seq_item.sv"
    `include "sequences/sequence.sv"
    `include "components/sequencer.sv"
    `include "components/driver.sv"
    `include "components/monitor.sv"
    `include "components/agent.sv"
    `include "components/scoreboard.sv"
    `include "components/env.sv"
    
    // Sequences
    `include "sequences/basic_rw_seq.sv"
    `include "sequences/fifo_full_seq.sv"
    `include "sequences/fifo_empty_seq.sv"
    `include "sequences/reset_seq.sv"
    
    // Tests
    `include "tests/rand_test.sv"
    `include "tests/basic_rw_test.sv"
    `include "tests/fifo_full_test.sv"
    `include "tests/fifo_empty_test.sv"
    `include "tests/reset_test.sv"

endpackage : axi4_uvm_pkg

