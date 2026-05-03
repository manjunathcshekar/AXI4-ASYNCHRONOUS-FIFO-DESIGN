class mon extends uvm_monitor;
    `uvm_component_utils(mon)

    virtual intf.mon_mp vif;
    transaction tr;
    transaction ar_tr;
    bit pending_axi_read;

    // ? you can change the name of the analysis port here
    uvm_analysis_port #(transaction) monitor_port;

    function new(string name = "mon", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Monitor", "Constructed monitor", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);
        `uvm_info("Monitor", "Build phase monitor", UVM_HIGH)
        monitor_port = new("monitor_port", this);

        if (!(uvm_config_db#(virtual intf.mon_mp)::get(this, "", "vif", vif)))
            `uvm_fatal("Monitor", "Couldn't get vif in monitor!")
    endfunction

    task run_phase(uvm_phase phase);

        super.run_phase(phase);
        `uvm_info("Monitor", "Run phase monitor", UVM_HIGH)

        fork
            sample_axi_write();
            sample_axi_read();
            sample_periph_read();
        join_none

    endtask

    // Track AXI write transactions (AW+W handshake -> B response)
    task sample_axi_write();
        transaction wr_tr;
        bit pending_write;
        pending_write = 1'b0;
        forever begin
            @(posedge vif.clk_axi);
            // Capture write address/data at AW+W handshake
            if (vif.awvalid && vif.awready && vif.wvalid && vif.wready) begin
                wr_tr = transaction::type_id::create("mon_write_tr", this);
                wr_tr.kind       = WRITE;
                wr_tr.addr       = vif.awaddr;
                wr_tr.data       = vif.wdata;
                wr_tr.strobe     = vif.wstrb;
                wr_tr.fifo_empty = vif.rd_empty;
                wr_tr.fifo_full  = vif.rd_full;
                pending_write    = 1'b1;
            end
            // Capture response
            if (pending_write && vif.bvalid && vif.bready) begin
                wr_tr.resp = vif.bresp;
                `uvm_info("Monitor", $sformatf("Sampled AXI write: addr=0x%0h data=0x%0h strobe=0x%0h bresp=0x%0h full=%0b", wr_tr.addr, wr_tr.data, wr_tr.strobe, wr_tr.resp, wr_tr.fifo_full), UVM_NONE)
                monitor_port.write(wr_tr);
                pending_write = 1'b0;
            end
        end
    endtask

    task sample_axi_read();
        forever begin
            @(posedge vif.clk_axi);

            if (vif.arvalid && vif.arready) begin
                ar_tr = transaction::type_id::create("mon_axi_read_tr", this);
                ar_tr.kind = AXI_READ;
                ar_tr.addr = vif.araddr;
                ar_tr.data = 32'h0;
                ar_tr.observed_data = 32'h0;
                ar_tr.fifo_empty = vif.rd_empty;
                ar_tr.fifo_full  = vif.rd_full;
                pending_axi_read = 1'b1;
            end

            if (pending_axi_read && vif.rvalid && vif.rready) begin
                ar_tr.observed_data = vif.rdata;
                ar_tr.resp          = vif.rresp;
                `uvm_info("Monitor", $sformatf("Sampled an AXI read transaction: addr=0x%0h observed_data=0x%0h rresp=0x%0h", ar_tr.addr, ar_tr.observed_data, ar_tr.resp), UVM_NONE)
                monitor_port.write(ar_tr);
                pending_axi_read = 1'b0;
            end
        end
    endtask

    task sample_periph_read();
        forever begin
            @(posedge vif.clk_periph);
            if (vif.rd_en && vif.rd_valid) begin
                tr = transaction::type_id::create("mon_periph_read_tr", this);
                tr.kind        = PERIPH_READ;
                tr.addr        = 4'h0;  // Peripheral reads only mirror FIFO data reads
                tr.data        = 32'h0;
                tr.observed_data = vif.rd_data;
                tr.fifo_empty  = vif.rd_empty;
                tr.fifo_full   = vif.rd_full;

                `uvm_info("Monitor", $sformatf("Sampled a peripheral read transaction: observed_data=0x%0h", tr.observed_data), UVM_NONE)
                monitor_port.write(tr);
            end
        end
    endtask

endclass
