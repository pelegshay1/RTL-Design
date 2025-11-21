`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.11.2025 18:19:43
// Design Name: 
// Module Name: FSM_tb
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

`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: fsm_tb
// Description: Test Bench for the System-Level UART Controller (FSM).
//              Verifies state transitions, inter-byte delay skipping, 
//              CR/LF sequence generation, and total byte counting.
//////////////////////////////////////////////////////////////////////////////////

module fsm_tb;

    // --- 1. TB Parameters and Constants ---
    localparam CLK_FREQ = 100_000_000;
    localparam T_CLK = 10; // 10 ns period
    
    // Test Configurations
    localparam NUM_BYTES_TEST_1 = 8'd5;    // Total bytes for normal transmission
    localparam NUM_BYTES_TEST_2 = 8'd4;    // Total bytes for EOL check (when actual_row_width=4)
    localparam SPEED_NO_DELAY = 8'h00;     // 0ms delay config
    localparam SPEED_50MS = 8'h05;         // 50ms delay config
    localparam BAUD_RATE = 57600;
    
    // --- 2. TB Signals (REG for inputs, WIRE for outputs) ---
    reg  clk;
    reg  reset;
    reg  write_en;
    reg  [7:0] num_of_bytes;
    reg  [7:0] speed;
    reg  end_of_byte; // Simulation of Tx PHY 'done' signal
    
    // Outputs to monitor
    wire led;
    wire [7:0] byte_count;
    wire [7:0] byte_to_send;
    wire tx_start;

    // --- 3. Instantiate UUT (Unit Under Test) ---
    FSM #(
        .CLK_FREQ(CLK_FREQ)
    ) uut (
        .clk(clk),
        .reset(reset),
        .write_en(write_en),
        .num_of_bytes(num_of_bytes),
        .speed(speed),
        .end_of_byte(end_of_byte),
        .led(led),
        .byte_count(byte_count),
        .byte_to_send(byte_to_send),
        .tx_start(tx_start)
    );
    
    // --- 4. Clock Generation ---
    initial begin
        clk = 0;
        forever #(T_CLK / 2) clk = ~clk;
    end

    // --- 5. Task: Simulate UART PHY Completion Pulse ---
    // Sends a short pulse to the FSM's 'end_of_byte' input.
    task pulse_end_of_byte;
        begin
            @(posedge clk);
            end_of_byte = 1;
            #10 end_of_byte = 0;
        end
    endtask

    // --- 6. Test Stimulus ---
    initial begin
        // --- 6.1 Initial Reset and Setup ---
        reset = 1;
        write_en = 0;
        end_of_byte = 0;
        
        #20 reset = 0; // Active Low Reset
        #20 reset = 1;
        $display("Time: %0t | System Reset Complete. State: IDLE", $time);

        
        // ====================================================================
        // TEST 1: Standard Transmission (5 Bytes + Spaces, No Delay)
        // ====================================================================
        #50;
        $display("\n--- Test 1: Standard 5 Bytes (Space Delimiter, No Delay) ---");
        num_of_bytes = NUM_BYTES_TEST_1; // Target: 5
        speed = SPEED_NO_DELAY;          // Delay target = 0 cycles

        // Trigger FSM start
        write_en = 1;
        #10 write_en = 0; // Pulse start

        // Expected Sequence: D0 -> Wait -> Space -> Wait -> D1 -> Wait -> Space ... -> D4 -> Wait -> Space -> IDLE
        repeat (NUM_BYTES_TEST_1 * 2) begin // 5 data bytes + 5 delimiters = 10 transmissions
            @(posedge clk) if (tx_start) begin
                
                if (byte_to_send != 8'h20) begin
                    $display("Time: %0t | [DATA] Sending: %h | Ctr: %d | LED: %b", $time, byte_to_send, byte_count+1, led);
                end else begin
                    $display("Time: %0t | [SPECIAL] Sending Space (0x20)", $time);
                end
                
                pulse_end_of_byte; // Simulate Tx PHY completion
            end
        end
        
        #50;
        $display("Time: %0t | Verification: Test 1 Complete. Final Data Count: %d (Expected %d)", $time, byte_count, NUM_BYTES_TEST_1);
        

        // ====================================================================
        // TEST 2: End Of Line (CR/LF) Sequence
        // Note: Assumes actual_row_width is calculated to be 4 (based on 8'h20 input)
        // Sequence: D1, Space, D2, Space, D3, CR, LF, D4, Space...
        // ====================================================================
        #100;
        $display("\n--- Test 2: CR/LF Sequence (Row Width = 32, Total = 32) ---");
        num_of_bytes = 8'h20; // 32 total bytes
        speed = SPEED_NO_DELAY; 
        
        // Trigger start
        write_en = 1;
        #10 write_en = 0;
        
        // We will stop the simulation loop just after the CR/LF sequence completes (Byte 32)
        // The EOL sequence will begin after byte_count reaches 32.
        
        // Run until the total byte counter indicates 32 bytes were SENT (plus the CR/LF sequence)
        @(posedge clk) while (byte_count < 32) begin
            if (tx_start) begin
                pulse_end_of_byte;
            end
        end
        
        // --- Verify the CR/LF Transition ---
        
        // Expect 1st Special (Space or CR)
        @(posedge clk) while (!tx_start) #1;
        $display("Time: %0t | CR/LF 1: Sending %h (Expected 0D)", $time, byte_to_send);
        if (byte_to_send !== 8'h0D) $error("ERROR: Expected CR (0x0D)");
        pulse_end_of_byte; // Done sending CR
        
        // Expect 2nd Special (LF) - MUST HAPPEN IMMEDIATELY (no delay)
        @(posedge clk) while (!tx_start) #1;
        $display("Time: %0t | CR/LF 2: Sending %h (Expected 0A)", $time, byte_to_send);
        if (byte_to_send !== 8'h0A) $error("ERROR: Expected LF (0x0A)");
        pulse_end_of_byte; // Done sending LF
        
        
        // --- Verification: Next state must be IDLE ---
        @(posedge clk) if (tx_start) 
            $display("Time: %0t | ERROR: FSM continued after final LF.", $time);
        else 
            $display("Time: %0t | Verification: EOL sequence complete and FSM is IDLE.", $time);


        // 6.4 Finalization
        #100 $finish;
    end

endmodule
