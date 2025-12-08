typedef enum {WRITE, PERIPH_READ} txn_kind_e;

class transaction extends uvm_sequence_item;
    `uvm_object_utils(transaction)

    rand txn_kind_e kind;
    rand bit [3:0]  addr;
    rand bit [31:0] data;

    // captured data for monitor
    bit [31:0] observed_data;

    constraint c_addr { addr inside {4'h0, 4'h4}; }

    function new(string name = "transaction");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal("DO_COPY", "Type mismatch in do_copy")
        end
        super.do_copy(rhs);
        kind          = rhs_.kind;
        addr          = rhs_.addr;
        data          = rhs_.data;
        observed_data = rhs_.observed_data;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal("DO_COMPARE", "Type mismatch in do_compare")
        end
        return (kind == rhs_.kind) &&
               (addr == rhs_.addr) &&
               (data == rhs_.data) &&
               (observed_data == rhs_.observed_data);
    endfunction

    function string convert2string();
        return $sformatf("kind=%s addr=0x%0h data=0x%0h observed=0x%0h",
                         kind.name(), addr, data, observed_data);
    endfunction

    function void do_print(uvm_printer printer);
        super.do_print(printer);
        `uvm_info("TRANSACTION", convert2string(), UVM_LOW)
    endfunction

endclass
