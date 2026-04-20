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
    `include "sequences/reset_check_seq.sv"
    `include "sequences/full_write_full_read_seq.sv"
    `include "sequences/continuous_rw_seq.sv"
    `include "sequences/cdc_stress_seq.sv"
    `include "sequences/burst_pattern_seq.sv"
    `include "sequences/alternating_pattern_seq.sv"
    `include "sequences/boundary_condition_seq.sv"
    `include "sequences/interrupt_signals_seq.sv"
    `include "sequences/stress_load_seq.sv"
    `include "sequences/protocol_edge_case_seq.sv"
    
    // ============================================================
    // COVERAGE INFRASTRUCTURE (Transaction-level)
    // ============================================================
    class axi4_fifo_coverage extends uvm_subscriber #(transaction);
        `uvm_component_utils(axi4_fifo_coverage)
        
        // Covergroups
        covergroup write_operations;
            write_kind: coverpoint last_tr.kind {
                bins is_write = {WRITE};
            }
            // Keep address visibility, but reduce its influence so AXI data
            // patterns drive this covergroup more strongly.
            wr_addr_hint: coverpoint last_tr.addr iff (last_tr.kind == WRITE) {
                option.weight = 1;
                bins fifo_data_port = {4'h0};
                bins status_peek_port = {4'h4};
            }
            wr_data_pattern: coverpoint last_tr.data iff (last_tr.kind == WRITE) {
                bins zero = {32'h0};
                bins ones = {32'hFFFFFFFF};
                bins pattern_5 = {32'h5A5A5A5A};
                bins pattern_A = {32'hA5A5A5A5};
                bins alternating_5 = {32'h5555_5555};
                bins alternating_A = {32'hAAAA_AAAA};
                bins signed_min = {32'h8000_0000};
                bins signed_max = {32'h7FFF_FFFF};
                bins other = default;
            }
            wr_data_lsb: coverpoint last_tr.data[7:0] iff (last_tr.kind == WRITE) {
                bins lsb_zero = {8'h00};
                bins lsb_ff = {8'hFF};
                bins lsb_alt[] = {8'h55, 8'hAA};
                bins lsb_other = default;
            }
            cross write_kind, wr_data_pattern, wr_data_lsb;
            cross wr_addr_hint, wr_data_pattern;
        endgroup
        
        covergroup read_operations;
            read_kind: coverpoint last_tr.kind {
                bins is_read = {PERIPH_READ};
            }
            // Retain the address context for debug, but make data the main goal.
            rd_addr_hint: coverpoint last_tr.addr iff (last_tr.kind == PERIPH_READ) {
                option.weight = 1;
                bins fifo_data_port = {4'h0};
                bins status_peek_port = {4'h4};
            }
            read_data_pattern: coverpoint last_tr.observed_data iff (last_tr.kind == PERIPH_READ) {
                bins zero = {32'h0};
                bins ones = {32'hFFFFFFFF};
                bins pattern_5 = {32'h5A5A5A5A};
                bins pattern_A = {32'hA5A5A5A5};
                bins alternating_5 = {32'h5555_5555};
                bins alternating_A = {32'hAAAA_AAAA};
                bins signed_min = {32'h8000_0000};
                bins signed_max = {32'h7FFF_FFFF};
                bins other = default;
            }
            read_data_lsb: coverpoint last_tr.observed_data[7:0] iff (last_tr.kind == PERIPH_READ) {
                bins lsb_zero = {8'h00};
                bins lsb_ff = {8'hFF};
                bins lsb_alt[] = {8'h55, 8'hAA};
                bins lsb_other = default;
            }
            cross read_kind, read_data_pattern, read_data_lsb;
            cross rd_addr_hint, read_data_pattern;
        endgroup
        
        transaction last_tr;
        int tr_count = 0;
        int write_count = 0;
        int read_count = 0;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
            write_operations = new();
            read_operations = new();
        endfunction
        
        virtual function void write(transaction t);
            last_tr = t;
            tr_count++;
            if (t.kind == WRITE) write_count++;
            if (t.kind == PERIPH_READ) read_count++;
            write_operations.sample();
            read_operations.sample();
        endfunction
        
        virtual function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("COVERAGE", $sformatf("Coverage: %0d writes, %0d reads, %0d total",
                write_count, read_count, tr_count), UVM_LOW)
        endfunction
    endclass
    
    // Tests
    `include "tests/rand_test.sv"
    `include "tests/basic_rw_test.sv"
    `include "tests/fifo_full_test.sv"
    `include "tests/fifo_empty_test.sv"
    `include "tests/reset_test.sv"
    `include "tests/full_write_full_read_test.sv"
    `include "tests/continuous_rw_test.sv"
    `include "tests/coverage_test_simple.sv"
    `include "tests/cdc_stress_test.sv"
    `include "tests/burst_pattern_test.sv"
    `include "tests/alternating_pattern_test.sv"
    `include "tests/boundary_condition_test.sv"
    `include "tests/interrupt_signals_test.sv"
    `include "tests/stress_load_test.sv"
    `include "tests/protocol_edge_case_test.sv"

endpackage : axi4_uvm_pkg

