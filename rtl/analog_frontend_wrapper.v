`timescale 1ns/1ps

module analog_frontend_wrapper (
    input wire clk_osr,      
    input wire rst_n,        
    input wire signed [31:0] vin_mv, 
    output reg bitstream     
);

    // Bypass simulator floating-point bugs using pure 32-bit integers.
    // +1.0V becomes +1000, -1.0V becomes -1000.
    reg signed [31:0] integrator_out;
    reg signed [31:0] feedback_dac;

    always @(posedge clk_osr or negedge rst_n) begin
        if (!rst_n) begin
            bitstream      <= 1'b0;
            feedback_dac   <= -1000; 
            integrator_out <= 0;
        end else begin
            // 1. Pure integer integration
            integrator_out <= integrator_out + (vin_mv - feedback_dac);

            // 2. Pure integer quantization
            if (integrator_out >= 0) begin
                bitstream    <= 1'b1;
                feedback_dac <= 1000;  
            end else begin
                bitstream    <= 1'b0;
                feedback_dac <= -1000; 
            end
        end
    end

endmodule