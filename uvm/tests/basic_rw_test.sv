class basic_rw_test extends uvm_test;
    `uvm_component_utils(basic_rw_test)

    env environment;

    function new(string name = "basic_rw_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Basic RW Test", "Constructed Basic RW Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Basic RW Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        basic_rw_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = basic_rw_seq::type_id::create("seq");

        // Preload expected data for scoreboard (data written will be read back)
        environment.scoreboard.add_expected(32'hA5A5A5A5);

        seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass

