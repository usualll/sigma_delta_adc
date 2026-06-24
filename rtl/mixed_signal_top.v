`timescale 1ns/1ps

module mixed_signal_top (
    input wire clk_osr,          
    input wire rst_n,            
    input wire signed [31:0] vin_mv, 
    output wire signed [23:0] pcm_out 
);

    wire bitstream;
    wire clk_48k;
    wire signed [23:0] cic_data_out;

    analog_frontend_wrapper u_analog (
        .clk_osr(clk_osr),
        .rst_n(rst_n),
        .vin_mv(vin_mv),
        .bitstream(bitstream)
    );

    cic_filter u_cic (
        .clk_in(clk_osr),
        .rst_n(rst_n),
        .din_bit(bitstream),
        .clk_out(clk_48k),
        .dout(cic_data_out)
    );

    fir_filter u_fir (
        .clk_48k(clk_48k),
        .rst_n(rst_n),
        .din(cic_data_out),
        .dout(pcm_out)
    );

endmodule