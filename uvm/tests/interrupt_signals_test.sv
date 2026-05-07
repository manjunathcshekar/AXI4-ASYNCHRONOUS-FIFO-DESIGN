// Interrupt Signals Test
// Comprehensive interrupt signal testing

class interrupt_signals_test extends uvm_test;
    `uvm_component_utils(interrupt_signals_test)

    env environment;

    function new(string name = "interrupt_signals_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Interrupt Signals Test", "Constructed Interrupt Signals Test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Interrupt Signals Test", "Build phase environment", UVM_HIGH)
        environment = env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        interrupt_signals_seq seq;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = interrupt_signals_seq::type_id::create("seq");
        seq.set_num_iterations(64);

        `uvm_info("INT_TEST", "Starting interrupt signals comprehensive test", UVM_HIGH)
        seq.start(environment.agent.sequencer);

        #500ns;

        phase.drop_objection(this);
    endtask

endclass
