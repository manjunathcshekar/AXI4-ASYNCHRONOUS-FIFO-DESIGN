class fifo_empty_test extends uvm_test;
    `uvm_component_utils(fifo_empty_test)

    env environment;

    function new(string name = "fifo_empty_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("FIFO Empty Test", "Constructed FIFO Empty Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("FIFO Empty Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_empty_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = fifo_empty_seq::type_id::create("seq");

        // Preload expected data for scoreboard
        // Note: First read on empty FIFO may not produce data (driver waits for !rd_empty)
        // Second read after write should succeed
        environment.scoreboard.add_expected(32'hBEEFCAFE);

        seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass

