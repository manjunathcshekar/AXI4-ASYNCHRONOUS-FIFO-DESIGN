`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// fifo_interrupt_controller
// Simple level-sensitive interrupt latching for FIFO status flags.
// - irq_full asserts when fifo_full is seen and stays high until cleared.
// - irq_empty asserts when fifo_empty is seen and stays high until cleared.
// - Clears are synchronous and take priority over new assertions in the same
//   cycle to avoid sticky interrupts after explicit clear.
// -----------------------------------------------------------------------------
module fifo_interrupt_controller (
    input  logic clk,
    input  logic rst_n,
    input  logic fifo_full,
    input  logic fifo_empty,
    input  logic irq_clear_full,
    input  logic irq_clear_empty,
    output logic irq_full,
    output logic irq_empty
);

    // Latch interrupts; clears take priority over set in case both occur
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_full  <= 1'b0;
            irq_empty <= 1'b0;
        end else begin
            // FULL interrupt
            if (irq_clear_full) begin
                irq_full <= 1'b0;
            end else if (fifo_full) begin
                irq_full <= 1'b1;
            end

            // EMPTY interrupt
            if (irq_clear_empty) begin
                irq_empty <= 1'b0;
            end else if (fifo_empty) begin
                irq_empty <= 1'b1;
            end
        end
    end

endmodule

