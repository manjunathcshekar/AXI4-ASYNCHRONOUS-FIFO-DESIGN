class rand_test extends uvm_test;
    `uvm_component_utils(rand_test)

    env environment;
    // ? STEP 9: Declare sequences

    function new(string name = "rand_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Rand Test", "Constructed Rand Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Rand Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        dummy_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = dummy_seq::type_id::create("seq");
        seq.set_no_of_tr(4);

        // preload expected data for scoreboard
        environment.scoreboard.add_expected(32'hDEAD_BEEF);
        environment.scoreboard.add_expected(32'hFEED_CAFE);

        seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass


