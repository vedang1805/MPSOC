`timescale 1ns / 1ps

module DCLS_TOP(
    input clk,
    input reset,
    
    // Error injection signals for testing
    input error_inject_enable,
    input [5:0] error_position,  // For MDMHC testing
    
    // Output signals
    output [31:0] final_output,
    output error_detected,
    output mismatch_flag,
    output unrecognized_instruction,
    output single_error_corrected,
    output double_error_detected
);

// Parameters
parameter DELAY_CYCLES = 2;  // Configurable delay for shadow core

// Internal signals
wire [31:0] master_result;
wire [31:0] shadow_result;
wire master_unrecognized;
wire shadow_unrecognized;

// Comparator signals
wire cores_match;
reg error_flag;

// MDMHC Encoder/Decoder signals  
wire [67:0] encoded_master_output;
wire [67:0] encoded_shadow_output;
wire [67:0] corrupted_encoded_data;
wire [31:0] decoded_output;

// Delay mechanism for shadow core reset
reg [DELAY_CYCLES-1:0] reset_delay;
reg shadow_reset;

always @(posedge clk) begin
    if (reset) begin
        reset_delay <= {DELAY_CYCLES{1'b1}};
        shadow_reset <= 1'b1;
    end else begin
        reset_delay <= {reset_delay[DELAY_CYCLES-2:0], 1'b0};
        shadow_reset <= reset_delay[DELAY_CYCLES-1];
    end
end

// Master Core Instance using RISC_V_PROCESSOR_LOCKSTEP
RISC_V_PROCESSOR_LOCKSTEP master_core(
    .clk(clk),
    .reset(reset),
    .is_shadow_core(1'b0),
    .external_instruction(32'h00000013),  // NOP (not used for master)
    .external_inst_valid(1'b0),
    .unrecognized(master_unrecognized),    // Correct port name
    .wb_data(master_result)                // Correct port name
);

// Shadow Core Instance using RISC_V_PROCESSOR_LOCKSTEP with delayed reset
RISC_V_PROCESSOR_LOCKSTEP shadow_core(
    .clk(clk),
    .reset(shadow_reset),
    .is_shadow_core(1'b1),
    .external_instruction(32'h00000013),  // NOP (will use shared instruction memory)
    .external_inst_valid(1'b0),           // Use internal instruction fetch
    .unrecognized(shadow_unrecognized),    // Correct port name
    .wb_data(shadow_result)                // Correct port name
);

// MDMHC Encoder for master output
MDMHC_ENCODER master_encoder(
    .data_in(master_result),
    .encoded_data(encoded_master_output)
);

// MDMHC Encoder for shadow output  
MDMHC_ENCODER shadow_encoder(
    .data_in(shadow_result),
    .encoded_data(encoded_shadow_output)
);

// Error injection for testing (inject into master's encoded output)
assign corrupted_encoded_data = error_inject_enable ? 
    (encoded_master_output ^ (68'b1 << error_position)) : encoded_master_output;

// MDMHC Decoder
MDMHC_DECODER decoder(
    .encoded_data_in(corrupted_encoded_data),
    .decoded_data(decoded_output),
    .single_error_corrected(single_error_corrected),
    .double_error_detected(double_error_detected)
);

// Comparator Module
COMPARATOR comp_unit(
    .master_output(master_result),
    .shadow_output(shadow_result),
    .clk(clk),
    .reset(reset),
    .match(cores_match),
    .mismatch(mismatch_flag)
);

// Error detection logic
always @(posedge clk) begin
    if (reset) begin
        error_flag <= 1'b0;
    end else begin
        if (!cores_match || double_error_detected) begin
            error_flag <= 1'b1;
        end
    end
end

// Output assignments
assign error_detected = error_flag || double_error_detected;
assign final_output = single_error_corrected ? decoded_output : master_result;
assign unrecognized_instruction = master_unrecognized | shadow_unrecognized;

endmodule
