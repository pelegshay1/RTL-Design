================================================================================
      UART RGB/LED Control & Display System - FPGA Project Overview
================================================================================

1. PROJECT DESCRIPTION
----------------------
This project implements a robust, bi-directional UART communication system on 
an FPGA (Xilinx Nexys/Basys style). The system is designed to receive and 
validate complex multi-byte ASCII commands from a PC (e.g., via PuTTY) to 
control RGB values, LED states, and update an 8-digit 7-segment display.

The system supports two primary message formats:
- RGB Commands: {Rddd,Cddd,Vddd} (16 bytes) to update specific display pixels.
- LED Commands: {L016} or {L017} (6 bytes) for direct hardware control.

2. FILE ARCHITECTURE & MODULE DESCRIPTIONS
------------------------------------------

Top_Level.sv
- Purpose: The system's top-level entity.
- Description: Integrates all sub-modules including the UART PHY, Parsers, 
  FSMs, and Display Controllers. It manages internal signal routing and global 
  reset/clock distribution.

Reciever.sv
- Purpose: Physical Layer (PHY) UART Receiver.
- Implementation: Handles start-bit detection with synchronization to prevent 
  metastability. It uses 5-point oversampling per bit and Majority Voting 
  (3-out-of-5) logic to ensure high noise immunity.

Transmitter.sv
- Purpose: Physical Layer (PHY) UART Transmitter.
- Implementation: Implements a shift register that transmits 8-bit data 
  enclosed in a start bit and two stop bits. It generates a precise 
  baud rate tick for 57,600 bps.

Buffer_Checker.sv
- Purpose: Frame synchronization and real-time protocol validation.
- Implementation: An FSM-based buffer that hunts for the '{' start character. 
  It validates every incoming byte against the expected protocol rules 
  (checking for 'R', 'C', 'V', commas, and digit ranges). Only fully 
  validated 128-bit frames are released to the parser.

Uart_Parser_New.sv
- Purpose: ASCII to Binary conversion and data unpacking.
- Implementation: Converts 3-digit ASCII decimal values into 8-bit binary 
  integers (0-255). It bundles the Row, Column, and Pixel values into a 
  single 24-bit data packet for the system FSM.

FSM_Rx.sv
- Purpose: Receiver-side Command Manager.
- Implementation: Acts as the interface between the Parser and the Display 
  Controller. It latches the 24-bit packet into registers representing 
  Row Index, Column Index, and Pixel Value upon a "ready" pulse.

FSM_tx.sv
- Purpose: Transmitter-side Flow Control.
- Implementation: Manages the sequence of outgoing data. It handles 
  inter-byte delays (speed control) and automatically inserts special 
  formatting characters like Spaces, Carriage Returns, and Line Feeds.

seg_controller.sv
- Purpose: 8-Digit 7-Segment Multiplexed Display Controller.
- Implementation: Generates a 400Hz refresh rate to multiplex 8 anodes. 
  It includes a hex-to-seven-segment decoder and logic to toggle display 
  modes between transmitted data and received data.

system_controller.sv
- Purpose: Global System Manager and Button Debouncer.
- Implementation: Monitors the center button for long-press events (1 second) 
  to trigger transmissions or enable the receiver. It also latches input 
  parameters (Speed, Data Size) into the system.

3. TECHNICAL SPECIFICATIONS
---------------------------
- System Clock: 100 MHz.
- Baud Rate: 57,600 bps.
- Protocol: 8-N-2 (8 Data bits, No parity, 2 Stop bits for Tx).
- Noise Reduction: 5x Oversampling + Majority Voting.
- Input Range Verification: Decimal range 000-255 validated in hardware.

================================================================================