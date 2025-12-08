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
    `include "rand_test.sv"

endpackage : axi4_uvm_pkg

