// ============================================================================
// File: protocol_variation_seq.sv
// Description: AXI Protocol Coverage Variation Sequence
//
// This sequence exercises AXI protocol variations including:
// 1. Different address modes (0x0 data, 0x4 status/peek)
// 2. Write strobe patterns (full and partial writes)
// 3. Interleaved status reads and writes
//
// Stimulus: Mixed addressing and strobe patterns
// Coverage Goals:
//   - All AXI write address modes (0x0, 0x4)
//   - Write strobe patterns (0x0, 0x5, 0xA, 0xF)
//   - Read address modes (0x0 status, 0x4 peek)
//   - Response code generation (OKAY, SLVERR)
//   - Cross-coverage: address mode vs response code
// ============================================================================

class protocol_variation_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(protocol_variation_seq)
    
    transaction tr;
    
    function new(string name = "protocol_variation_seq");
        super.new(name);
    endfunction
    
    task body();
        randcase
            40: test_address_0x0_writes();    // 40% standard writes to 0x0
            30: test_address_0x4_operations();  // 30% status/peek operations
            30: test_strobe_variations();       // 30% strobe pattern variations
        endcase
    endtask
    
    // Test standard writes to address 0x0 (data writes)
    task test_address_0x0_writes();
        `uvm_info("Protocol Var Seq", "Testing address 0x0 writes (data address)", UVM_LOW)
        
        for (int i = 0; i < 4; i++) begin
            start_item(tr);
            tr = transaction::type_id::create("tr");
            tr.kind = WRITE;
            tr.addr = 4'h0;  // Data address
            tr.data = 32'h1111_0000 + i;
            finish_item(tr);
            #50ns;
        end
        
        #100ns;  // CDC settling
        
        // Read back
        for (int i = 0; i < 4; i++) begin
            start_item(tr);
            tr = transaction::type_id::create("tr");
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            finish_item(tr);
            #50ns;
        end
    endtask
    
    // Test address 0x4 (status/peek operations)
    task test_address_0x4_operations();
        `uvm_info("Protocol Var Seq", "Testing address 0x4 status/peek", UVM_LOW)
        
        // First write some data to 0x0
        for (int i = 0; i < 3; i++) begin
            start_item(tr);
            tr = transaction::type_id::create("tr");
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h4444_0000 + i;
            finish_item(tr);
            #50ns;
        end
        
        // Now attempt status reads (address 0x4)
        // In actual implementation, 0x4 might be for status/peek
        start_item(tr);
        tr = transaction::type_id::create("tr");
        tr.kind = 1'b0;  // READ operation
        tr.addr = 4'h4;  // Status/peek address
        finish_item(tr);
        
        #100ns;
        
        // Another status read
        start_item(tr);
        tr = transaction::type_id::create("tr");
        tr.kind = 1'b0;
        tr.addr = 4'h4;
        finish_item(tr);
    endtask
    
    // Test write strobe variations
    task test_strobe_variations();
        `uvm_info("Protocol Var Seq", "Testing write strobe pattern variations", UVM_LOW)
        
        // Write with different strobes for partial write coverage
        // Note: Driver may need modification to support variable strobes
        
        for (int i = 0; i < 4; i++) begin
            start_item(tr);
            tr = transaction::type_id::create("tr");
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h5555_0000 + i;
            // Strobe patterns: 0x5 (binary 0101), 0xA (binary 1010), 0xF (binary 1111)
            case(i % 3)
                0: tr.strobe = 4'h5;  // Bytes 0,2
                1: tr.strobe = 4'hA;  // Bytes 1,3
                2: tr.strobe = 4'hF;  // All bytes
            endcase
            finish_item(tr);
            #50ns;
        end
        
        #100ns;
        
        // Read back to verify strobed writes
        for (int i = 0; i < 4; i++) begin
            start_item(tr);
            tr = transaction::type_id::create("tr");
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            finish_item(tr);
            #50ns;
        end
    endtask
    
endclass
