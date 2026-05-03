class drv extends uvm_driver #(transaction);
    `uvm_component_utils(drv)

    virtual intf.drv_mp vif;
    transaction  tr;
    uvm_analysis_port #(transaction) coverage_port;

    function new(string name = "driver", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Driver", "Constructed driver", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Driver", "Build phase driver", UVM_HIGH)

        if (!(uvm_config_db#(virtual intf.drv_mp)::get(this, "", "vif", vif))) begin
            `uvm_fatal("Driver", "Driver couldn't get vif")
        end
        coverage_port = new("coverage_port", this);
    endfunction

    task run_phase(uvm_phase phase);

        super.run_phase(phase);
        `uvm_info("Driver", "Run phase driver", UVM_HIGH)
        tr = transaction::type_id::create("tr");

        // drive defaults
        reset_signals();

        // wait for reset deassert
        wait (vif.axi_resetn === 1'b1);

        forever begin
            // If reset asserts at any time, immediately quiesce and wait for release
            if (vif.axi_resetn === 1'b0) begin
                reset_signals();
                wait (vif.axi_resetn === 1'b1);
                @(posedge vif.clk_axi);
            end
            seq_item_port.get_next_item(tr);
            // Snapshot FIFO state before driving (for coverage of flow-control skips)
            tr.fifo_empty = vif.rd_empty;
            tr.fifo_full  = vif.rd_full;
            drive(tr);
            // Send all transaction types to coverage (monitor handles writes too,
            // but driver sends pre-drive state for flow-control skips)
            coverage_port.write(tr);
            `uvm_info("Driver", "Drove a transaction", UVM_NONE)
            tr.print();
            seq_item_port.item_done();
        end
    endtask

    task drive(transaction tr);
        case (tr.kind)
            WRITE: begin
                drive_write(tr.addr, tr.data, tr.strobe);
            end
            PERIPH_READ: begin
                drive_periph_read();
            end
            AXI_READ: begin
                drive_axi_read(tr.addr);
            end
            default: begin
                `uvm_warning("Driver", "Unknown transaction kind")
            end
        endcase
    endtask

    task reset_signals();
        vif.awaddr  <= '0;
        vif.awvalid <= 1'b0;
        vif.wdata   <= '0;
        vif.wstrb   <= 4'h0;
        vif.wvalid  <= 1'b0;
        vif.bready  <= 1'b0;
        vif.araddr  <= '0;
        vif.arvalid <= 1'b0;
        vif.rready  <= 1'b0;
        vif.rd_en   <= 1'b0;
        vif.irq_clear_full  <= 1'b0;
        vif.irq_clear_empty <= 1'b0;
    endtask

    task drive_write(bit [3:0] addr, bit [31:0] data, bit [3:0] strobe = 4'hF);
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end
        // Flow control: do not issue writes when FIFO is full.
        // Important: never wait forever here; just skip and allow the test to progress/terminate.
        if (vif.rd_full) begin
            `uvm_info("Driver", "Skipping WRITE because FIFO is FULL", UVM_MEDIUM)
            return;
        end

        // present AW/W
        @(posedge vif.clk_axi);
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end
        vif.awaddr  <= addr;
        vif.awvalid <= 1'b1;
        vif.wdata   <= data;
        vif.wstrb   <= strobe;
        vif.wvalid  <= 1'b1;

        // wait for handshake
        wait ((vif.awready && vif.wready) || (vif.axi_resetn === 1'b0));
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end
        @(posedge vif.clk_axi);
        vif.awvalid <= 1'b0;
        vif.wvalid  <= 1'b0;

        // wait for B response
        vif.bready <= 1'b1;
        wait (vif.bvalid || (vif.axi_resetn === 1'b0));
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end
        @(posedge vif.clk_axi);
        vif.bready <= 1'b0;
    endtask

    task drive_axi_read(bit [3:0] addr);
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end

        // present AR
        @(posedge vif.clk_axi);
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end
        vif.araddr  <= addr;
        vif.arvalid <= 1'b1;

        // wait for read address handshake
        wait ((vif.arready && vif.arvalid) || (vif.axi_resetn === 1'b0));
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end
        @(posedge vif.clk_axi);
        vif.arvalid <= 1'b0;

        // ready to accept read data
        vif.rready <= 1'b1;
        wait ((vif.rvalid && vif.rready) || (vif.axi_resetn === 1'b0));
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end
        @(posedge vif.clk_axi);
        vif.rready <= 1'b0;
    endtask

    task drive_periph_read();
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end
        // Flow control: do not issue reads when FIFO is empty.
        // Important: never wait forever here; just skip and allow the test to progress/terminate.
        if (vif.rd_empty) begin
            `uvm_info("Driver", "Skipping PERIPH_READ because FIFO is EMPTY", UVM_MEDIUM)
            return;
        end
        @(posedge vif.clk_periph);
        if (vif.axi_resetn === 1'b0) begin
            reset_signals();
            return;
        end
        vif.rd_en <= 1'b1;
        @(posedge vif.clk_periph);
        vif.rd_en <= 1'b0;
    endtask

endclass
