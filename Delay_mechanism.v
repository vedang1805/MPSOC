`timescale 1ns / 1ps

module DELAY_MECHANISM #(
    parameter DELAY_CYCLES = 2  // Configurable delay
)(
    input clk,
    input reset,
    input [31:0] instruction_in,
    output reg [31:0] instruction_out
);

// Create delay registers based on DELAY_CYCLES
reg [31:0] delay_regs [0:DELAY_CYCLES-1];
integer i;

always @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < DELAY_CYCLES; i = i + 1) begin
            delay_regs[i] <= 32'h00000013; // NOP instruction
        end
        instruction_out <= 32'h00000013;
    end else begin
        // Shift register implementation
        delay_regs[0] <= instruction_in;
        for (i = 1; i < DELAY_CYCLES; i = i + 1) begin
            delay_regs[i] <= delay_regs[i-1];
        end
        instruction_out <= delay_regs[DELAY_CYCLES-1];
    end
end

endmodule