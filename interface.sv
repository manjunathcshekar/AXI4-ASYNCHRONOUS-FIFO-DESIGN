interface intf ();
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
    logic [31:0] wdata;
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
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready;

    // Peripheral read side
    logic        rd_en;
    logic [31:0] rd_data;
    logic        rd_valid;
    logic        rd_empty;
    logic        rd_full;

    // Driver modport: drives requests, receives handshakes
    modport drv_mp (
        input  clk_axi, clk_periph, axi_resetn,
        input  awready, wready, bresp, bvalid,
        input  arready, rdata, rresp, rvalid,
        input  rd_valid, rd_data, rd_empty, rd_full,
        output awaddr, awvalid, wdata, wstrb, wvalid, bready,
        output araddr, arvalid, rready,
        output rd_en
    );

    // Monitor modport: observe everything
    modport mon_mp (
        input clk_axi, clk_periph, axi_resetn,
        input awaddr, awvalid, awready,
        input wdata, wstrb, wvalid, wready,
        input bresp, bvalid, bready,
        input araddr, arvalid, arready,
        input rdata, rresp, rvalid, rready,
        input rd_en, rd_data, rd_valid, rd_empty, rd_full
    );
endinterface : intf
