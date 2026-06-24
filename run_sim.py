from cocotb_test.simulator import run

def run_adc_verification():
    run(
        verilog_sources=[
            "rtl/analog_frontend_wrapper.v",
            "rtl/cic_filter.v",
            "rtl/fir_filter.v",
            "rtl/mixed_signal_top.v"
        ],
        toplevel="mixed_signal_top",
        module="tb_mixed_signal", # points to our python testbench
        sim_build="sim/build",
        simulator="icarus"
    )

if __name__ == "__main__":
    print("Compiling RTL and initializing Simulator...")
    run_adc_verification()
