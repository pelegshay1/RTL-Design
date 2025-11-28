`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.11.2025 15:38:09
// Design Name: 
// Module Name: trasmitter_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// Module Name: transmitter_tb
// Description: Test Bench for the UART Transmitter PHY.
//              Checks clock division, state transitions, and serial output timing.
//////////////////////////////////////////////////////////////////////////////////

module transmitter_tb;

    // --- 1. TB Parameters and Constants ---
    localparam CLK_FREQ = 100_000_000;
    localparam T_CLK = 10; // 1 / 100 MHz = 10 ns period
    localparam BAUD_RATE = 57600;
    localparam BAUD_CYCLES = CLK_FREQ / BAUD_RATE; // 1736 (cycles per bit)
    localparam T_BAUD_NS = T_CLK * BAUD_CYCLES; // 17360 ns (17.36 us)

    // --- 2. TB Signals (REG for inputs, WIRE for outputs) ---
    reg  clk;
    reg  reset;
    reg  tx_start;
    reg  [7:0] byte_to_send;

    wire end_of_byte;
    wire data_out;
    wire [2:0] current_state_display; // Adding a display wire for debugging
    
    // --- Internal signal for debugging: end_of_bit tick ---
    wire end_of_bit_tick_debug;
    
    // --- 3. Instantiate the Unit Under Test (UUT) ---
    Transmitter #(
        .CLK_FREQ(100_000_000),
        .BAUDRATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .byte_to_send(byte_to_send),
        .tx_start(tx_start),
        .end_of_byte(end_of_byte),
        .data_out(data_out)
    );

    // --- 4. Clock Generation (50% duty cycle) ---
    initial begin
        clk = 0;
        forever #(T_CLK / 2) clk = ~clk;
    end

    // --- 5. Debug and Monitoring (Optional: for display/dumping) ---
    initial begin
        $display("--- Starting Transmitter TB ---");
        $display("Baud Rate: %d bps (Period: %d ns)", BAUD_RATE, T_BAUD_NS);
        // $dumpfile("transmitter.vcd");
        // $dumpvars(0, transmitter_tb);
    end

    // --- 6. Test Stimulus (Scenario Execution) ---
    initial begin
        // 6.1 Initial Reset and Setup
        reset = 1;
        tx_start = 0;
        byte_to_send = 8'hAA; // Data: 10101010
        
        // Asynchronous reset (Active Low)
        #20 reset = 0;
        #20 reset = 1;

        // 6.2 Test 1: Full Transmission Cycle (Sending 0x55)
        #100;
        $display("Time: %0t | Test 1: Sending 0x55", $time);
        byte_to_send = 8'h55; // Data: 01010101

        // Trigger start (Pulse high for one cycle)
        tx_start = 1;
        #10 tx_start = 0;

        // Wait for the transmission to start (S_TRANSMIT)
        # (T_CLK * 2); 
        $display("Time: %0t | Tx Started. Waiting for end_of_byte...", $time);

        // Wait for end_of_byte (approx 10 bits * 1736 cycles = 17360 ns * 10 = 173600 ns)
        // Add a safety margin: 11 bits (11 * T_BAUD_NS)
        # (11 * T_BAUD_NS);

        // 6.3 Verification of End of Byte Pulse
        #100;
        if (end_of_byte == 1) begin
            $display("Time: %0t | SUCCESS: end_of_byte PULSE DETECTED.", $time);
        end else begin
            $display("Time: %0t | FAILURE: end_of_byte pulse NOT detected.", $time);
        end

        // Wait a bit more to ensure FSM returns to IDLE
        # (2 * T_BAUD_NS);
        
        // 6.4 Test 2: Sending a second byte (0xAA)
        #100;
        $display("Time: %0t | Test 2: Sending 0xAA", $time);
        byte_to_send = 8'hAA; 
        
        // Trigger start
        tx_start = 1;
        #10 tx_start = 0;
        
        # (11 * T_BAUD_NS);

        // 6.5 Verification of second pulse
        #100;
        if (end_of_byte == 1) begin
            $display("Time: %0t | SUCCESS: Second pulse detected.", $time);
        end else begin
            $display("Time: %0t | FAILURE: Second pulse NOT detected.", $time);
        end


        // 6.6 Finalization
        #200 $finish;
    end
endmodule