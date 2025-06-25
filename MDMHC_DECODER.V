`timescale 1ns / 1ps

module MDMHC_DECODER(
    input [67:0] encoded_data_in,
    output [31:0] decoded_data,
    output single_error_corrected,
    output double_error_detected
);

// Extract components from encoded data
wire [31:0] received_data = encoded_data_in[31:0];
wire [15:0] received_v_parity = encoded_data_in[47:32];
wire [39:0] received_h_parity = encoded_data_in[87:48];
wire [23:0] received_hamming = encoded_data_in[111:88];

// Recalculate parities
wire [67:0] recalc_encoded;
MDMHC_ENCODER recalc_encoder(
    .data_in(received_data),
    .encoded_data(recalc_encoded)
);

wire [15:0] recalc_v_parity = recalc_encoded[47:32];
wire [39:0] recalc_h_parity = recalc_encoded[87:48];
wire [23:0] recalc_hamming = recalc_encoded[111:88];

// Calculate syndromes
wire [15:0] v_syndrome = received_v_parity ^ recalc_v_parity;
wire [39:0] h_syndrome = received_h_parity ^ recalc_h_parity;
wire [23:0] hamming_syndrome = received_hamming ^ recalc_hamming;

// Error detection and correction logic
reg [31:0] corrected_data;
reg error_corrected;
reg double_error;

// Syndrome analysis
wire total_syndrome_zero = (v_syndrome == 0) && (h_syndrome == 0) && (hamming_syndrome == 0);
wire single_bit_error = !total_syndrome_zero && (|v_syndrome) && (|h_syndrome);

integer i;
always @(*) begin
    corrected_data = received_data;
    error_corrected = 1'b0;
    double_error = 1'b0;
    
    if (!total_syndrome_zero) begin
        // Attempt single-bit correction
        if (single_bit_error) begin
            // Find error position using syndrome
            for (i = 0; i < 32; i = i + 1) begin
                if (v_syndrome[i % 16] && h_syndrome[i / 4]) begin
                    corrected_data[i] = ~received_data[i];
                    error_corrected = 1'b1;
                end
            end
        end else begin
            // Multiple errors detected
            double_error = 1'b1;
        end
    end
end

assign decoded_data = corrected_data;
assign single_error_corrected = error_corrected;
assign double_error_detected = double_error;

endmodule