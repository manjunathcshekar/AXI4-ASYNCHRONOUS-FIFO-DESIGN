// Stress Load Test
// High-volume transaction stress testing

class stress_load_test extends uvm_test;
    `uvm_component_utils(stress_load_test)

    env environment;

    function new(string name = "stress_load_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Stress Load Test", "Constructed Stress Load Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Stress Load Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        stress_load_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = stress_load_seq::type_id::create("seq");
        seq.set_num_transactions(500);  // Very high volume

        `uvm_info("STRESS_TEST", "Starting stress load test with 500 transactions", UVM_HIGH)
        seq.start(environment.agent.sequencer);

        #1000ns;

        phase.drop_objection(this);
    endtask

endclass
