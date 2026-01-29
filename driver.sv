class drv extends uvm_driver #(transaction);
    `uvm_component_utils(drv)

    virtual intf.drv_mp vif;
    transaction  tr;

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
    endfunction

    task run_phase(uvm_phase phase);

        super.run_phase(phase);
        `uvm_info("Driver", "Run phase driver", UVM_HIGH)
        tr = transaction::type_id::create("tr");

        // drive defaults
        reset_signals();

        // wait for reset deassert
        wait (!vif.axi_resetn);
        @(posedge vif.axi_resetn);

        forever begin
            seq_item_port.get_next_item(tr);
            drive(tr);
            `uvm_info("Driver", "Drove a transaction", UVM_NONE)
            tr.print();
            seq_item_port.item_done();
        end
    endtask

    task drive(transaction tr);
        case (tr.kind)
            WRITE: begin
                drive_write(tr.addr, tr.data);
            end
            PERIPH_READ: begin
                drive_periph_read();
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

    task drive_write(bit [3:0] addr, bit [31:0] data);
        // Flow control: do not issue writes when FIFO is full.
        // Important: never wait forever here; just skip and allow the test to progress/terminate.
        if (vif.rd_full) begin
            `uvm_info("Driver", "Skipping WRITE because FIFO is FULL", UVM_MEDIUM)
            return;
        end

        // present AW/W
        @(posedge vif.clk_axi);
        vif.awaddr  <= addr;
        vif.awvalid <= 1'b1;
        vif.wdata   <= data;
        vif.wstrb   <= 4'hF;
        vif.wvalid  <= 1'b1;

        // wait for handshake
        wait (vif.awready && vif.wready);
        @(posedge vif.clk_axi);
        vif.awvalid <= 1'b0;
        vif.wvalid  <= 1'b0;

        // wait for B response
        vif.bready <= 1'b1;
        wait (vif.bvalid);
        @(posedge vif.clk_axi);
        vif.bready <= 1'b0;
    endtask

    task drive_periph_read();
        // Flow control: do not issue reads when FIFO is empty.
        // Important: never wait forever here; just skip and allow the test to progress/terminate.
        if (vif.rd_empty) begin
            `uvm_info("Driver", "Skipping PERIPH_READ because FIFO is EMPTY", UVM_MEDIUM)
            return;
        end
        @(posedge vif.clk_periph);
        vif.rd_en <= 1'b1;
        @(posedge vif.clk_periph);
        vif.rd_en <= 1'b0;
    endtask

endclass
