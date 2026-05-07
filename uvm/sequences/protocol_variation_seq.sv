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
        // Run ALL three sub-tasks every time to ensure full coverage of
        // addresses, strobe patterns, and AXI read addresses.
        test_address_0x0_writes();
        test_address_0x4_operations();
        test_strobe_variations();
    endtask
    
    // Test standard writes to address 0x0 (data writes)
    task test_address_0x0_writes();
        `uvm_info("Protocol Var Seq", "Testing address 0x0 writes (data address)", UVM_LOW)
        
        for (int i = 0; i < 4; i++) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;  // Data address
            tr.data = 32'h1111_0000 + i;
            finish_item(tr);
            #50ns;
        end
        
        #100ns;  // CDC settling
        
        // Read back
        for (int i = 0; i < 4; i++) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            finish_item(tr);
            #50ns;
        end
        
        // AXI status read at 0x0 when FIFO is now empty (addr_status × empty)
        // Note: test_address_0x4_operations also covers this, but belt-and-suspenders
        #50ns;
        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.kind = AXI_READ;
        tr.addr = 4'h0;
        finish_item(tr);
    endtask
    
    // Test address 0x4 (status/peek operations)
    task test_address_0x4_operations();
        `uvm_info("Protocol Var Seq", "Testing address 0x4 status/peek and 0x0 status", UVM_LOW)
        
        // ---- Phase 0: Write to addr 0x4 (ctrl address) while FIFO has room ----
        // This hits the addr_ctrl bin in cg_axi_write
        for (int i = 0; i < 3; i++) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            tr.kind   = WRITE;
            tr.addr   = 4'h4;   // ctrl address — the missing bin
            tr.data   = 32'hC001_0000 + i;
            tr.strobe = 4'hF;
            finish_item(tr);
            #50ns;
        end
        for (int i = 0; i < 3; i++) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h4444_0000 + i;
            finish_item(tr);
            #50ns;
        end
        
        // AXI status read at 0x0 when FIFO has data (addr_status × not_empty)
        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.kind = AXI_READ;
        tr.addr = 4'h0;
        finish_item(tr);
        #50ns;
        
        // AXI peek read at 0x4 when FIFO has data (addr_peek × not_empty)
        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.kind = AXI_READ;
        tr.addr = 4'h4;
        finish_item(tr);
        #50ns;
        
        // ---- Phase B: Fill FIFO to full, then AXI read (fifo_state: AXI_READ × full) ----
        // Write 8 more entries to fill the FIFO (FIFO depth=8, already has 3)
        for (int i = 0; i < 5; i++) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            tr.kind = WRITE;
            tr.addr = 4'h0;
            tr.data = 32'h4455_0000 + i;
            finish_item(tr);
            #50ns;
        end
        
        // AXI status read at 0x0 when FIFO is FULL (addr_status × not_empty, fifo_state AXI_READ×full)
        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.kind = AXI_READ;
        tr.addr = 4'h0;
        finish_item(tr);
        #50ns;
        
        // AXI peek at 0x4 when FIFO is FULL (addr_peek × not_empty, fifo_state AXI_READ×full)
        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.kind = AXI_READ;
        tr.addr = 4'h4;
        finish_item(tr);
        #50ns;
        
        // ---- Phase C: Drain FIFO to empty, then AXI read (addr × empty) ----
        // Drain all 8 entries
        for (int i = 0; i < 8; i++) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            finish_item(tr);
            #50ns;
        end
        
        // AXI status read at 0x0 when FIFO is EMPTY (addr_status × empty)
        #50ns;
        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.kind = AXI_READ;
        tr.addr = 4'h0;
        finish_item(tr);
        #50ns;
        
        // AXI peek at 0x4 when FIFO is EMPTY (addr_peek × empty)
        tr = transaction::type_id::create("tr");
        start_item(tr);
        tr.kind = AXI_READ;
        tr.addr = 4'h4;
        finish_item(tr);
        #50ns;
    endtask
    
    // Test write strobe variations
    task test_strobe_variations();
        `uvm_info("Protocol Var Seq", "Testing write strobe pattern variations", UVM_LOW)
        
        // Write with different strobes for partial write coverage
        // Note: Driver may need modification to support variable strobes
        
        for (int i = 0; i < 4; i++) begin
            tr = transaction::type_id::create("tr");
            start_item(tr);
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
            tr = transaction::type_id::create("tr");
            start_item(tr);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;
            finish_item(tr);
            #50ns;
        end
    endtask
    
endclass
