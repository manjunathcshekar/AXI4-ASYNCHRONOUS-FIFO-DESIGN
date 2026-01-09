class reset_test extends uvm_test;
    `uvm_component_utils(reset_test)

    env environment;

    function new(string name = "reset_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Reset Test", "Constructed Reset Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Reset Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        reset_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = reset_seq::type_id::create("seq");

        // Preload expected data for scoreboard (data written before reset)
        // Note: Reset behavior verification is primarily through signal observation
        // Scoreboard may not capture all data if reset interrupts transactions
        for (int i = 0; i < 3; i++) begin
            environment.scoreboard.add_expected(32'h1111_1111 + i);
        end

        seq.start(environment.agent.sequencer);

        // Allow time for transactions and reset recovery
        #1000ns;

        phase.drop_objection(this);
    endtask

endclass

