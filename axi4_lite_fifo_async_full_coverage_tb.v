`timescale 1ns / 1ps

module axi4_lite_fifo_async_tb #(
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 32,
    parameter int FIFO_DEPTH = 8
);

    // Clocks & reset
    reg wr_clk;
    reg rd_clk;
    reg S_AXI_ARESETN;

    // AXI write address channel
    reg  [ADDR_WIDTH-1:0] S_AXI_AWADDR;
    reg                   S_AXI_AWVALID;
    wire                  S_AXI_AWREADY;

    // AXI write data channel
    reg  [DATA_WIDTH-1:0] S_AXI_WDATA;
    reg  [3:0]            S_AXI_WSTRB;
    reg                   S_AXI_WVALID;
    wire                  S_AXI_WREADY;

    // AXI write response channel
    wire [1:0]            S_AXI_BRESP;
    wire                  S_AXI_BVALID;
    reg                   S_AXI_BREADY;

    // AXI read address channel
    reg  [ADDR_WIDTH-1:0] S_AXI_ARADDR;
    reg                   S_AXI_ARVALID;
    wire                  S_AXI_ARREADY;

    // AXI read data channel
    wire [DATA_WIDTH-1:0] S_AXI_RDATA;
    wire [1:0]            S_AXI_RRESP;
    wire                  S_AXI_RVALID;
    reg                   S_AXI_RREADY;

    // Peripheral read interface
    reg                   rd_en;
    wire [DATA_WIDTH-1:0] rd_data;
    wire                  rd_valid;
    wire                  rd_empty;
    wire                  rd_full;
    // Interrupts
    reg                   irq_clear_full;
    reg                   irq_clear_empty;
    wire                  irq_full;
    wire                  irq_empty;

    // ----------------------------------------------------------------
    // DUT instantiation
    // ----------------------------------------------------------------
    // Note: DUT module name is axi_lite_async_fifo (without the "4" after axi)
    axi_lite_async_fifo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        // Clock & reset
        .clk_axi        (wr_clk),
        .clk_periph     (rd_clk),
        .axi_resetn_i   (S_AXI_ARESETN),

        // AXI write address
        .axi_awaddr_i   (S_AXI_AWADDR),
        .axi_awvalid_i  (S_AXI_AWVALID),
        .axi_awready_o  (S_AXI_AWREADY),

        // AXI write data
        .axi_wdata_i    (S_AXI_WDATA),
        .axi_wstrb_i    (S_AXI_WSTRB),
        .axi_wvalid_i   (S_AXI_WVALID),
        .axi_wready_o   (S_AXI_WREADY),

        // AXI write response
        .axi_bresp_o    (S_AXI_BRESP),
        .axi_bvalid_o   (S_AXI_BVALID),
        .axi_bready_i   (S_AXI_BREADY),

        // AXI read address
        .axi_araddr_i   (S_AXI_ARADDR),
        .axi_arvalid_i  (S_AXI_ARVALID),
        .axi_arready_o  (S_AXI_ARREADY),

        // AXI read data/resp
        .axi_rdata_o    (S_AXI_RDATA),
        .axi_rresp_o    (S_AXI_RRESP),
        .axi_rvalid_o   (S_AXI_RVALID),
        .axi_rready_i   (S_AXI_RREADY),

        // Peripheral read side
        .periph_rd_en_i (rd_en),
        .periph_rdata_o (rd_data),
        .periph_rvalid_o(rd_valid),
        .periph_empty_o (rd_empty),
        .periph_full_o  (rd_full),

        // Interrupts
        .irq_clear_full_i  (irq_clear_full),
        .irq_clear_empty_i (irq_clear_empty),
        .irq_full_o        (irq_full),
        .irq_empty_o       (irq_empty)
    );

    // ----------------------------------------------------------------
    // Clock generation
    // ----------------------------------------------------------------
    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk;   // 100 MHz
    end

    initial begin
        rd_clk = 0;
        forever #7 rd_clk = ~rd_clk;   // ~71 MHz
    end

    // ----------------------------------------------------------------
    // Reset
    // ----------------------------------------------------------------
    initial begin
        S_AXI_ARESETN = 0;
        #50;
        S_AXI_ARESETN = 1;
    end

    // ----------------------------------------------------------------
    // AXI Write Task (single-beat write)
    // ----------------------------------------------------------------
    task automatic axi_write(
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] data
    );
        integer timeout;
    begin
        @(posedge wr_clk);
        S_AXI_AWADDR  <= addr;
        S_AXI_AWVALID <= 1'b1;
        S_AXI_WDATA   <= data;
        S_AXI_WSTRB   <= 4'hF;
        S_AXI_WVALID  <= 1'b1;

        // Wait until both AWREADY and WREADY are asserted
        timeout = 0;
        while (!(S_AXI_AWREADY && S_AXI_WREADY)) begin
            @(posedge wr_clk);
            timeout = timeout + 1;
            if (timeout > 1000) begin
                $error("TIMEOUT: AWREADY/WREADY handshake did not complete");
                disable axi_write;
            end
        end

        // Deassert AWVALID/WVALID
        S_AXI_AWVALID <= 1'b0;
        S_AXI_WVALID  <= 1'b0;

        // Accept B response
        S_AXI_BREADY <= 1'b1;
        timeout = 0;
        while (!S_AXI_BVALID) begin
            @(posedge wr_clk);
            timeout = timeout + 1;
            if (timeout > 1000) begin
                $error("TIMEOUT: BVALID not asserted");
                disable axi_write;
            end
        end

        $display("[%0t] AXI WRITE: addr=0x%0h data=0x%0h BRESP=0x%0h",
                 $time, addr, data, S_AXI_BRESP);

        S_AXI_BREADY <= 1'b0;
        @(posedge wr_clk);
    end
    endtask

    // ----------------------------------------------------------------
    // AXI Read Task (status / peek)
    // ----------------------------------------------------------------
    task automatic axi_read(
        input  [ADDR_WIDTH-1:0] addr,
        output [DATA_WIDTH-1:0] data,
        output [1:0]            resp
    );
        integer timeout;
    begin
        @(posedge wr_clk);
        S_AXI_ARADDR  <= addr;
        S_AXI_ARVALID <= 1'b1;

        // Wait for ARREADY
        timeout = 0;
        while (!S_AXI_ARREADY) begin
            @(posedge wr_clk);
            timeout = timeout + 1;
            if (timeout > 1000) begin
                $error("TIMEOUT: ARREADY not asserted");
                disable axi_read;
            end
        end

        S_AXI_ARVALID <= 1'b0;

        // Wait for RVALID
        S_AXI_RREADY <= 1'b1;
        timeout = 0;
        while (!S_AXI_RVALID) begin
            @(posedge wr_clk);
            timeout = timeout + 1;
            if (timeout > 1000) begin
                $error("TIMEOUT: RVALID not asserted");
                disable axi_read;
            end
        end

        data = S_AXI_RDATA;
        resp = S_AXI_RRESP;

        $display("[%0t] AXI READ : addr=0x%0h data=0x%0h RRESP=0x%0h",
                 $time, addr, data, resp);

        S_AXI_RREADY <= 1'b0;
        @(posedge wr_clk);
    end
    endtask

    // ----------------------------------------------------------------
    // Peripheral Read Task
    // ----------------------------------------------------------------
    task automatic periph_read(
        output [DATA_WIDTH-1:0] data
    );
        integer timeout;
    begin
        // Wait until FIFO not empty
        timeout = 0;
        while (rd_empty) begin
            @(posedge rd_clk);
            timeout = timeout + 1;
            if (timeout > 1000) begin
                $error("TIMEOUT: FIFO stayed empty before peripheral read");
                disable periph_read;
            end
        end

        // Pulse rd_en for one rd_clk cycle
        @(posedge rd_clk);
        rd_en <= 1'b1;
        @(posedge rd_clk);
        rd_en <= 1'b0;

        // Wait for rd_valid
        timeout = 0;
        while (!rd_valid) begin
            @(posedge rd_clk);
            timeout = timeout + 1;
            if (timeout > 1000) begin
                $error("TIMEOUT: rd_valid not asserted after rd_en");
                disable periph_read;
            end
        end

        data = rd_data;
        $display("[%0t] PERIPH READ: data=0x%0h", $time, data);
    end
    endtask

    // ----------------------------------------------------------------
    // Test sequence
    // ----------------------------------------------------------------
    reg [DATA_WIDTH-1:0] axi_rdata;
    reg [1:0]            axi_rresp;
    reg [DATA_WIDTH-1:0] periph_data;

    initial begin
        // Initial values
        S_AXI_AWADDR  = 0;
        S_AXI_AWVALID = 0;
        S_AXI_WDATA   = 0;
        S_AXI_WSTRB   = 0;
        S_AXI_WVALID  = 0;
        S_AXI_BREADY  = 0;
        S_AXI_ARADDR  = 0;
        S_AXI_ARVALID = 0;
        S_AXI_RREADY  = 0;
        rd_en         = 0;
        irq_clear_full  = 1'b0;
        irq_clear_empty = 1'b0;

        // Wait for reset deassert
        wait (S_AXI_ARESETN == 1);
        @(posedge wr_clk);
        $display("\n=== Starting AXI4-Lite Async FIFO Testbench ===");

        // ------------------------------------------------------------
        // 1. Write two words via AXI
        // ------------------------------------------------------------
        axi_write(4'h0, 32'hDEAD_BEEF);
        axi_write(4'h0, 32'hFEED_CAFE);

        // ------------------------------------------------------------
        // 2. AXI peek (0x4) before peripheral reads
        // ------------------------------------------------------------
        axi_read(4'h4, axi_rdata, axi_rresp); // peek head
        if (axi_rresp == 2'b00 && axi_rdata !== 32'hDEAD_BEEF) begin
            $error("PEEK MISMATCH: expected 0xDEAD_BEEF, got 0x%0h", axi_rdata);
        end

        // ------------------------------------------------------------
        // 3. Peripheral reads out the two entries
        // ------------------------------------------------------------
        periph_read(periph_data);
        if (periph_data !== 32'hDEAD_BEEF)
            $error("PERIPH READ #1 mismatch: expected 0xDEAD_BEEF, got 0x%0h", periph_data);

        periph_read(periph_data);
        if (periph_data !== 32'hFEED_CAFE)
            $error("PERIPH READ #2 mismatch: expected 0xFEED_CAFE, got 0x%0h", periph_data);

        // ------------------------------------------------------------
        // 4. AXI status read at 0x0 (should show empty)
        // ------------------------------------------------------------
        axi_read(4'h0, axi_rdata, axi_rresp); // status
        $display("Status word after draining FIFO = 0x%0h (LSB=empty flag)", axi_rdata);

        // ------------------------------------------------------------
        // 5. AXI peek on empty FIFO (expect SLVERR)
        // ------------------------------------------------------------
        axi_read(4'h4, axi_rdata, axi_rresp);
        if (axi_rresp != 2'b10)
            $error("Expected SLVERR on peek when empty, got RRESP=0x%0h", axi_rresp);

        $display("\n=== BASIC TEST COMPLETED ===\n");

        #200;
        $finish;
    end

endmodule
