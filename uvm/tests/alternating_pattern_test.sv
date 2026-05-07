// Alternating Pattern Test
// Tests state machine transitions with variable timing

class alternating_pattern_test extends uvm_test;
    `uvm_component_utils(alternating_pattern_test)

    env environment;

    function new(string name = "alternating_pattern_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Alternating Pattern Test", "Constructed Alternating Pattern Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Alternating Pattern Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        alternating_pattern_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = alternating_pattern_seq::type_id::create("seq");
        seq.set_num_pairs(32);  // 32 read-write pair variations

        `uvm_info("ALT_PATTERN_TEST", "Starting alternating pattern test with variable timing", UVM_HIGH)
        seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass
