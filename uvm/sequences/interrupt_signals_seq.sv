// Interrupt Signals Comprehensive Sequence
// Tests all interrupt signal combinations and patterns
// Targets: Interrupt Signals coverage (currently 100% but verifying all combinations)

class interrupt_signals_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(interrupt_signals_seq)

    transaction tr;
    int num_iterations = 64;

    function new(string name = "interrupt_signals_seq");
        super.new(name);
        `uvm_info("Interrupt Signals Sequence", "Constructed interrupt_signals_seq", UVM_HIGH)
    endfunction

    function void set_num_iterations(int n);
        num_iterations = n;
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        `uvm_info("INT_SIGNALS", "Phase 1: Basic interrupt write/read cycles", UVM_MEDIUM)
        for (int i = 0; i < num_iterations/4; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hABCD_0000 + i;
            finish_item(tr);
            #10ns;

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #10ns;
        end

        #50ns;

        `uvm_info("INT_SIGNALS", "Phase 2: Concurrent write/read interrupt generation", UVM_MEDIUM)
        for (int i = 0; i < num_iterations/4; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hDEF0_0000 + i;
            finish_item(tr);
            #5ns;

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #5ns;
        end

        #50ns;

        `uvm_info("INT_SIGNALS", "Phase 3: Interrupt with FIFO full condition", UVM_MEDIUM)
        for (int i = 0; i < 32; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hF001_0000 + i;
            finish_item(tr);
            #3ns;
        end

        #100ns;

        for (int i = 0; i < 16; i++) begin
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #5ns;
        end

        #50ns;

        `uvm_info("INT_SIGNALS", "Phase 4: Interrupt with FIFO empty condition", UVM_MEDIUM)
        for (int i = 0; i < 8; i++) begin
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #5ns;
        end

        #100ns;

        for (int i = 0; i < 8; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hE001_0000 + i;
            finish_item(tr);
            #5ns;
        end

        `uvm_info("INT_SIGNALS", "Interrupt signals test completed", UVM_MEDIUM)
    endtask

endclass
