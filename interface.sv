interface intf #(
    parameter int DATA_WIDTH = 32,
    parameter int FIFO_DEPTH = 8  // kept for potential reuse/coverage alignment
)();
    timeunit 1ns; timeprecision 1ps;
    // Clocks and reset
    logic clk_axi;
    logic clk_periph;
    logic axi_resetn;

    // AXI write address channel
    logic [3:0]  awaddr;
    logic        awvalid;
    logic        awready;

    // AXI write data channel
    logic [DATA_WIDTH-1:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    logic        wready;

    // AXI write response channel
    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;

    // AXI read address channel (status/peek)
    logic [3:0]  araddr;
    logic        arvalid;
    logic        arready;

    // AXI read data channel
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready;

    // Peripheral read side
    logic        rd_en;
    logic [DATA_WIDTH-1:0] rd_data;
    logic        rd_valid;
    logic        rd_empty;
    logic        rd_full;
    // Interrupt signals (passive observation + optional clears)
    logic        irq_full;
    logic        irq_empty;
    logic        irq_clear_full;
    logic        irq_clear_empty;

    // Driver modport: drives requests, receives handshakes
    modport drv_mp (
        input  clk_axi, clk_periph, axi_resetn,
        input  awready, wready, bresp, bvalid,
        input  arready, rdata, rresp, rvalid,
        input  rd_valid, rd_data, rd_empty, rd_full,
        input  irq_full, irq_empty,
        output awaddr, awvalid, wdata, wstrb, wvalid, bready,
        output araddr, arvalid, rready,
        output rd_en,
        output irq_clear_full, irq_clear_empty
    );

    // Monitor modport: observe everything
    modport mon_mp (
        input clk_axi, clk_periph, axi_resetn,
        input awaddr, awvalid, awready,
        input wdata, wstrb, wvalid, wready,
        input bresp, bvalid, bready,
        input araddr, arvalid, arready,
        input rdata, rresp, rvalid, rready,
        input rd_en, rd_data, rd_valid, rd_empty, rd_full,
        input irq_full, irq_empty, irq_clear_full, irq_clear_empty
    );
endinterface : intf
