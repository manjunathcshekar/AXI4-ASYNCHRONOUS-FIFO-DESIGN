// Burst Pattern Test
// Tests different addressing and burst patterns

class burst_pattern_test extends uvm_test;
    `uvm_component_utils(burst_pattern_test)

    env environment;

    function new(string name = "burst_pattern_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Burst Pattern Test", "Constructed Burst Pattern Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Burst Pattern Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        burst_pattern_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = burst_pattern_seq::type_id::create("seq");
        seq.set_burst_length(16);  // 16-transaction bursts

        `uvm_info("BURST_PATTERN_TEST", "Starting burst pattern test with varied addressing", UVM_HIGH)
        seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass
