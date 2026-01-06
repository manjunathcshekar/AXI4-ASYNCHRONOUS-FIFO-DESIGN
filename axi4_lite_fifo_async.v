`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// axi_lite_async_fifo.v
// -----------------------------------------------------------------------------
/*
  AXI4-Lite Async FIFO (Option A)
  - AXI slave logic runs in clk_axi domain (AW/W/B and AR/R for status/peek).
  - FIFO write side (producer) in clk_axi domain.
  - FIFO read side (consumer/peripheral) in clk_periph domain.
  - Gray-coded pointers + 2-flop synchronizers for safe CDC.
  - Peripheral reads via periph_rd_en_i and receives periph_rdata_o & periph_rvalid_o.
  - AXI AR at address 0x0 returns basic status (LSB = empty).
  - AXI AR at address 0x4 returns a non-destructive peek of the next element.
  - If FIFO is full when a write arrives, module returns BRESP = SLVERR (2'b10).
  - Author: ChatGPT (adapted for readability and teaching)
*/
module axi_lite_async_fifo #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8
)(
    // Clocks & reset
    input                       clk_axi,         // AXI/master clock domain
    input                       clk_periph,      // peripheral clock domain
    input                       axi_resetn_i,    // active-low reset (global)

    // -----------------------------
    // AXI4-Lite Write Address Channel (slave)
    // -----------------------------
    input  [ADDR_WIDTH-1:0]     axi_awaddr_i,
    input                       axi_awvalid_i,
    output reg                  axi_awready_o,

    // -----------------------------
    // AXI4-Lite Write Data Channel (slave)
    // -----------------------------
    input  [DATA_WIDTH-1:0]     axi_wdata_i,
    input  [3:0]                axi_wstrb_i,
    input                       axi_wvalid_i,
    output reg                  axi_wready_o,

    // -----------------------------
    // AXI4-Lite Write Response Channel (slave)
    // -----------------------------
    output reg [1:0]            axi_bresp_o,
    output reg                  axi_bvalid_o,
    input                       axi_bready_i,

    // -----------------------------
    // AXI4-Lite Read Address Channel (slave) - status/peek only
    // -----------------------------
    input  [ADDR_WIDTH-1:0]     axi_araddr_i,
    input                       axi_arvalid_i,
    output reg                  axi_arready_o,

    // -----------------------------
    // AXI4-Lite Read Data Channel (slave)
    // -----------------------------
    output reg [DATA_WIDTH-1:0] axi_rdata_o,
    output reg [1:0]            axi_rresp_o,
    output reg                  axi_rvalid_o,
    input                       axi_rready_i,

    // -----------------------------
    // Peripheral Read Interface (consumer) - periph domain
    // -----------------------------
    input                       periph_rd_en_i,    // peripheral requests a read (pulse or level)
    output reg [DATA_WIDTH-1:0] periph_rdata_o,
    output reg                  periph_rvalid_o,
    output                      periph_empty_o,
    output                      periph_full_o,

    // Interrupt outputs (optional/passive)
    input                       irq_clear_full_i,
    input                       irq_clear_empty_i,
    output                      irq_full_o,
    output                      irq_empty_o
);

    // -------------------------------------------------------------------------
    // Local params & pointer widths
    // -------------------------------------------------------------------------
    localparam PTR = $clog2(FIFO_DEPTH);        // number of address bits
    // pointers are PTR+1 bits wide to detect full condition by MSB flip
    // sanity note: FIFO_DEPTH should ideally be a power of two (recommended)

    // -------------------------------------------------------------------------
    // FIFO memory
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    // Binary pointers (PTR:0)
    reg [PTR:0] fifo_wr_ptr_bin_r;   // write pointer (binary) in clk_axi domain
    reg [PTR:0] fifo_rd_ptr_bin_r;   // read pointer (binary) in clk_periph domain

    // Gray pointers
    reg [PTR:0] fifo_wr_ptr_gray_r;  // write pointer gray (clk_axi)
    reg [PTR:0] fifo_rd_ptr_gray_r;  // read pointer gray (clk_periph)

    // Synchronizers (two flip-flops each direction)
    reg [PTR:0] fifo_rd_ptr_gray_sync_axi_1, fifo_rd_ptr_gray_sync_axi_2;   // rd->axi
    reg [PTR:0] fifo_wr_ptr_gray_sync_periph_1, fifo_wr_ptr_gray_sync_periph_2; // wr->periph

    // -------------------------------------------------------------------------
    // AXI write capture latches (to tolerate AW and W on different cycles)
    // -------------------------------------------------------------------------
    reg                     axi_aw_pending_r;
    reg [ADDR_WIDTH-1:0]    axi_awaddr_latched_r;

    reg                     axi_w_pending_r;
    reg [DATA_WIDTH-1:0]    axi_wdata_latched_r;

    // -------------------------------------------------------------------------
    // Helper wires: memory addresses (low PTR bits)
    // -------------------------------------------------------------------------
    wire [PTR-1:0] fifo_wr_addr_w = fifo_wr_ptr_bin_r[PTR-1:0];
    wire [PTR-1:0] fifo_rd_addr_w = fifo_rd_ptr_bin_r[PTR-1:0];

    // -------------------------------------------------------------------------
    // Binary <-> Gray conversion functions
    // -------------------------------------------------------------------------
    function [PTR:0] bin2gray;
        input [PTR:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    function [PTR:0] gray2bin;
        input [PTR:0] gray;
        integer i;
        begin
            gray2bin[PTR] = gray[PTR];
            for (i = PTR-1; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // -------------------------------------------------------------------------
    // Convert synchronized gray pointers back to binary for comparisons
    // (these are combinational conversions used in their respective clock domains)
    // -------------------------------------------------------------------------
    wire [PTR:0] fifo_rd_bin_sync_axi   = gray2bin(fifo_rd_ptr_gray_sync_axi_2);    // rd pointer synchronized into axi domain
    wire [PTR:0] fifo_wr_bin_sync_periph = gray2bin(fifo_wr_ptr_gray_sync_periph_2); // wr pointer synchronized into periph domain

    // next write pointer in binary (used for full detection in AXI domain)
    wire [PTR:0] fifo_wr_bin_next_w = fifo_wr_ptr_bin_r + 1'b1;

    // empty (in periph domain) and full (in axi domain) detection
    // fifo_full asserted in AXI domain when next write == read (synced)
    wire fifo_full_axi_w  = (fifo_wr_bin_next_w == fifo_rd_bin_sync_axi);

    // fifo_empty asserted in periph domain when read == write (synced)
    wire fifo_empty_periph_w = (fifo_rd_ptr_bin_r == fifo_wr_bin_sync_periph);
    // fifo_empty as seen in AXI domain (used for interrupt generation)
    wire fifo_empty_axi_w = (fifo_wr_ptr_bin_r == fifo_rd_bin_sync_axi);

    // expose status outputs
    assign periph_full_o  = fifo_full_axi_w;     // note: sampled in AXI domain semantics
    assign periph_empty_o = fifo_empty_periph_w; // periph domain logic uses this wire locally

    // -------------------------------------------------------------------------
    // Interrupt controller (clk_axi domain)
    // -------------------------------------------------------------------------
    fifo_interrupt_controller u_fifo_interrupt_controller (
        .clk             (clk_axi),
        .rst_n           (axi_resetn_i),
        .fifo_full       (fifo_full_axi_w),
        .fifo_empty      (fifo_empty_axi_w),
        .irq_clear_full  (irq_clear_full_i),
        .irq_clear_empty (irq_clear_empty_i),
        .irq_full        (irq_full_o),
        .irq_empty       (irq_empty_o)
    );

    // -------------------------------------------------------------------------
    // Pointer synchronizers (cross-domain)
    //   - write gray -> periph domain
    //   - read gray  -> axi domain
    // -------------------------------------------------------------------------
    // write Gray pointer -> periph domain (two FFs)
    always @(posedge clk_periph or negedge axi_resetn_i) begin
        if (!axi_resetn_i) begin
            fifo_wr_ptr_gray_sync_periph_1 <= { (PTR+1){1'b0} };
            fifo_wr_ptr_gray_sync_periph_2 <= { (PTR+1){1'b0} };
        end else begin
            fifo_wr_ptr_gray_sync_periph_1 <= fifo_wr_ptr_gray_r;
            fifo_wr_ptr_gray_sync_periph_2 <= fifo_wr_ptr_gray_sync_periph_1;
        end
    end

    // read Gray pointer -> axi domain (two FFs)
    always @(posedge clk_axi or negedge axi_resetn_i) begin
        if (!axi_resetn_i) begin
            fifo_rd_ptr_gray_sync_axi_1 <= { (PTR+1){1'b0} };
            fifo_rd_ptr_gray_sync_axi_2 <= { (PTR+1){1'b0} };
        end else begin
            fifo_rd_ptr_gray_sync_axi_1 <= fifo_rd_ptr_gray_r;
            fifo_rd_ptr_gray_sync_axi_2 <= fifo_rd_ptr_gray_sync_axi_1;
        end
    end

    // -------------------------------------------------------------------------
    // AXI Write logic (clk_axi domain)
    // - latch AW or W if they arrive separately
    // - support fast path (AW & W same cycle) and latched path
    // - generate BRESP OKAY or SLVERR when full
    // -------------------------------------------------------------------------
    always @(posedge clk_axi or negedge axi_resetn_i) begin
        if (!axi_resetn_i) begin
            // reset all AXI write-related registers
            axi_awready_o           <= 1'b0;
            axi_wready_o            <= 1'b0;
            axi_bvalid_o            <= 1'b0;
            axi_bresp_o             <= 2'b00;

            fifo_wr_ptr_bin_r       <= { (PTR+1){1'b0} };
            fifo_wr_ptr_gray_r      <= { (PTR+1){1'b0} };

            axi_aw_pending_r        <= 1'b0;
            axi_w_pending_r         <= 1'b0;
            axi_awaddr_latched_r    <= {ADDR_WIDTH{1'b0}};
            axi_wdata_latched_r     <= {DATA_WIDTH{1'b0}};
        end else begin
            // default ready behavior: accept AW/W if not already pending and no outstanding BVALID and not full
            axi_awready_o <= !axi_aw_pending_r && !axi_bvalid_o && !fifo_full_axi_w;
            axi_wready_o  <= !axi_w_pending_r  && !axi_bvalid_o && !fifo_full_axi_w;

            // capture AW when presented & accepted
            if (axi_awvalid_i && axi_awready_o) begin
                axi_aw_pending_r     <= 1'b1;
                axi_awaddr_latched_r <= axi_awaddr_i;
            end

            // capture W when presented & accepted
            if (axi_wvalid_i && axi_wready_o) begin
                axi_w_pending_r     <= 1'b1;
                axi_wdata_latched_r <= axi_wdata_i;
            end

            // Fast path: both AW & W provided this cycle & FIFO has room & no outstanding B
            if (axi_awvalid_i && axi_wvalid_i && !axi_bvalid_o && !fifo_full_axi_w) begin
                // write directly from inputs
                fifo_mem[fifo_wr_addr_w] <= axi_wdata_i;
                fifo_wr_ptr_bin_r <= fifo_wr_ptr_bin_r + 1'b1;
                fifo_wr_ptr_gray_r <= bin2gray(fifo_wr_ptr_bin_r + 1'b1);

                // ack via B channel
                axi_bvalid_o <= 1'b1;
                axi_bresp_o  <= 2'b00; // OKAY

                // clear any pending latches (defensive)
                axi_aw_pending_r <= 1'b0;
                axi_w_pending_r  <= 1'b0;
            end else begin
                // If latched AW & W are present and FIFO has room & no outstanding B
                if (axi_aw_pending_r && axi_w_pending_r && !axi_bvalid_o && !fifo_full_axi_w) begin
                    fifo_mem[fifo_wr_addr_w] <= axi_wdata_latched_r;
                    fifo_wr_ptr_bin_r <= fifo_wr_ptr_bin_r + 1'b1;
                    fifo_wr_ptr_gray_r <= bin2gray(fifo_wr_ptr_bin_r + 1'b1);

                    axi_bvalid_o <= 1'b1;
                    axi_bresp_o  <= 2'b00; // OKAY

                    axi_aw_pending_r <= 1'b0;
                    axi_w_pending_r  <= 1'b0;
                end
                // If a write attempt (either direct or latched) and FIFO full -> return SLVERR
                else if (( (axi_awvalid_i && axi_wvalid_i) || (axi_aw_pending_r && axi_w_pending_r) ) && !axi_bvalid_o && fifo_full_axi_w) begin
                    // generate error response (clear pending latches)
                    axi_bvalid_o <= 1'b1;
                    axi_bresp_o  <= 2'b10; // SLVERR

                    axi_aw_pending_r <= 1'b0;
                    axi_w_pending_r  <= 1'b0;
                end

                // clear BVALID when master accepts response
                if (axi_bvalid_o && axi_bready_i) begin
                    axi_bvalid_o <= 1'b0;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // AXI Read logic (clk_axi domain) - status / peek only (non-destructive)
    // Address map:
    //  - 0x0 : status      (RDATA[0] = empty flag)
    //  - 0x4 : peek_head   (non-destructive peek; returns 0 + SLVERR if empty)
    // -------------------------------------------------------------------------
    // occupancy calculation (modulo arithmetic due to fixed-width binary)
    wire [PTR:0] occupancy_axi_w = fifo_wr_ptr_bin_r - fifo_rd_bin_sync_axi;

    always @(posedge clk_axi or negedge axi_resetn_i) begin
        if (!axi_resetn_i) begin
            axi_arready_o <= 1'b0;
            axi_rvalid_o  <= 1'b0;
            axi_rresp_o   <= 2'b00;
            axi_rdata_o   <= {DATA_WIDTH{1'b0}};
        end else begin
            // accept a new AR when we have no outstanding R
            axi_arready_o <= !axi_rvalid_o;

            if (axi_arvalid_i && axi_arready_o) begin
                // decode addresses (simple mapping)
                if (axi_araddr_i == { {ADDR_WIDTH-1{1'b0}}, 1'b0 }) begin
                    // status word: bit0 = empty, bit1 = full, bits[31:16] may carry occupancy(Low bits)
                    axi_rdata_o <= { {(DATA_WIDTH-1){1'b0}}, (fifo_empty_periph_w ? 1'b1 : 1'b0) };
                    axi_rresp_o <= 2'b00;
                end else if (axi_araddr_i == { {ADDR_WIDTH-1{1'b0}}, 1'b1 }) begin
                    // peek head element (non-destructive)
                    if (fifo_empty_periph_w) begin
                        axi_rdata_o <= {DATA_WIDTH{1'b0}};
                        axi_rresp_o <= 2'b10; // SLVERR - empty
                    end else begin
                        // compute peek index using synced read pointer (safe snapshot)
                        axi_rdata_o <= fifo_mem[ fifo_rd_bin_sync_axi[PTR-1:0] ];
                        axi_rresp_o <= 2'b00;
                    end
                end else begin
                    axi_rdata_o <= {DATA_WIDTH{1'b0}};
                    axi_rresp_o <= 2'b10; // SLVERR for unsupported addresses
                end
                axi_rvalid_o <= 1'b1;
            end else if (axi_rvalid_o && axi_rready_i) begin
                axi_rvalid_o <= 1'b0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Peripheral read logic (clk_periph domain)
    // - peripheral pulses/holds periph_rd_en_i to receive data
    // - periph_rvalid_o pulses for one cycle when data present
    // -------------------------------------------------------------------------
    always @(posedge clk_periph or negedge axi_resetn_i) begin
        if (!axi_resetn_i) begin
            fifo_rd_ptr_bin_r   <= { (PTR+1){1'b0} };
            fifo_rd_ptr_gray_r  <= { (PTR+1){1'b0} };
            periph_rdata_o      <= {DATA_WIDTH{1'b0}};
            periph_rvalid_o     <= 1'b0;
        end else begin
            // default
            periph_rvalid_o <= 1'b0;

            // if peripheral requests and FIFO not empty (as seen in periph domain)
            if (periph_rd_en_i && !fifo_empty_periph_w) begin
                periph_rdata_o <= fifo_mem[ fifo_rd_addr_w ];
                periph_rvalid_o <= 1'b1;

                // advance read pointer (binary) and update gray
                fifo_rd_ptr_bin_r <= fifo_rd_ptr_bin_r + 1'b1;
                fifo_rd_ptr_gray_r <= bin2gray(fifo_rd_ptr_bin_r + 1'b1);
            end
        end
    end

endmodule
