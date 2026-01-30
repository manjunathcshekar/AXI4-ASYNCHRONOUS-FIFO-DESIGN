class scb extends uvm_scoreboard;
    `uvm_component_utils(scb)

    // ? STEP 7: Change the analysis imp port if you want
    uvm_analysis_imp #(transaction, scb) scoreboard_port;
    transaction trs[$];
    transaction tr;
    int i = 0;

    // Declare variables which may be needed to make comparison
    bit [31:0] expected_q[$];
    function void add_expected(bit [31:0] data);
        expected_q.push_back(data);
    endfunction

    function new(string name = "scb", uvm_component parent);
        super.new(name, parent);
        `uvm_info("Scoreboard", "Constructed scoreboard", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("Scoreboard", "Build phase scoreboard", UVM_HIGH)
        // change the analysis imp port name here as well
        scoreboard_port = new("scoreboard_port", this);
    endfunction

    function void compare(transaction tr);
        bit [31:0] exp;
        if (expected_q.size() == 0) begin
            `uvm_error("Scoreboard", $sformatf("No expected data for observed 0x%0h", tr.observed_data))
            return;
        end
        exp = expected_q.pop_front();
        if (tr.observed_data !== exp) begin
            `uvm_error("Scoreboard", $sformatf("Data mismatch exp=0x%0h got=0x%0h", exp, tr.observed_data))
        end else begin
            `uvm_info("Scoreboard", $sformatf("Data match exp=0x%0h", exp), UVM_LOW)
        end
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("Scoreboard", "Run phase scoreboard", UVM_HIGH)
        tr = transaction::type_id::create("item", this);
        forever begin
            wait (!(trs.size() == 0));
            tr = trs.pop_front();
            i++;
            tr.print();
            compare(tr);
            `uvm_info("Tr count", $sformatf("Tr count = %d", i), UVM_NONE)
        end
    endtask

    function void write(transaction tr);
        trs.push_back(tr);
        `uvm_info("Scoreboard", "Write method Scoreboard", UVM_HIGH)
    endfunction

endclass

