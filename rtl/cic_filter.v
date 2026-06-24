`timescale 1ns/1ps

module cic_filter #(
    parameter WIDTH = 24,
    parameter DECIMATION = 64
)(
    input wire clk_in,        
    input wire rst_n,         
    input wire din_bit,       
    output reg clk_out,       
    output reg signed [WIDTH-1:0] dout 
);

    wire signed [WIDTH-1:0] din_mapped = din_bit ? 24'sd1 : -24'sd1;

    // integrator section
    reg signed [WIDTH-1:0] int1, int2, int3;
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            int1 <= 0; int2 <= 0; int3 <= 0;
        end else begin
            int1 <= int1 + din_mapped;
            int2 <= int2 + int1;
            int3 <= int3 + int2;
        end
    end

    reg [5:0] count;
    reg sample_tick;
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            sample_tick <= 0;
            clk_out <= 0;
        end else begin
            if (count == DECIMATION - 1) begin
                count <= 0;
                sample_tick <= 1'b1;
                clk_out <= 1'b1; 
            end else begin
                count <= count + 1;
                sample_tick <= 1'b0;
                if (count == (DECIMATION/2) - 1) begin
                    clk_out <= 1'b0; 
                end
            end
        end
    end

    
    reg signed [WIDTH-1:0] d1, d2, d3;
    reg signed [WIDTH-1:0] comb1, comb2, comb3;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            d1 <= 0; d2 <= 0; d3 <= 0;
            comb1 <= 0; comb2 <= 0; comb3 <= 0;
            dout <= 0;
        end else if (sample_tick) begin
            d1 <= int3;
            comb1 <= int3 - d1;
            
            d2 <= comb1;
            comb2 <= comb1 - d2;
            
            d3 <= comb2;
            comb3 <= comb2 - d3;
            
            dout <= comb3;
        end
    end
endmodule