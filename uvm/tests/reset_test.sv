class reset_test extends uvm_test;
    `uvm_component_utils(reset_test)

    env environment;
    virtual intf.rst_mp rst_vif;
    virtual intf.mon_mp mon_vif;

    function new(string name = "reset_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Reset Test", "Constructed Reset Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Reset Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);

        if (!(uvm_config_db#(virtual intf.rst_mp)::get(this, "", "rst_vif", rst_vif)))
            `uvm_fatal("Reset Test", "Couldn't get rst_vif")
        if (!(uvm_config_db#(virtual intf.mon_mp)::get(this, "", "vif", mon_vif)))
            `uvm_fatal("Reset Test", "Couldn't get mon_vif")
    endfunction

    task run_phase(uvm_phase phase);
        reset_seq seq;
        reset_check_seq check_seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = reset_seq::type_id::create("seq");
        check_seq = reset_check_seq::type_id::create("check_seq");

        // Start traffic, then assert reset in the middle
        fork
            seq.start(environment.agent.sequencer);
            begin
                // wait a bit so writes are in-flight
                #60ns;
                rst_vif.axi_resetn = 1'b0;
                repeat (8) @(posedge rst_vif.clk_axi);
                rst_vif.axi_resetn = 1'b1;
            end
        join

        // Allow CDC to settle, then check reset state
        repeat (4) @(posedge mon_vif.clk_periph);
        if (mon_vif.rd_empty !== 1'b1)
            `uvm_error("Reset Test", $sformatf("Expected FIFO EMPTY=1 after reset, got %0b", mon_vif.rd_empty))
        if (mon_vif.rd_full !== 1'b0)
            `uvm_error("Reset Test", $sformatf("Expected FIFO FULL=0 after reset, got %0b", mon_vif.rd_full))

        // Post-reset checks:
        // - attempt a read after reset (should be blocked if empty)
        // - write then read one item after reset (scoreboard must match)
        environment.scoreboard.add_expected(32'hCAFE_BABE);
        check_seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass

