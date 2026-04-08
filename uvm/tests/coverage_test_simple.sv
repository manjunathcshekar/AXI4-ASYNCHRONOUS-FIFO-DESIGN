// ============================================================
// SIMPLIFIED COVERAGE TEST
// ============================================================
// Runs existing sequences with coverage collection enabled

class coverage_test extends uvm_test;
    `uvm_component_utils(coverage_test)
    
    env environment;
    axi4_fifo_coverage cov;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        environment = env::type_id::create("environment", this);
        cov = axi4_fifo_coverage::type_id::create("cov", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect coverage subscriber to monitor's analysis port
        if (environment.agent.monitor.monitor_port != null) begin
            environment.agent.monitor.monitor_port.connect(cov.analysis_export);
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        basic_rw_seq basic_seq;
        continuous_rw_seq cont_seq;
        fifo_full_seq full_seq;
        fifo_empty_seq empty_seq;
        
        phase.raise_objection(this);
        
        `uvm_info("coverage_test", "Starting coverage collection test...", UVM_LOW)
        
        // Sequence 1: Basic read-write (exercises address 0x0)
        basic_seq = basic_rw_seq::type_id::create("basic_seq");
        `uvm_info("coverage_test", "Running basic_rw_seq for coverage...", UVM_LOW)
        basic_seq.start(environment.agent.sequencer);
        
        // Sequence 2: Full write then full read
        full_seq = fifo_full_seq::type_id::create("full_seq");
        `uvm_info("coverage_test", "Running fifo_full_seq for coverage...", UVM_LOW)
        full_seq.start(environment.agent.sequencer);
        
        // Sequence 3: Empty read  attempt
        empty_seq = fifo_empty_seq::type_id::create("empty_seq");
        `uvm_info("coverage_test", "Running fifo_empty_seq for coverage...", UVM_LOW)
        empty_seq.start(environment.agent.sequencer);
        
        // Sequence 4: Continuous operations (many writes and reads)
        cont_seq = continuous_rw_seq::type_id::create("cont_seq");
        `uvm_info("coverage_test", "Running continuous_rw_seq for coverage...", UVM_LOW)
        cont_seq.start(environment.agent.sequencer);
        
        #100ns;
        
        `uvm_info("coverage_test", "====================================", UVM_LOW)
        `uvm_info("coverage_test", "COVERAGE TEST COMPLETED SUCCESSFULLY!", UVM_LOW)
        `uvm_info("coverage_test", "====================================", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
    
endclass : coverage_test
