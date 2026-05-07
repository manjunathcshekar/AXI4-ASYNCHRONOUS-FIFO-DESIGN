class continuous_rw_test extends uvm_test;
    `uvm_component_utils(continuous_rw_test)

    env environment;
    virtual intf.mon_mp mon_vif;

    function new(string name = "continuous_rw_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Continuous RW Test", "Constructed continuous_rw_test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        environment = env::type_id::create("env", this);
        if (!(uvm_config_db#(virtual intf.mon_mp)::get(this, "", "vif", mon_vif)))
            `uvm_fatal("Continuous RW Test", "Couldn't get mon_vif")
    endfunction

    task run_phase(uvm_phase phase);
        continuous_rw_seq seq;
        int iters;

        super.run_phase(phase);
        phase.raise_objection(this);

        iters = 50;
        seq = continuous_rw_seq::type_id::create("seq");
        seq.set_num_iters(iters);

        // preload expected data for scoreboard (one read per write)
        for (int i = 0; i < iters; i++) begin
            environment.scoreboard.add_expected(32'hC0DE_0000 + i);
        end

        seq.start(environment.agent.sequencer);

        // end-state sanity: FIFO should be empty after balanced write/read
        repeat (4) @(posedge mon_vif.clk_periph);
        if (mon_vif.rd_empty !== 1'b1)
            `uvm_error("Continuous RW Test", $sformatf("Expected FIFO EMPTY=1 at end, got %0b", mon_vif.rd_empty))

        #500ns;
        phase.drop_objection(this);
    endtask

endclass

