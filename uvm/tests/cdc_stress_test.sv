// CDC Stress Test
// Tests Clock Domain Crossing synchronization under stress

class cdc_stress_test extends uvm_test;
    `uvm_component_utils(cdc_stress_test)

    env environment;

    function new(string name = "cdc_stress_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("CDC Stress Test", "Constructed CDC Stress Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("CDC Stress Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        cdc_stress_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = cdc_stress_seq::type_id::create("seq");
        seq.set_num_cycles(100);  // 100 CDC cycles

        `uvm_info("CDC_STRESS_TEST", "Starting CDC stress test with rapid synchronizer exercise", UVM_HIGH)
        seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass
