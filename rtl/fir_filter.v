`timescale 1ns/1ps

module fir_filter #(
    parameter TAPS = 31,
    parameter IN_WIDTH = 24,
    parameter OUT_WIDTH = 24
)(
    input wire clk_48k,          // 48 kHz slow clock from the CIC
    input wire rst_n,            // Active-low reset
    input wire signed [IN_WIDTH-1:0] din,
    output reg signed [OUT_WIDTH-1:0] dout
);

    // coeff rom
    reg signed [15:0] coeffs [0:TAPS-1];
    initial begin
        $readmemh("../../rtl/coeffs.hex", coeffs);
    end

    // shift register delay
    reg signed [IN_WIDTH-1:0] shift_reg [0:TAPS-1];
    integer i;

    always @(posedge clk_48k or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i = i + 1) begin
                shift_reg[i] <= 0;
            end
        end else begin
            shift_reg[0] <= din;
            for (i = 1; i < TAPS; i = i + 1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
        end
    end

    // MAC
    reg signed [45:0] acc;
    integer j;

    always @(*) begin
        acc = 0;
        for (j = 0; j < TAPS; j = j + 1) begin
            acc = acc + (shift_reg[j] * coeffs[j]);
        end
    end

    // output scaling
    always @(posedge clk_48k or negedge rst_n) begin
        if (!rst_n) dout <= 0;
        else dout <= acc >>> 15;
    end

endmodule