package axi4_uvm_pkg;
    timeunit 1ns; timeprecision 1ps;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // UVM components
    `include "seq_item.sv"
    `include "sequence.sv"
    `include "sequencer.sv"
    `include "driver.sv"
    `include "monitor.sv"
    `include "agent.sv"
    `include "scoreboard.sv"
    `include "env.sv"
    
    // Sequences
    `include "basic_rw_seq.sv"
    `include "fifo_full_seq.sv"
    `include "fifo_empty_seq.sv"
    `include "reset_seq.sv"
    
    // Tests
    `include "rand_test.sv"
    `include "basic_rw_test.sv"
    `include "fifo_full_test.sv"
    `include "fifo_empty_test.sv"
    `include "reset_test.sv"

endpackage : axi4_uvm_pkg

