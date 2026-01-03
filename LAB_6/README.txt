================================================================================
                    LAB6 - RGB LED PWM Controller System
================================================================================

PROJECT OVERVIEW
----------------
This project implements a complete RGB LED control system on an FPGA that 
receives color commands via UART, processes them through gamma correction 
and CIE scaling, and outputs PWM signals to control RGB LEDs. The system 
supports two LEDs (LED16 and LED17) with button-based color adjustment and 
a 7-segment display for feedback.

================================================================================
SYSTEM ARCHITECTURE
================================================================================

TOP MODULE: Top_Level.sv
------------------------
The top-level module integrates all system components:
- UART Receiver (57600 baud)
- Message validation and parsing
- RGB value processing (gamma + CIE scaling)
- PWM generation (3 generators: Red, Green, Blue)
- Button debouncing (5 buttons)
- 7-segment display controller
- Output: PWM signals for LED16 and LED17 (3 channels each)

MAIN MODULES
------------

1. Reciever.sv
   - UART PHY receiver
   - 57600 baud rate, 100MHz clock
   - 5-point oversampling for accurate data capture
   - Outputs: rx_byte, rx_done, status LEDs

2. Buffer_Checker (buffer_checker_new.sv)
   - Validates incoming UART messages
   - Supports two message formats:
     * RGB: {Rddd,Gddd,Bddd} (16 bytes)
     * LED Selector: {L016} or {L017} (6 bytes)
   - Buffers validated messages (128-bit for RGB, extracts LED command)
   - Outputs: valid_msg, msg_ready, led_command, led_cmd_ready

3. uart_parser (uart_parser_new.sv)
   - Parses RGB messages: ASCII to binary conversion
   - Extracts Red, Green, Blue values (0-255)
   - Passes through LED command messages
   - Output: pixel_data_packet [23:0] = {R[7:0], G[7:0], B[7:0]}

4. FSM_rx (FSM_rx_New.sv)
   - Main control state machine
   - Processes RGB data packets
   - Handles button controls:
     * Up/Down: Increase/Decrease selected color value
     * Left/Right: Select color (Red/Green/Blue) or LED (16/17)
     * Center: Commit changes to RGB values
   - Outputs: red_value, green_value, blue_value, led_select

5. CIE_scaling_unit (CIE_scailing.sv)
   - Applies gamma correction using gamma_lut_table.sv
   - Converts sRGB (0-255) to linear LED values (0-1023)
   - Applies CIE scaling constants for perceived brightness:
     * Red:   1.0 (no scaling)
     * Green: 0.51 (multiply by 131/256 using bit shifts)
     * Blue:  2.62 (multiply by 671/256 using bit shifts)
   - Parametrized PWM resolution: 512, 1024, or 2048 slots
   - Outputs: red_pwm_out, green_pwm_out, blue_pwm_out [10:0]

6. PWM_generator.sv (3 instances)
   - Generates PWM signals for each color channel (Red, Green, Blue)
   - Parametrized resolution: 512, 1024, or 2048 slots
   - Routes PWM output to LED16 or LED17 based on led_select:
     * led_select = 2'b01: Output to LED16
     * led_select = 2'b10: Output to LED17
   - Outputs: pwm_out_16, pwm_out_17

7. button_debouncer (20ms_button_debouncer.sv)
   - 5 instances (one per button)
   - 20ms debounce period
   - 100MHz clock frequency
   - Outputs: buttons_clean[4:0]

8. seg_controller.sv
   - 7-segment display controller
   - Displays RGB values and LED selection
   - Multiplexed display (400Hz refresh)
   - Outputs: cathode[7:0], anode[7:0]

================================================================================
MESSAGE FORMATS
================================================================================

RGB MESSAGE FORMAT
------------------
Format: {Rddd,Gddd,Bddd}
- Example: {R255,G128,B000}
- Length: 16 bytes (including braces and commas)
- R, G, B: ASCII characters (0x52, 0x47, 0x42)
- ddd: ASCII digits 0-9 (0x30-0x39)
- Values: 000-255 for each color component

LED SELECTOR MESSAGE FORMAT
---------------------------
Format: {L016} or {L017}
- Example: {L016} for LED16, {L017} for LED17
- Length: 6 bytes (including braces)
- L: ASCII character (0x4C)
- 0: ASCII zero (0x30)
- 16/17: ASCII digits (0x31 0x36 / 0x31 0x37)

================================================================================
SYSTEM PARAMETERS
================================================================================

Clock Frequency:     100 MHz
UART Baud Rate:      57600
PWM Resolution:      512, 1024, or 2048 slots (default: 1024)
Debounce Period:     20 ms (2000000 clock cycles @ 100MHz)
Display Refresh:     400 Hz (250000 clock cycles @ 100MHz)

CIE SCALING CONSTANTS
---------------------
Red:   1.0   (no scaling)
Green: 0.51  (multiply by 131/256)
Blue:  2.62  (multiply by 671/256)

Implementation uses bit shifts and additions for efficient hardware synthesis:
- Green: (gamma << 7) + (gamma << 1) + gamma, then >> 8
- Blue:  (gamma << 9) + (gamma << 7) + (gamma << 4) + (gamma << 3) + 
         (gamma << 2) + (gamma << 1) + gamma, then >> 8

================================================================================
BUTTON CONTROLS
================================================================================

Button[0] (Up):      Increase selected color value
Button[1] (Down):    Decrease selected color value
Button[2] (Left):    Previous selection (color or LED)
Button[3] (Right):   Next selection (color or LED)
Button[4] (Center):  Commit changes to RGB values and LED selection

Selection Mode:
- 00: LED selection (LED16/LED17)
- 01: Red color adjustment
- 10: Green color adjustment
- 11: Blue color adjustment

================================================================================
FILE STRUCTURE
================================================================================

Core Modules:
-------------
Top_Level.sv                  - Top-level integration module
Reciever.sv                   - UART receiver PHY
buffer_checker_new.sv         - Message validation and buffering
uart_parser_new.sv            - RGB message parsing (ASCII to binary)
FSM_rx_New.sv                 - Main control state machine
CIE_scailing.sv               - Gamma correction and CIE scaling
gamma_lut_table.sv            - Gamma correction lookup table (256 entries)
PWM_generator.sv              - PWM signal generator
20ms_button_debouncer.sv      - Button debouncer (20ms period)
seg_controller.sv             - 7-segment display controller

Testbenches:
------------
LAB_tb/CIE_PWM_generator_tb.sv       - Testbench for CIE and PWM modules
LAB_tb/reciever_checker_parser_tb.sv - Integrated testbench for RX chain
LAB_tb/debouncer.sv                  - Button debouncer testbench

Tools:
------
send_rgb_commands.py          - Python script for automated RGB/LED commands
                                 via serial port (COM5, 57600 baud)

Legacy Files (not used in current design):
------------------------------------------
Buffer_Checker.sv             - Legacy buffer checker
FSM_Rx.sv                     - Legacy FSM
FSM_Tx.sv                     - Legacy transmitter FSM
Transmitter.sv                - Legacy transmitter
system_controller.sv          - Legacy system controller

================================================================================
USAGE INSTRUCTIONS
================================================================================

HARDWARE SETUP
--------------
1. Connect FPGA board to host PC via UART (typically COM5)
2. Configure UART settings: 57600 baud, 8N1
3. Connect RGB LEDs to PWM output pins:
   - LED16: pwm_out_16[2:0] = {Blue, Green, Red}
   - LED17: pwm_out_17[2:0] = {Blue, Green, Red}
4. Connect buttons to button[4:0] inputs
5. Connect 7-segment display to cathode[7:0] and anode[7:0] outputs

SENDING COMMANDS VIA UART
--------------------------
Method 1: Manual Serial Terminal
- Open serial terminal (PuTTY, Tera Term, etc.)
- Configure: COM5, 57600 baud, 8N1
- Send RGB command: {R255,G128,B000}
- Send LED command: {L016} or {L017}

Method 2: Python Script
- Run: python send_rgb_commands.py
- Script automatically sends test sequences to both LEDs
- Modify script to send custom RGB values

BUTTON CONTROLS
---------------
1. Use Left/Right buttons to select:
   - LED selection mode: Choose LED16 or LED17
   - Color adjustment mode: Select Red, Green, or Blue
2. Use Up/Down buttons to adjust selected value
3. Press Center button to commit changes

================================================================================
SIMULATION
================================================================================

CIE_PWM_generator_tb.sv
-----------------------
Tests gamma correction and PWM generation:
- Input RGB values (0-255)
- Verify gamma-corrected outputs (0-1023)
- Verify CIE-scaled PWM values
- Test PWM signal generation with various duty cycles
- Test LED16 and LED17 routing
- Supports PWM_SLOTS = 512, 1024, or 2048

reciever_checker_parser_tb.sv
-----------------------------
Integrated testbench for UART receive chain:
- Simulates UART byte reception
- Tests message validation (RGB and LED formats)
- Tests ASCII to binary conversion
- Tests button debouncing
- Tests FSM control logic

RUNNING SIMULATION
------------------
1. Open project in Vivado/Xcelium/ModelSim
2. Add testbench file and required modules
3. Set testbench as top module
4. Run simulation
5. View waveforms to verify functionality

================================================================================
DESIGN NOTES
================================================================================

GAMMA CORRECTION
----------------
- Uses pre-computed lookup table (gamma_lut_table.sv)
- Maps 8-bit sRGB input (0-255) to 10-bit linear output (0-1023)
- Implements sRGB gamma curve (gamma ≈ 2.2)
- Improves perceived color accuracy for human vision

CIE SCALING
-----------
- Compensates for different LED brightness characteristics
- Red LED: No scaling (1.0)
- Green LED: Reduced brightness (0.51) for color matching
- Blue LED: Increased brightness (2.62) for color matching
- Uses fixed-point arithmetic (multiply by constant, divide by 256)
- Implemented with bit shifts and additions for efficiency

PWM GENERATION
--------------
- Parametrized resolution: 512, 1024, or 2048 slots
- Counter-based implementation
- Output HIGH when counter < duty_cycle
- Supports up to 11-bit duty cycle (for 2048 slots)
- Each color channel has independent PWM generator

BUTTON DEBOUNCING
-----------------
- 20ms debounce period (2000000 cycles @ 100MHz)
- Prevents false triggers from mechanical switch bounce
- 5 instances for 5 buttons
- Outputs clean button signals to FSM

MESSAGE VALIDATION
------------------
- Validates message format byte-by-byte
- Supports two message types: RGB and LED selector
- Discards invalid messages
- Outputs validated 128-bit buffer for RGB messages
- Extracts LED command (16 or 17) for LED messages

================================================================================
TESTING CHECKLIST
================================================================================

[ ] UART reception at 57600 baud
[ ] RGB message validation ({Rddd,Gddd,Bddd})
[ ] LED message validation ({L016}, {L017})
[ ] ASCII to binary conversion accuracy
[ ] Gamma correction (verify LUT lookup)
[ ] CIE scaling (verify fixed-point math)
[ ] PWM generation (verify duty cycles)
[ ] LED16/LED17 routing (verify led_select)
[ ] Button debouncing (20ms period)
[ ] Button controls (Up/Down/Left/Right/Center)
[ ] 7-segment display output
[ ] Status LED outputs

================================================================================
KNOWN ISSUES / LIMITATIONS
================================================================================

1. PWM resolution is fixed at design time (parameter)
2. CIE scaling uses fixed constants (not adjustable at runtime)
3. Button debounce period is fixed (20ms, not configurable)
4. Maximum RGB value is 255 (8-bit input)
5. Only two LEDs supported (LED16 and LED17)

================================================================================
AUTHOR & VERSION
================================================================================

Project: LAB6 - RGB LED PWM Controller
Version: 1.0
Date: 2024

================================================================================
LICENSE
================================================================================

This project is provided for educational purposes.

================================================================================

