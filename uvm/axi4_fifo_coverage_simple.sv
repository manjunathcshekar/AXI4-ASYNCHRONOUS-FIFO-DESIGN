// ============================================================
// SIMPLIFIED FUNCTIONAL COVERAGE - TRANSACTION LEVEL
// ============================================================
// This uses transaction-level coverage (not raw RTL signals)
// which is more practical and actually compiles in QuestaSim
// ============================================================

package axi4_fifo_coverage_pkg;
    import uvm_pkg::*;
    
    // ============================================================
    // TRANSACTION-LEVEL COVERAGE (What the UVM sees)
    // ============================================================
    class axi4_fifo_coverage extends uvm_subscriber #(transaction);
        `uvm_component_utils(axi4_fifo_coverage)
        
        // Covergroups (defined INSIDE the class, not in package)
        covergroup write_operations;
            write_kind: coverpoint (last_tr.kind == WRITE) {
                bins is_write = {1};
                bins not_write = {0};
            }
            wr_data: coverpoint last_tr.data {
                bins zero = {32'h0};
                bins ones = {32'hFFFFFFFF};
                bins pattern_5 = {32'h5A5A5A5A};
                bins pattern_A = {32'hA5A5A5A5};
                bins other = default;
            }
            cross write_kind, wr_data;
        endgroup
        
        covergroup read_operations;
            address: coverpoint last_tr.addr {
                bins addr_data = {4'h0};
                bins addr_status = {4'h4};
            }
            read_kind: coverpoint (last_tr.kind == READ) {
                bins is_read = {1};
                bins not_read = {0};
            }
            read_data: coverpoint last_tr.observed_data {
                bins zero = {32'h0};
                bins ones = {32'hFFFFFFFF};
                bins pattern_5 = {32'h5A5A5A5A};
                bins pattern_A = {32'hA5A5A5A5};
                bins other = default;
            }
            cross read_kind, address, read_data;
        endgroup
        
        covergroup fifo_sequences;
            sequence_type: coverpoint sequence_name {
                bins write_only = {"WRITE"};
                bins read_only = {"READ"};
                bins write_read_pairs = {"WR_PAIR"};
                bins mixed = {"MIXED"};
            }
            transaction_count: coverpoint tr_count {
                bins small = {[1:10]};
                bins medium = {[11:50]};
                bins large = {[51:100]};
                bins xlarge = {[101:$]};
            }
            cross sequence_type, transaction_count;
        endgroup
        
        // ============================================================
        // Member variables
        // ============================================================
        transaction last_tr;
        string sequence_name = "UNKNOWN";
        int tr_count = 0;
        int write_count = 0;
        int read_count = 0;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
            write_operations = new();
            read_operations = new();
            fifo_sequences = new();
        endfunction
        
        virtual function void write(transaction t);
            last_tr = t;
            tr_count++;
            
            if (t.kind == WRITE) write_count++;
            if (t.kind == READ || t.kind == PERIPH_READ) read_count++;
            
            // Determine sequence type for cross coverage
            if (write_count > 0 && read_count > 0) sequence_name = "WR_PAIR";
            else if (write_count > 0) sequence_name = "WRITE";
            else if (read_count > 0) sequence_name = "READ";
            
            // Sample all covergroups
            write_operations.sample();
            read_operations.sample();
            fifo_sequences.sample();
            
            `uvm_info("COVERAGE", $sformatf(
                "Transaction #%0d: %s at addr=0x%01x data=0x%08x",
                tr_count, 
                (t.kind == WRITE) ? "WRITE" : "READ",
                t.addr,
                t.data), UVM_HIGH)
        endfunction
        
        virtual function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("COVERAGE", $sformatf(
                "Coverage Report: %0d writes, %0d reads, %0d total transactions",
                write_count, read_count, tr_count), UVM_LOW)
        endfunction
        
    endclass : axi4_fifo_coverage
    
endpackage : axi4_fifo_coverage_pkg
