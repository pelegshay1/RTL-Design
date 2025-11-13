# 7-SEGMENT CONTROLLER FOR NEXYS A7 (RTL DESIGN)

This repository contains the Verilog HDL (Hardware Description Language) implementation for a modular digital system designed to manage user input and display data on the Digilent Nexys A7 FPGA board's 7-segment display.

## 1. Project Overview

The primary goal of this design is to multiplex a 16-bit binary input (from switches) onto the 5 central digits of the 8-digit display. The system provides two operating modes and manages the display's Active-Low nature.

### Key Functionality:
* **Latching:** The current value of the switches (SW) is latched (captured) into a register upon a **Center Button (BTN_C) Long Press**.
* **Mode Control:** Toggles the display between Hexadecimal (Hex) and Binary-Coded Decimal (BCD).
* **Multiplexing:** The display cycles through 4 (Hex) or 5 (BCD) digits at a 400Hz refresh rate.

---

## 2. Design Architecture (Top-Level Components)

The design is modular, encapsulated by the `top_level` module, which connects the following three main sub-modules:

| Module | Purpose | Key Parameters/Logic |
| :--- | :--- | :--- |
| **system_controller** | The 'Brain.' Handles input debouncing, detects Long/Short button presses, manages the 1-second timer, and sets the display mode (Hex/Dec). | `CLK_FREQ` (Override for simulation speed) |
| **binary_to_bcd_16_bit** | Data conversion. Implements the **Shift-and-Add-3 (Double-Dabble)** algorithm to convert the 16-bit binary value into a 5-digit BCD format. | Purely Combinational |
| **seg_controller** | The Display Driver. Handles multiplexing control (Mod-4/Mod-5 counter) and contains the integrated 7-segment decoder. | `CLK400HZ` (Override for simulation speed) |

---

## 3. Hardware Rules and Constraints (NEXYS A7)

The design strictly adheres to the I/O rules of the Nexys A7's 7-Segment Display, which is configured as **Common Anode** with transistors performing signal inversion on the digit-select lines.

### A. I/O Polarity (Active-Low):

| Function | Signal Name (Verilog) | Active State | Purpose |
| :--- | :--- | :--- | :--- |
| **Segment Data** (a-g) | `seg_catode[6:0]` | **Logic LOW (0)** | To turn an individual segment ON. |
| **Digit Select** (AN0-AN4) | `seg_anode[4:0]` | **Logic LOW (0)** | To enable/light up a specific digit. |
| **System Reset** | `reset` | **Logic LOW (0)** | To assert system reset. |

### B. Button Logic Summary (BTN_C):

| Button Event | State Action | Mode Result |
| :--- | :--- | :--- |
| **Long Press** (> 1 second) | Latches `sw` input to `latched_switch_value`. | Forces **DECIMAL (0)** mode (to show new value). |
| **Short Press** (< 1 second) | No latching. | Forces **DECIMAL (0)** mode (as defined by code). |
| **Down Press (BTN_D)** | No latching. | Toggles mode to **HEX (1)**. |

---

## 4. Synthesis and Simulation Notes

### A. Parameter Overrides (Fast Simulation):
The design is scaled for testing. To run quickly in tools like Vivado or Icarus Verilog, the internal time constants must be overridden during instantiation:

| Module | Parameter | Default Value (FPGA) | Testbench Value (TB) |
| :--- | :--- | :--- | :--- |
| `system_controller` | `.CLK_FREQ` | 100,000,000 | **200** (1 sec $\approx$ 201 cycles) |
| `seg_controller` | `.CLK400HZ` | 250,000 | **20** (400Hz $\approx$ 21 cycles) |

### B. Verilog Port to FPGA Pin Mapping (XDC):

| Verilog Port | Bit Order | FPGA Pin | Description |
| :--- | :--- | :--- | :--- |
| `clk100` | - | **E3** | 100MHz System Clock |
| `reset` | - | **C12** | CPU Reset Button |
| `center_button` | - | **N17** | BTN_C |
| `down_button` | - | **P18** | BTN_D |
| **`seg_catode[6:0]`** | `[6]=A, [0]=G` | **T10, R10, K16...** | Segment Data (Cathodes) |
| **`seg_anode[4:0]`** | `[0]=AN0, [4]=AN4`| **J17, J18, T9...** | Digit Select (Anodes) |