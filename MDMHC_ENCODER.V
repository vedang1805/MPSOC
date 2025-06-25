`timescale 1ns / 1ps

module MDMHC_ENCODER(
    input [31:0] data_in,
    output [67:0] encoded_data  // 32 data + 20 horizontal + 16 vertical parity bits
);

// Arrange 32-bit input into 2x4 matrix (each element is 4 bits)
wire [3:0] matrix [0:1][0:3];

// Matrix arrangement
assign matrix[0][0] = data_in[3:0];
assign matrix[0][1] = data_in[7:4];
assign matrix[0][2] = data_in[11:8];
assign matrix[0][3] = data_in[15:12];
assign matrix[1][0] = data_in[19:16];
assign matrix[1][1] = data_in[23:20];
assign matrix[1][2] = data_in[27:24];
assign matrix[1][3] = data_in[31:28];

// Horizontal parity generation (5 bits per symbol using adder)
wire [4:0] h_parity [0:7];

// Row 0
assign h_parity[0] = {1'b0, matrix[0][0]} + {1'b0, matrix[0][2]};  // data[3:0] + data[11:8]
assign h_parity[1] = {1'b0, matrix[0][1]} + {1'b0, matrix[0][3]};  // data[7:4] + data[15:12]

// Row 1
assign h_parity[2] = {1'b0, matrix[1][0]} + {1'b0, matrix[1][2]};  // data[19:16] + data[27:24]
assign h_parity[3] = {1'b0, matrix[1][1]} + {1'b0, matrix[1][3]};  // data[23:20] + data[31:28]

// Additional horizontal parity for complete coverage
assign h_parity[4] = {1'b0, matrix[0][0]} + {1'b0, matrix[0][1]};
assign h_parity[5] = {1'b0, matrix[0][2]} + {1'b0, matrix[0][3]};
assign h_parity[6] = {1'b0, matrix[1][0]} + {1'b0, matrix[1][1]};
assign h_parity[7] = {1'b0, matrix[1][2]} + {1'b0, matrix[1][3]};

// Vertical parity generation (XOR operation)
wire [15:0] v_parity;
genvar j;
generate
    for (j = 0; j < 16; j = j + 1) begin : vertical_parity_gen
        assign v_parity[j] = data_in[j] ^ data_in[j + 16];
    end
endgenerate

// Hamming code parity bits for each 4-bit symbol
wire [2:0] hamming_parity [0:7];
genvar k;
generate
    for (k = 0; k < 8; k = k + 1) begin : hamming_gen
        wire [3:0] symbol = (k < 4) ? matrix[0][k] : matrix[1][k-4];
        assign hamming_parity[k][0] = symbol[0] ^ symbol[1] ^ symbol[3]; // P1
        assign hamming_parity[k][1] = symbol[0] ^ symbol[2] ^ symbol[3]; // P2
        assign hamming_parity[k][2] = symbol[1] ^ symbol[2] ^ symbol[3]; // P3
    end
endgenerate

// Combine all bits into encoded output
assign encoded_data = {
    hamming_parity[7], hamming_parity[6], hamming_parity[5], hamming_parity[4],
    hamming_parity[3], hamming_parity[2], hamming_parity[1], hamming_parity[0],  // 24 bits
    h_parity[7], h_parity[6], h_parity[5], h_parity[4],
    h_parity[3], h_parity[2], h_parity[1], h_parity[0],  // 40 bits
    v_parity,  // 16 bits
    data_in    // 32 bits
};

endmodule