// Protocol Edge Case Sequence
// Tests AXI protocol boundary conditions and edge cases
// Targets: AXI Protocol coverage (currently 85%)

class protocol_edge_case_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(protocol_edge_case_seq)

    transaction tr;
    int num_cases = 32;

    function new(string name = "protocol_edge_case_seq");
        super.new(name);
        `uvm_info("Protocol Edge Case Sequence", "Constructed protocol_edge_case_seq", UVM_HIGH)
    endfunction

    function void set_num_cases(int n);
        num_cases = n;
    endfunction

    task body();
        // All declarations must come first
        int boundary_data[] = '{32'h0000_0000, 32'hFFFF_FFFF, 32'h8000_0000, 
                               32'h7FFF_FFFF, 32'hAAAA_AAAA, 32'h5555_5555};
        int gap;
        int i, idx, j;
        
        tr = transaction::type_id::create("tr");

        `uvm_info("PROTO_EDGE", "Phase 1: Boundary address values", UVM_MEDIUM)
        // Test with min and max valid addresses
        for (i = 0; i < num_cases/4; i++) begin
            // Write to address 0x0 (minimum valid)
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h1234_0000 + i;
            finish_item(tr);
            #8ns;

            // Write to address 0x4 (maximum valid)
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h4;
            tr.data = 32'h5678_0000 + i;
            finish_item(tr);
            #8ns;

            // Read from address 0x0
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #8ns;

            // Read from address 0x4
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h4;
            tr.data = 32'h0;
            finish_item(tr);
            #8ns;
        end

        #100ns;

        `uvm_info("PROTO_EDGE", "Phase 2: Data boundary values", UVM_MEDIUM)
        // Test with extreme data values
        for (idx = 0; idx < boundary_data.size(); idx++) begin
            for (j = 0; j < 2; j++) begin
                start_item(tr);
                tr.kind = WRITE;
                tr.addr = (j == 0) ? 4'h0 : 4'h4;
                tr.data = boundary_data[idx];
                finish_item(tr);
                #6ns;

                start_item(tr);
                tr.kind = PERIPH_READ;
                tr.addr = (j == 0) ? 4'h0 : 4'h4;
                tr.data = 32'h0;
                finish_item(tr);
                #6ns;
            end
        end

        #100ns;

        `uvm_info("PROTO_EDGE", "Phase 3: Rapid address switching", UVM_MEDIUM)
        // Rapidly switch between addresses
        for (i = 0; i < num_cases; i++) begin
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = (i % 2) ? 4'h4 : 4'h0;
            tr.data = 32'hEDED_0000 + i;
            finish_item(tr);
            #4ns;
        end

        #100ns;

        `uvm_info("PROTO_EDGE", "Phase 4: Protocol response timing", UVM_MEDIUM)
        // Test response timing with various gaps
        for (i = 0; i < num_cases/4; i++) begin
            gap = 100 + (i * 50);  // Increasing gap between write and read

            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'hC0DE_0000 + i;
            finish_item(tr);
            
            #(gap);

            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            tr.data = 32'h0;
            finish_item(tr);
            #20ns;
        end

        `uvm_info("PROTO_EDGE", "Protocol edge case test completed", UVM_MEDIUM)
    endtask

endclass
