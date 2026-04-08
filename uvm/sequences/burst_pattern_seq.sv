// Burst Pattern Sequence
// Tests different addressing patterns and burst behaviors
// Targets: AXI Protocol coverage (currently 85%), FIFO State Machine (92%)

class burst_pattern_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(burst_pattern_seq)

    transaction tr;
    int burst_length = 16;

    function new(string name = "burst_pattern_seq");
        super.new(name);
        `uvm_info("Burst Pattern Sequence", "Constructed burst_pattern_seq", UVM_HIGH)
    endfunction

    function void set_burst_length(int len);
        burst_length = len;
    endfunction

    task body();
        tr = transaction::type_id::create("tr");

        // Burst Pattern 1: Sequential address writes
        `uvm_info("BURST_PATTERN", "Starting sequential address pattern", UVM_MEDIUM)
        for (int i = 0; i < burst_length; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = (i % 2) ? 4'h4 : 4'h0;  // Alternate between valid addresses
            tr.data = 32'hDEAD_0000 + i;
            finish_item(tr);
            #8ns;
        end

        #50ns;  // Gap between bursts

        // Burst Pattern 2: Same address writes (most common for FIFO)
        `uvm_info("BURST_PATTERN", "Starting fixed address write burst", UVM_MEDIUM)
        for (int i = 0; i < burst_length; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h0F1F_0000 + i;
            finish_item(tr);
            #8ns;
        end

        #50ns;  // Gap between bursts

        // Burst Pattern 3: Reads from fixed address
        `uvm_info("BURST_PATTERN", "Starting fixed address read burst", UVM_MEDIUM)
        for (int i = 0; i < burst_length; i++) begin
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #8ns;
        end

        #50ns;

        // Burst Pattern 4: Alternating address burst
        `uvm_info("BURST_PATTERN", "Starting alternating address burst", UVM_MEDIUM)
        for (int i = 0; i < burst_length; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = (i % 2) ? 4'h4 : 4'h0;
            tr.data = 32'hA1DE_0000 + i;
            finish_item(tr);
            #12ns;  // Slightly slower to allow processor time
        end

        `uvm_info("BURST_PATTERN", "Burst pattern test completed", UVM_MEDIUM)
    endtask

endclass
