import numpy as np
from scipy import signal
import os

print("Calculating 31-tap FIR compensator coefficients...")

# 31-tap low-pass filter to clean up the CIC output
num_taps = 31
bands = [0, 0.25, 0.3, 0.5] 
desired = [1, 0] # Passband = 1, Stopband = 0

# Calculate optimal coefficients using Remez algorithm
taps = signal.remez(num_taps, bands, desired, fs=1.0)

# Quantize the floating-point taps to 16-bit integers for hardware
taps_quant = np.round(taps * (2**15 - 1)).astype(int)


os.makedirs('rtl', exist_ok=True)

# Write to hex file for Verilog's $readmemh function
with open('rtl/coeffs.hex', 'w') as f:
    for tap in taps_quant:
        
        hex_val = hex(tap & 0xFFFF)[2:].zfill(4)
        f.write(f"{hex_val}\n")

print("Success! Coefficients written to rtl/coeffs.hex")