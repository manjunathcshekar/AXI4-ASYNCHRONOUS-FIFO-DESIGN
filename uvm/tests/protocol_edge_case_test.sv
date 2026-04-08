// Protocol Edge Case Test
// AXI protocol boundary condition testing

class protocol_edge_case_test extends uvm_test;
    `uvm_component_utils(protocol_edge_case_test)

    env environment;

    function new(string name = "protocol_edge_case_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Protocol Edge Case Test", "Constructed Protocol Edge Case Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Protocol Edge Case Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        protocol_edge_case_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = protocol_edge_case_seq::type_id::create("seq");
        seq.set_num_cases(32);

        `uvm_info("PROTO_TEST", "Starting protocol edge case test", UVM_HIGH)
        seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass
