class full_write_full_read_test extends uvm_test;
    `uvm_component_utils(full_write_full_read_test)

    env environment;
    virtual intf.mon_mp mon_vif;

    function new(string name = "full_write_full_read_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("FWFR Test", "Constructed full_write_full_read_test", UVM_HIGH)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        environment = env::type_id::create("env", this);
        if (!(uvm_config_db#(virtual intf.mon_mp)::get(this, "", "vif", mon_vif)))
            `uvm_fatal("FWFR Test", "Couldn't get mon_vif")
    endfunction

    task run_phase(uvm_phase phase);
        full_write_full_read_seq seq;
        uvm_event ev_write_done;
        uvm_event ev_read_done;

        super.run_phase(phase);
        phase.raise_objection(this);

        seq = full_write_full_read_seq::type_id::create("seq");
        ev_write_done = uvm_event_pool::get_global("FWFR_WRITE_DONE");
        ev_read_done  = uvm_event_pool::get_global("FWFR_READ_DONE");

        // preload expected data for scoreboard (8 writes -> 8 reads)
        for (int i = 0; i < 8; i++) begin
            environment.scoreboard.add_expected(32'hF00D_0000 + i);
        end

        fork
            seq.start(environment.agent.sequencer);
            begin
                ev_write_done.wait_trigger();
                // allow flag to settle
                repeat (2) @(posedge mon_vif.clk_periph);
                if (mon_vif.rd_full !== 1'b1)
                    `uvm_error("FWFR Test", $sformatf("Expected FIFO FULL=1 after fill, got %0b", mon_vif.rd_full))
            end
            begin
                ev_read_done.wait_trigger();
                // allow empty to settle
                repeat (2) @(posedge mon_vif.clk_periph);
                if (mon_vif.rd_empty !== 1'b1)
                    `uvm_error("FWFR Test", $sformatf("Expected FIFO EMPTY=1 after drain, got %0b", mon_vif.rd_empty))
            end
        join

        #500ns;
        phase.drop_objection(this);
    endtask

endclass

