// Boundary Condition Test
// Tests edge cases and corner scenarios

class boundary_condition_test extends uvm_test;
    `uvm_component_utils(boundary_condition_test)

    env environment;

    function new(string name = "boundary_condition_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Boundary Condition Test", "Constructed Boundary Condition Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Boundary Condition Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        boundary_condition_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = boundary_condition_seq::type_id::create("seq");
        seq.set_stress_count(20);  // 20 stress iterations

        `uvm_info("BOUNDARY_TEST", "Starting boundary condition test with edge case scenarios", UVM_HIGH)
        seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass
