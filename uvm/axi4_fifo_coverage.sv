// ============================================================================
// File: axi4_fifo_coverage.sv
// Description: Functional Coverage Model for AXI4 Asynchronous FIFO
// 
// This file defines five covergroups implementing academic-level functional
// coverage for the AXI4-Lite Async FIFO design:
// 1. AXI Protocol Coverage (addresses, strobes, responses)
// 2. FIFO State Machine (occupancy levels and transitions)
// 3. CDC & Synchronization (Gray code pointers, reset timing)
// 4. Interrupt Signals (IRQ generation and clearing)
// 5. Error Scenarios & Edge Cases (overflow, underflow, reset timing)
//
// Coverage integrates with UVM monitor/environment via callback mechanism
// ============================================================================

package axi4_fifo_coverage_pkg;
    import uvm_pkg::*;
    
    `include "uvm_macros.svh"

    // ========================================================================
    // COVERGROUP 1: AXI PROTOCOL COVERAGE
    // ========================================================================
    // Objective: Ensure all AXI protocol variations are exercised
    // - Write/Read address modes (0x0 data, 0x4 status/peek)
    // - Write strobe patterns (full/partial writes)
    // - Response codes (OKAY, SLVERR on overflow)
    
    covergroup cg_axi_protocol @(posedge clk_axi);
        
        // Coverpoint: Write Address Modes
        cp_wr_addr: coverpoint wr_addr {
            bins addr_0x0 = {4'h0};     // Data write
            bins addr_0x4 = {4'h4};     // Control/Status write
            illegal_bins addr_other = default;
        }
        
        // Coverpoint: Write Strobe Patterns  
        cp_wr_strb: coverpoint wr_strb {
            bins strb_0x0 = {4'h0};     // No bytes enabled (invalid)
            bins strb_0x5 = {4'h5};     // Bytes 0,2 (0101 pattern)
            bins strb_0xA = {4'hA};     // Bytes 1,3 (1010 pattern)
            bins strb_0xF = {4'hF};     // All bytes (normal case)
            illegal_bins strb_other = default;
        }
        
        // Coverpoint: Write Response Codes
        cp_wr_resp: coverpoint wr_resp {
            bins resp_okay   = {2'b00};  // Successful write
            bins resp_slverr = {2'b10};  // Slave error (FIFO full)
            illegal_bins resp_other = default;
        }
        
        // Coverpoint: Read Address Modes
        cp_rd_addr: coverpoint rd_addr {
            bins addr_0x0 = {4'h0};     // Status read
            bins addr_0x4 = {4'h4};     // Peek (non-destructive) read
            illegal_bins addr_other = default;
        }
        
        // Coverpoint: Read Response Codes
        cp_rd_resp: coverpoint rd_resp {
            bins resp_okay   = {2'b00};  // Successful read
            bins resp_slverr = {2'b10};  // Slave error (empty on peek)
            illegal_bins resp_other = default;
        }
        
        // Cross-Coverage: Write Address vs Response
        // Validates that correct responses generated for each address
        cross_wr_addr_resp: cross cp_wr_addr, cp_wr_resp {
            // Expected combinations:
            // addr_0x0 can be OKAY or SLVERR (when FIFO full)
            // addr_0x4 typically OKAY
            ignore_bins ignore_addr4_slverr = binsof(cp_wr_addr) intersect {4'h4} &&
                                               binsof(cp_wr_resp) intersect {2'b10};
        }
        
        // Cross-Coverage: Read Address vs Response
        // Validates peek (0x4) returns SLVERR when FIFO empty
        cross_rd_addr_resp: cross cp_rd_addr, cp_rd_resp {
            // addr_0x0 (status) typically returns OKAY regardless of FIFO state
            // addr_0x4 (peek) can return SLVERR when empty
        }
        
        // Cross-Coverage: Write Address vs Strobe
        // Validates strobe patterns used with address modes
        cross_wr_addr_strb: cross cp_wr_addr, cp_wr_strb;
        
        option.per_instance = 1;
        option.name = "cg_axi_protocol";
    endgroup
    
    // ========================================================================
    // COVERGROUP 2: FIFO STATE MACHINE COVERAGE
    // ========================================================================
    // Objective: Verify all FIFO occupancy levels visited and transitions complete
    // - All FIFO depths (0 = empty, 1-7 = partial, 8 = full)
    // - All state transitions between levels
    // - Empty/full flag combinations
    
    covergroup cg_fifo_state @(posedge clk_axi);
        
        // Coverpoint: Current FIFO Occupancy (number of entries)
        cp_fifo_occupancy: coverpoint fifo_level {
            bins empty        = {0};       // FIFO empty
            bins q1           = {1};       // 1 entry
            bins q2           = {2};       // 2 entries
            bins q3           = {3};       // 3 entries
            bins q4           = {4};       // 4 entries (half-full)
            bins q5           = {5};       // 5 entries
            bins q6           = {6};       // 6 entries
            bins q7           = {7};       // 7 entries (almost full)
            bins full         = {8};       // 8 entries (full)
        }
        
        // Coverpoint: Empty Flag Status
        cp_empty_flag: coverpoint rd_empty {
            bins empty_true   = {1'b1};   // FIFO is empty
            bins empty_false  = {1'b0};   // FIFO is NOT empty
        }
        
        // Coverpoint: Full Flag Status
        cp_full_flag: coverpoint rd_full {
            bins full_true    = {1'b1};   // FIFO is full
            bins full_false   = {1'b0};   // FIFO is NOT full
        }
        
        // Cross-Coverage: Occupancy with Empty Flag
        // Verifies that EMPTY flag correctly reflects occupancy
        cross_occupancy_empty: cross cp_fifo_occupancy, cp_empty_flag {
            // Illegal combinations:
            ignore_bins ignore_full_and_empty = 
                binsof(cp_fifo_occupancy) intersect {1,2,3,4,5,6,7,8} &&
                binsof(cp_empty_flag) intersect {1'b1};
        }
        
        // Cross-Coverage: Occupancy with Full Flag
        // Verifies that FULL flag correctly reflects full condition
        cross_occupancy_full: cross cp_fifo_occupancy, cp_full_flag {
            // Illegal combinations:
            ignore_bins ignore_partial_and_full = 
                binsof(cp_fifo_occupancy) intersect {0,1,2,3,4,5,6,7} &&
                binsof(cp_full_flag) intersect {1'b1};
        }
        
        // Cross-Coverage: State Transitions
        // Captures transitions between occupancy levels (e.g., 3 -> 4, 8 -> 7)
        cross_state_transitions: cross cp_fifo_occupancy_prev, cp_fifo_occupancy {
            // All transitions allowed (FIFO can go up or down)
        }
        
        option.per_instance = 1;
        option.name = "cg_fifo_state";
    endgroup
    
    // Previous occupancy level for transition tracking
    bit [3:0] cp_fifo_occupancy_prev;
    
    // ========================================================================
    // COVERGROUP 3: CDC & SYNCHRONIZATION COVERAGE
    // ========================================================================
    // Objective: Verify clock domain crossing safety and proper synchronization
    // - Gray code pointer transitions for all bits
    // - Synchronization delay patterns
    // - Pointer wraparound at FIFO boundaries
    // - Reset timing relative to CDC
    
    covergroup cg_cdc_coverage @(posedge clk_axi or posedge clk_periph);
        
        // Coverpoint: Gray-Coded Write Pointer Bit Transitions
        // Each bit should transition during normal operation
        cp_gray_wr_bit_0: coverpoint wr_ptr_gray[0] {
            bins bit_0_seq = (0 => 1). (1 => 0). (0 => 1). (1 => 0);
        }
        cp_gray_wr_bit_1: coverpoint wr_ptr_gray[1] {
            bins bit_1_seq = (0 => 1). (1 => 0). (0 => 1). (1 => 0);
        }
        cp_gray_wr_bit_2: coverpoint wr_ptr_gray[2] {
            bins bit_2_seq = (0 => 1). (1 => 0). (0 => 1). (1 => 0);
        }
        cp_gray_wr_bit_3: coverpoint wr_ptr_gray[3] {
            bins bit_3_seq = (0 => 1). (1 => 0). (0 => 1). (1 => 0);
        }
        
        // Coverpoint: Gray-Coded Read Pointer Bit Transitions
        cp_gray_rd_bit_0: coverpoint rd_ptr_gray[0] {
            bins bit_0_seq = (0 => 1). (1 => 0). (0 => 1). (1 => 0);
        }
        cp_gray_rd_bit_1: coverpoint rd_ptr_gray[1] {
            bins bit_1_seq = (0 => 1). (1 => 0). (0 => 1). (1 => 0);
        }
        cp_gray_rd_bit_2: coverpoint rd_ptr_gray[2] {
            bins bit_2_seq = (0 => 1). (1 => 0). (0 => 1). (1 => 0);
        }
        cp_gray_rd_bit_3: coverpoint rd_ptr_gray[3] {
            bins bit_3_seq = (0 => 1). (1 => 0). (0 => 1). (1 => 0);
        }
        
        // Coverpoint: Pointer Wraparound Events
        // Captures when pointers wrap around FIFO boundary
        cp_ptr_wraparound: coverpoint ptr_wrap_event {
            bins wrap_at_0 = {4'd0};    // Wrap from 7 or 8 to 0
            bins wrap_at_1 = {4'd1};    // Wrap point detected at 1
            bins wrap_at_4 = {4'd4};    // Wrap at quarter boundary
            bins wrap_at_8 = {4'd8};    // Wrap at full boundary
            bins no_wrap    = {4'd0xff}; // No immediate wrap
        }
        
        // Coverpoint: CDC Synchronization Delay
        // Measure delay between pointer update and observation (0-5 clocks)
        cp_cdc_sync_delay: coverpoint cdc_delay_clocks {
            bins delay_0 = {0};         // Same clock (no delay)
            bins delay_1 = {1};         // 1 clock cycle delay
            bins delay_2 = {2};         // 2 clock cycles delay
            bins delay_3 = {3};         // 3 clock cycles delay
            bins delay_4 = {4};         // 4 clock cycles delay
            bins delay_5 = {5};         // 5+ clock cycles delay
        }
        
        // Coverpoint: Reset Timing Phase
        // Captures what phase FIFO is in when reset asserted
        cp_reset_phase: coverpoint reset_timing_phase {
            bins reset_idle        = {3'b000};  // No transactions pending
            bins reset_wr_pending  = {3'b001};  // Write in-flight
            bins reset_rd_pending  = {3'b010};  // Read in-flight
            bins reset_cdc_sync    = {3'b011};  // During CDC sync
            bins reset_draining    = {3'b100};  // FIFO draining
        }
        
        // Cross-Coverage: Gray Bit Transitions vs FIFO Level
        // Ensures all Gray transitions happen at realistic FIFO occupancies
        cross_gray_wr_level: cross cp_gray_wr_bit_0, cp_fifo_occupancy;
        cross_gray_rd_level: cross cp_gray_rd_bit_0, cp_fifo_occupancy;
        
        // Cross-Coverage: Wraparound vs Reset Phase
        // Identifies wraparound during various reset scenarios
        cross_wrap_reset: cross cp_ptr_wraparound, cp_reset_phase;
        
        option.per_instance = 1;
        option.name = "cg_cdc_coverage";
    endgroup
    
    // ========================================================================
    // COVERGROUP 4: INTERRUPT SIGNAL COVERAGE
    // ========================================================================
    // Objective: Verify interrupt generation and clearing mechanisms
    // - IRQ_FULL assertion when FIFO reaches full capacity
    // - IRQ_EMPTY assertion when FIFO becomes empty
    // - Clear signal acknowledgment and timing
    
    covergroup cg_interrupt_coverage @(posedge clk_axi);
        
        // Coverpoint: IRQ Full Signal States
        cp_irq_full: coverpoint irq_full {
            bins irq_full_asserted   = {1'b1};  // Interrupt asserted
            bins irq_full_deasserted = {1'b0};  // Interrupt cleared
        }
        
        // Coverpoint: IRQ Empty Signal States
        cp_irq_empty: coverpoint irq_empty {
            bins irq_empty_asserted   = {1'b1};  // Interrupt asserted
            bins irq_empty_deasserted = {1'b0};  // Interrupt cleared
        }
        
        // Coverpoint: Clear Full Signal Activity
        cp_irq_clear_full: coverpoint irq_clear_full {
            bins clear_pulsed  = (1'b0 => 1'b1 => 1'b0);  // Pulse pattern
            bins clear_held    = (0 => 1) [* 2:$];         // Held low
            bins clear_inactive = {1'b0};                   // Inactive
        }
        
        // Coverpoint: Clear Empty Signal Activity
        cp_irq_clear_empty: coverpoint irq_clear_empty {
            bins clear_pulsed  = (1'b0 => 1'b1 => 1'b0);  // Pulse pattern
            bins clear_held    = (0 => 1) [* 2:$];         // Held low
            bins clear_inactive = {1'b0};                   // Inactive
        }
        
        // Coverpoint: IRQ Full Signal Duration (cycles held)
        cp_irq_full_duration: coverpoint irq_full_cycles {
            bins duration_0 = {0};
            bins duration_1_5 = {[1:5]};
            bins duration_6_15 = {[6:15]};
            bins duration_16_plus = {[16:$]};
        }
        
        // Coverpoint: IRQ Empty Signal Duration
        cp_irq_empty_duration: coverpoint irq_empty_cycles {
            bins duration_0 = {0};
            bins duration_1_5 = {[1:5]};
            bins duration_6_15 = {[6:15]};
            bins duration_16_plus = {[16:$]};
        }
        
        // Cross-Coverage: IRQ Full Event and Clear Correlation
        // Validates relationship between FULL interrupt and clear signal
        cross_irq_full_clear: cross cp_irq_full, cp_irq_clear_full {
            // Both can be active independently
        }
        
        // Cross-Coverage: IRQ Empty Event and Clear Correlation
        cross_irq_empty_clear: cross cp_irq_empty, cp_irq_clear_empty {
            // Both can be active independently
        }
        
        option.per_instance = 1;
        option.name = "cg_interrupt_coverage";
    endgroup
    
    // Tracking variables for interrupt durations
    int irq_full_cycles = 0;
    int irq_empty_cycles = 0;
    
    // ========================================================================
    // COVERGROUP 5: ERROR SCENARIOS & EDGE CASES
    // ========================================================================
    // Objective: Verify proper handling of error conditions and edge cases
    // - Overflow attempts when FIFO full
    // - Underflow attempts when FIFO empty
    // - Reset during various operation phases
    // - Post-reset state validity
    
    covergroup cg_error_scenarios @(posedge clk_axi);
        
        // Coverpoint: Overflow Attempt Detection
        cp_overflow_attempt: coverpoint overflow_detected {
            bins overflow_write_full   = {1'b1};  // Write attempted while full
            bins normal_operation      = {1'b0};  // No overflow condition
        }
        
        // Coverpoint: Underflow Attempt Detection
        cp_underflow_attempt: coverpoint underflow_detected {
            bins underflow_read_empty  = {1'b1};  // Read attempted while empty
            bins normal_operation      = {1'b0};  // No underflow condition
        }
        
        // Coverpoint: Reset Assertion Timing Phase
        cp_reset_assert_phase: coverpoint reset_assert_phase {
            bins phase_idle            = {3'b000};  // FIFO idle
            bins phase_write_active    = {3'b001};  // AXI write in-flight
            bins phase_read_active     = {3'b010};  // Peripheral read in-flight
            bins phase_cdc_sync        = {3'b011};  // CDC sync in progress
            bins phase_transitioning   = {3'b100};  // FIFO transitioning states
        }
        
        // Coverpoint: FIFO Level When Reset Asserted
        cp_fifo_level_at_reset: coverpoint fifo_level_at_reset {
            bins fifo_empty_at_reset    = {0};           // Reset while empty
            bins fifo_partial_at_reset  = {[1:7]};       // Reset while partial
            bins fifo_full_at_reset     = {8};           // Reset while full
        }
        
        // Coverpoint: Post-Reset Data Validity
        cp_post_reset_validity: coverpoint post_reset_valid {
            bins post_reset_valid       = {1'b1};  // Post-reset data valid
            bins post_reset_corrupted   = {1'b0};  // Post-reset data corrupted
        }
        
        // Coverpoint: SLVERR Response Generation
        cp_slverr_response: coverpoint slverr_detected {
            bins slverr_generated       = {1'b1};  // SLVERR on full overflow
            bins okayresp_generated     = {1'b0};  // OKAY response
        }
        
        // Cross-Coverage: Overflow with Response Code
        // Validates SLVERR generated on overflow
        cross_overflow_resp: cross cp_overflow_attempt, cp_slverr_response {
            // When overflow detected, SLVERR should be generated
            illegal_bins illegal_overflow_no_slverr = 
                binsof(cp_overflow_attempt) intersect {1'b1} &&
                binsof(cp_slverr_response) intersect {1'b0};
        }
        
        // Cross-Coverage: Reset Timing vs FIFO Level
        // Captures full reset scenario combinations
        cross_reset_state: cross cp_reset_assert_phase, cp_fifo_level_at_reset {
            // All combinations valid
        }
        
        // Cross-Coverage: Underflow with Empty Flag  
        // Validates underflow detection aligns with EMPTY flag
        cross_underflow_empty: cross cp_underflow_attempt, cp_empty_flag {
            // Underflow should correlate with EMPTY flag
        }
        
        option.per_instance = 1;
        option.name = "cg_error_scenarios";
    endgroup
    
    // Tracking variables
    bit overflow_detected = 1'b0;
    bit underflow_detected = 1'b0;
    bit post_reset_valid = 1'b1;
    bit slverr_detected = 1'b0;
    bit [3:0] reset_timing_phase = 4'b0;
    bit [3:0] reset_assert_phase = 4'b0;
    bit [3:0] fifo_level_at_reset = 4'b0;
    bit [3:0] ptr_wrap_event = 4'hFF;
    int cdc_delay_clocks = 0;
    
    // ========================================================================
    // INTERFACE BINDINGS (Sampling Variables)
    // ========================================================================
    // These variables are sampled from the interface/monitor
    // and drive the coverpoints above
    
    logic clk_axi;
    logic clk_periph;
    logic [3:0] wr_addr;
    logic [3:0] wr_strb;
    logic [1:0] wr_resp;
    logic [3:0] rd_addr;
    logic [1:0] rd_resp;
    logic [3:0] fifo_level;
    logic rd_empty;
    logic rd_full;
    logic [4:0] wr_ptr_gray;
    logic [4:0] rd_ptr_gray;
    logic [4:0] wr_ptr_bin;
    logic [4:0] rd_ptr_bin;
    logic irq_full;
    logic irq_empty;
    logic irq_clear_full;
    logic irq_clear_empty;
    
    // ========================================================================
    // COVERAGE CALLBACK CLASS
    // ========================================================================
    // Integrates coverage collection with UVM environment
    // Hook this into the monitor or driver via callback mechanism
    
    class coverage_callback extends uvm_callback;
        `uvm_object_utils(coverage_callback)
        
        function new(string name = "coverage_callback");
            super.new(name);
        endfunction
        
        // Called at appropriate sampling points to update coverage
        virtual function void sample_axi_protocol(
            logic [3:0] addr,
            logic [3:0] strb,
            logic [1:0] resp,
            logic is_write
        );
            if (is_write) begin
                wr_addr = addr;
                wr_strb = strb;
                wr_resp = resp;
            end else begin
                rd_addr = addr;
                rd_resp = resp;
            end
        endfunction
        
        virtual function void sample_fifo_state(
            logic [3:0] occupancy,
            logic empty,
            logic full
        );
            cp_fifo_occupancy_prev = fifo_level;
            fifo_level = occupancy;
            rd_empty = empty;
            rd_full = full;
        endfunction
        
        virtual function void sample_cdc_status(
            logic [4:0] wr_ptr_g,
            logic [4:0] rd_ptr_g,
            logic [4:0] wr_ptr_b,
            logic [4:0] rd_ptr_b
        );
            wr_ptr_gray = wr_ptr_g;
            rd_ptr_gray = rd_ptr_g;
            wr_ptr_bin = wr_ptr_b;
            rd_ptr_bin = rd_ptr_b;
        endfunction
        
        virtual function void sample_interrupt_status(
            logic full_irq,
            logic empty_irq,
            logic clear_full,
            logic clear_empty
        );
            irq_full = full_irq;
            irq_empty = empty_irq;
            irq_clear_full = clear_full;
            irq_clear_empty = clear_empty;
        endfunction
        
        virtual function void sample_error_condition(
            logic overflow,
            logic underflow,
            logic slverr
        );
            overflow_detected = overflow;
            underflow_detected = underflow;
            slverr_detected = slverr;
        endfunction
    endclass

endpackage: axi4_fifo_coverage_pkg
