`timescale 1ns / 1ps

module COMPARATOR(
    input [31:0] master_output,
    input [31:0] shadow_output,
    input clk,
    input reset,
    output reg match,
    output reg mismatch
);

always @(posedge clk) begin
    if (reset) begin
        match <= 1'b1;
        mismatch <= 1'b0;
    end else begin
        if (master_output == shadow_output) begin
            match <= 1'b1;
            mismatch <= 1'b0;
        end else begin
            match <= 1'b0;
            mismatch <= 1'b1;
        end
    end
end

endmodule