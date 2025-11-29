`timescale 1ns / 1ps

module axi4_lite_fifo_async #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 8
)(
    input                      wr_clk,      // Write clock (AXI)
    input                      rd_clk,      // Read clock (Peripheral)
    input                      S_AXI_ARESETN,

    // AXI Write Address Channel
    input  [ADDR_WIDTH-1:0]    S_AXI_AWADDR,
    input                      S_AXI_AWVALID,
    output reg                 S_AXI_AWREADY,

    // AXI Write Data Channel
    input  [DATA_WIDTH-1:0]    S_AXI_WDATA,
    input  [3:0]               S_AXI_WSTRB,
    input                      S_AXI_WVALID,
    output reg                 S_AXI_WREADY,

    // AXI Write Response Channel
    output reg [1:0]           S_AXI_BRESP,
    output reg                 S_AXI_BVALID,
    input                      S_AXI_BREADY,

    // AXI Read Address Channel
    input  [ADDR_WIDTH-1:0]    S_AXI_ARADDR,
    input                      S_AXI_ARVALID,
    output reg                 S_AXI_ARREADY,

    // AXI Read Data Channel
    output reg [DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0]           S_AXI_RRESP,
    output reg                 S_AXI_RVALID,
    input                      S_AXI_RREADY
);

    // ------------------------------
    // FIFO memory and pointers
    // ------------------------------
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] wr_ptr_bin, rd_ptr_bin;
    reg [$clog2(FIFO_DEPTH):0] wr_ptr_gray, rd_ptr_gray;

    // Synchronized pointers
    reg [$clog2(FIFO_DEPTH):0] wr_ptr_gray_rdclk_sync1, wr_ptr_gray_rdclk_sync2;
    reg [$clog2(FIFO_DEPTH):0] rd_ptr_gray_wrclk_sync1, rd_ptr_gray_wrclk_sync2;

    // ------------------------------
    // Binary <-> Gray conversion
    // ------------------------------
    function [$clog2(FIFO_DEPTH):0] bin2gray(input [$clog2(FIFO_DEPTH):0] bin);
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    function [$clog2(FIFO_DEPTH):0] gray2bin(input [$clog2(FIFO_DEPTH):0] gray);
        integer i;
        begin
            gray2bin[$clog2(FIFO_DEPTH)] = gray[$clog2(FIFO_DEPTH)];
            for(i=$clog2(FIFO_DEPTH)-1;i>=0;i=i-1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // ------------------------------
    // Pointer synchronization
    // ------------------------------
    always @(posedge rd_clk or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            wr_ptr_gray_rdclk_sync1 <= 0;
            wr_ptr_gray_rdclk_sync2 <= 0;
        end else begin
            wr_ptr_gray_rdclk_sync1 <= wr_ptr_gray;
            wr_ptr_gray_rdclk_sync2 <= wr_ptr_gray_rdclk_sync1;
        end
    end

    always @(posedge wr_clk or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            rd_ptr_gray_wrclk_sync1 <= 0;
            rd_ptr_gray_wrclk_sync2 <= 0;
        end else begin
            rd_ptr_gray_wrclk_sync1 <= rd_ptr_gray;
            rd_ptr_gray_wrclk_sync2 <= rd_ptr_gray_wrclk_sync1;
        end
    end

    // ------------------------------
    // Full & Empty flags
    // ------------------------------
    wire fifo_full  = ( ((wr_ptr_bin + 1) % FIFO_DEPTH) == gray2bin(rd_ptr_gray_wrclk_sync2) );
    wire fifo_empty = ( rd_ptr_bin == gray2bin(wr_ptr_gray_rdclk_sync2) );

    // ------------------------------
    // Write logic (AXI)
    // ------------------------------
    always @(posedge wr_clk or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 0;
            S_AXI_WREADY  <= 0;
            S_AXI_BVALID  <= 0;
            S_AXI_BRESP   <= 2'b00;
            wr_ptr_bin    <= 0;
            wr_ptr_gray   <= 0;
        end else begin
            // AW/W handshake
            S_AXI_AWREADY <= !S_AXI_BVALID;
            S_AXI_WREADY  <= !S_AXI_BVALID;

            if (S_AXI_AWVALID && S_AXI_WVALID && !fifo_full) begin
                fifo_mem[wr_ptr_bin] <= S_AXI_WDATA;
                wr_ptr_bin <= (wr_ptr_bin + 1) % FIFO_DEPTH;
                wr_ptr_gray <= bin2gray((wr_ptr_bin + 1) % FIFO_DEPTH);

                S_AXI_BVALID <= 1;
                S_AXI_BRESP  <= 2'b00; // OKAY
            end else if (S_AXI_AWVALID && S_AXI_WVALID && fifo_full) begin
                S_AXI_BVALID <= 1;
                S_AXI_BRESP  <= 2'b10; // SLVERR
            end else if (S_AXI_BREADY) begin
                S_AXI_BVALID <= 0;
            end
        end
    end

    // ------------------------------
    // Read logic (Peripheral)
    // ------------------------------
    always @(posedge rd_clk or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 0;
            S_AXI_RVALID  <= 0;
            S_AXI_RRESP   <= 2'b00;
            rd_ptr_bin    <= 0;
            rd_ptr_gray   <= 0;
        end else begin
            S_AXI_ARREADY <= 1;

            if (S_AXI_ARVALID && S_AXI_ARREADY && !fifo_empty) begin
                S_AXI_RDATA  <= fifo_mem[rd_ptr_bin];
                rd_ptr_bin   <= (rd_ptr_bin + 1) % FIFO_DEPTH;
                rd_ptr_gray  <= bin2gray((rd_ptr_bin + 1) % FIFO_DEPTH);

                S_AXI_RVALID <= 1;
                S_AXI_RRESP  <= 2'b00; // OKAY
            end else if (S_AXI_ARVALID && S_AXI_ARREADY && fifo_empty) begin
                S_AXI_RDATA  <= 0;
                S_AXI_RVALID <= 1;
                S_AXI_RRESP  <= 2'b10; // SLVERR
            end else if (S_AXI_RREADY) begin
                S_AXI_RVALID <= 0;
            end
        end
    end

endmodule
