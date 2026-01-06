import uvm_pkg::*;
import axi4_uvm_pkg::*;

module tb ();
    timeunit 1ns; timeprecision 1ps;

    logic clk_axi;
    logic clk_periph;
    logic axi_resetn;

    initial begin
        clk_axi = 0;
        forever #5 clk_axi = ~clk_axi; // 100 MHz
    end

    initial begin
        clk_periph = 0;
        forever #7 clk_periph = ~clk_periph; // ~71 MHz
    end

    initial begin
        axi_resetn = 0;
        #50;
        axi_resetn = 1;
    end

    intf vif ();

    // connect clocks/reset into the interface
    assign vif.clk_axi    = clk_axi;
    assign vif.clk_periph = clk_periph;
    assign vif.axi_resetn = axi_resetn;
    assign vif.irq_clear_full  = 1'b0;
    assign vif.irq_clear_empty = 1'b0;

    // DUT
    axi_lite_async_fifo #(
        .ADDR_WIDTH(4),
        .DATA_WIDTH(32),
        .FIFO_DEPTH(8)
    ) dut (
        .clk_axi        (clk_axi),
        .clk_periph     (clk_periph),
        .axi_resetn_i   (axi_resetn),
        .axi_awaddr_i   (vif.awaddr),
        .axi_awvalid_i  (vif.awvalid),
        .axi_awready_o  (vif.awready),
        .axi_wdata_i    (vif.wdata),
        .axi_wstrb_i    (vif.wstrb),
        .axi_wvalid_i   (vif.wvalid),
        .axi_wready_o   (vif.wready),
        .axi_bresp_o    (vif.bresp),
        .axi_bvalid_o   (vif.bvalid),
        .axi_bready_i   (vif.bready),
        .axi_araddr_i   (vif.araddr),
        .axi_arvalid_i  (vif.arvalid),
        .axi_arready_o  (vif.arready),
        .axi_rdata_o    (vif.rdata),
        .axi_rresp_o    (vif.rresp),
        .axi_rvalid_o   (vif.rvalid),
        .axi_rready_i   (vif.rready),
        .periph_rd_en_i (vif.rd_en),
        .periph_rdata_o (vif.rd_data),
        .periph_rvalid_o(vif.rd_valid),
        .periph_empty_o (vif.rd_empty),
        .periph_full_o  (vif.rd_full),
        .irq_clear_full_i  (vif.irq_clear_full),
        .irq_clear_empty_i (vif.irq_clear_empty),
        .irq_full_o        (vif.irq_full),
        .irq_empty_o       (vif.irq_empty)
    );

    initial begin
        uvm_config_db#(virtual intf.drv_mp)::set(null, "*", "vif", vif);
        uvm_config_db#(virtual intf.mon_mp)::set(null, "*", "vif", vif);
        run_test("rand_test");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule
