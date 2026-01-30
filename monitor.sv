class mon extends uvm_monitor;
    `uvm_component_utils(mon)

    virtual intf.mon_mp vif;
    transaction tr;

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

        forever begin
            sample ();
        end

    endtask

    task sample ();
        // Wait for a valid read handshake: rd_en and rd_valid both asserted
        // This ensures we capture each read operation exactly once
        @(posedge vif.clk_periph);
        if (vif.rd_en && vif.rd_valid) begin
            tr = transaction::type_id::create("mon_tr", this);
            tr.kind = PERIPH_READ;
            tr.addr = 4'h0;  // Peripheral reads don't have explicit address, use default
            tr.data = 32'h0; // Original write data not available, use default
            tr.observed_data = vif.rd_data;
            
            `uvm_info("Monitor", $sformatf("Sampled a peripheral read transaction: observed_data=0x%0h", tr.observed_data), UVM_NONE)
            monitor_port.write(tr);
        end
    endtask


endclass
