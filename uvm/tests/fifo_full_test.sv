class fifo_full_test extends uvm_test;
    `uvm_component_utils(fifo_full_test)

    env environment;

    function new(string name = "fifo_full_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("FIFO Full Test", "Constructed FIFO Full Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("FIFO Full Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_full_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = fifo_full_seq::type_id::create("seq");

        // Preload expected data for scoreboard (only the first 8 writes will be readable)
        // Note: The overflow write should result in SLVERR, not data corruption
        for (int i = 0; i < 8; i++) begin
            environment.scoreboard.add_expected(32'h1000 + i);
        end

        seq.start(environment.agent.sequencer);

        #1000ns;  // Allow time for all writes and overflow handling

        phase.drop_objection(this);
    endtask

endclass

