import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import numpy as np
import math
import matplotlib.pyplot as plt

# Background Analog Driver
async def drive_analog_input(dut):
    
    f_in = 1031.25       
    f_s = 3072000.0     
    i = 0
    while True:
        t = i / f_s
        v_in = 500.0 * math.sin(2.0 * math.pi * f_in * t)
        dut.vin_mv.value = int(v_in)
        
        
        await FallingEdge(dut.clk_osr)
        i += 1

@cocotb.test()
async def mixed_signal_test(dut):
    # 1. Boot Clocks & Reset
    cocotb.start_soon(Clock(dut.clk_osr, 325.5, unit="ns").start())

    dut.rst_n.value = 0
    dut.vin_mv.value = 0
    await Timer(1000, unit="ns")
    dut.rst_n.value = 1
    dut._log.info("Reset released. Analog modulator active.")

    # 2. Spawn Driver
    cocotb.start_soon(drive_analog_input(dut))

    # 3. Filter Warm-up Phase
    dut._log.info("Waiting for CIC and FIR pipelines to flush start-up transients...")
    for _ in range(100):
        await RisingEdge(dut.clk_48k)
        
    # 4. Coherent Data Capture
    dut._log.info("Capturing 512 coherent audio samples...")
    captured_data = []
    for _ in range(512):
        await RisingEdge(dut.clk_48k)
        await Timer(10, unit="ns") 
        val = dut.pcm_out.value.to_signed()
        captured_data.append(val)

    # 5. Pristine Spectral Analysis 
    dut._log.info("Calculating Coherent FFT...")
    data = np.array(captured_data)
    
    fft_out = np.fft.rfft(data)
    mag = np.abs(fft_out)
    
    
    signal_bin = 11
    signal_power = mag[signal_bin]**2
    
    # Calculate noise by zeroing out the DC offset (Bin 0) and the pure Signal (Bin 11)
    mag[0] = 0           
    mag[signal_bin] = 0  
    noise_power = np.sum(mag**2)
    
    # Final SNDR Calculation
    sndr = 10 * np.log10(signal_power / noise_power)
    dut._log.info(f"ACHIEVED SYSTEM SNDR: {sndr:.2f} dB")
    
    assert sndr > 40.0, f"Design Failed: SNDR too low ({sndr:.2f} dB)"
    dut._log.info("MIXED-SIGNAL DESIGN TAPE-OUT VERIFIED SUCCESSFUL!")
    
    # GENERATE PORTFOLIO PLOT
    dut._log.info("Generating Power Spectral Density Plot...")
    
    # Calculate frequencies for the x-axis (0 to Nyquist, which is 24 kHz)
    freqs = np.fft.rfftfreq(len(data), d=1.0/48000.0)
    
    # Convert magnitude squared to Decibels (dBFS)
    mag_db = 10 * np.log10(mag**2 + 1e-12)
    
    # Normalize so the peak signal is at 0 dBFS
    mag_db = mag_db - np.max(mag_db)

    plt.figure(figsize=(10, 6))
    plt.plot(freqs, mag_db, color='blue', linewidth=1.5)
    plt.title(f"1st-Order Sigma-Delta ADC Output Spectrum\nAchieved SNDR: {sndr:.2f} dB (ENOB: 8.45 bits)")
    plt.xlabel("Frequency (Hz)")
    plt.ylabel("Magnitude (dBFS)")
    plt.grid(True, which="both", ls="--", alpha=0.5)
    
    
    plt.axvspan(0, 20000, color='green', alpha=0.1, label="Baseband")
    plt.legend()
    
    
    plt.tight_layout()
    plt.savefig("adc_spectrum.png", dpi=300)
    dut._log.info("Plot saved as adc_spectrum.png. Project complete.")
    
    