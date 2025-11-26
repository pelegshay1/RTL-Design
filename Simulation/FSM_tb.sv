`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: fsm_tb
// Description: Test Bench for the System-Level UART Controller (FSM).
//              Verifies state transitions, inter-byte delay skipping,
//              CR/LF sequence generation, and total byte counting.
//////////////////////////////////////////////////////////////////////////////////

module fsm_tb ;

    // --- 1. TB Parameters and Constants ---
    localparam CLK_FREQ = 100_000_000;
    localparam T_CLK = 10; // 10 ns period


    // --- 2. TB Signals (REG for inputs, WIRE for outputs) ---
    reg  clk;
    reg  reset;
    reg  write_en;
    reg  [7:0] num_of_bytes;
    reg  [7:0] speed;
    reg  end_of_byte; // Simulation of Tx PHY 'done' signal
    reg  [7:0] data_tx;       // Input: The data to be sent (from latched SW[7:0])

    // Outputs to monitor
    wire led;
    wire [7:0] total_row_count;
    wire [7:0] byte_to_send;
    wire tx_start;

    logic row_count;

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
        .data_tx(data_tx),           // Connect the new data input

        .led(led),
        .total_row_count(total_row_count),
        .byte_to_send(byte_to_send),
        .tx_start(tx_start),
        .finished(finished)
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
        data_tx = 8'hAA;     // The byte we are testing (0xAA)

        #20 reset = 0; // Active Low Reset
        #20 reset = 1;
        $display("Time: %0t | System Reset Complete. State: IDLE", $time);


        // ====================================================================
        // TEST 1: Standard Transmission (256 Bytes  No Delay)
        // ====================================================================
        #50;
        $display("\n--- Test 1: Standard 32 Bytes (Target %d) ---", 8'd5);
        num_of_bytes = 8'd255; // Target: 32
        speed = 8'h00;          // 0 delay

        // Trigger FSM start
        write_en = 1;
        #10;
        @(negedge clk);
        write_en = 0;   


        // Loop: 5 Data + 5 Delimiters = 10 transmissions total
        // We wait for the tx_start pulse as the trigger for the simulation
        while (!finished) begin

            @(posedge clk) while (tx_start == 0) #1; // Wait for FSM to assert start pulse

            if (tx_start) begin

                if (byte_to_send == 8'hAA) begin
                    // Case 1: Data Byte
                    $display("Time: %0t | [DATA] Sending: %h (0xAA) | Ctr: %d", $time, total_row_count, led);
                end else if (byte_to_send == 8'h20) begin
                    // Case 2: Space Delimiter
                    $display("Time: %0t | [SPECIAL] Sending Space (0x20)", $time);
                end else if (byte_to_send == 8'h0D) begin
                    // Case 3: Carriage Return (CR)
                    $display("Time: %0t | [EOL] Sending CR (0x0D) - Phase 1", $time);
                end else if (byte_to_send == 8'h0A) begin
                    // Case 4: Line Feed (LF)
                    $display("Time: %0t | [EOL] Sending LF (0x0A) - Phase 2", $time);
                end else begin
                    // Warning
                    $display("Time: %0t | WARNING: Unexpected Byte %h", $time, byte_to_send);
                end


                pulse_end_of_byte; // Simulate Tx PHY completion (moves FSM to next state)
                #10;
                
            end
            row_count = total_row_count;
        end

        #50;


        // ====================================================================
        // TEST 2: Standard Transmission (128 bytes)
        // ====================================================================
        #50;
        $display("\n--- Test 2: Standard 32 Bytes (Target %d) ---", 8'd5);
        num_of_bytes = 8'h80; // Target: 32
        speed = 8'h00;          // 0 delay

        // Trigger FSM start
        write_en = 1;
        #3;
        write_en = 0;   


        // Loop: 5 Data + 5 Delimiters = 10 transmissions total
        // We wait for the tx_start pulse as the trigger for the simulation
        while (!finished) begin

            @(posedge clk) while (tx_start == 0) #1; // Wait for FSM to assert start pulse

            if (tx_start) begin

                if (byte_to_send == 8'hAA) begin
                    // Case 1: Data Byte
                    $display("Time: %0t | [DATA] Sending: %h (0xAA) | Ctr: %d", $time, total_row_count, led);
                end else if (byte_to_send == 8'h20) begin
                    // Case 2: Space Delimiter
                    $display("Time: %0t | [SPECIAL] Sending Space (0x20)", $time);
                end else if (byte_to_send == 8'h0D) begin
                    // Case 3: Carriage Return (CR)
                    $display("Time: %0t | [EOL] Sending CR (0x0D) - Phase 1", $time);
                end else if (byte_to_send == 8'h0A) begin
                    // Case 4: Line Feed (LF)
                    $display("Time: %0t | [EOL] Sending LF (0x0A) - Phase 2", $time);
                end else begin
                    // Warning
                    $display("Time: %0t | WARNING: Unexpected Byte %h", $time, byte_to_send);
                end


                pulse_end_of_byte; // Simulate Tx PHY completion (moves FSM to next state)
                #10;
                
            end
            row_count = total_row_count;
        end

        #50;



        // ====================================================================
        // TEST 3: End Of Line (CR/LF) Sequence (Sending 32 Bytes)
        // ====================================================================
        #100;
        $display("\n--- Test 2: EOL Sequence (Row Width = 32, Total = 32) ---");

        // Set new data and target (32 bytes is 1 full row)
        data_tx = 8'hBB;
        num_of_bytes = 8'd32;
        speed= 8'h00;

        // Trigger start
        write_en = 1;
        #10 write_en = 0;

        // Loop: Run for 32 Data + 32 Delimiters (The final two are CR/LF)
        // We run 64 iterations, checking the last two for 0D and 0A
        while (!finished) begin
            @(posedge clk) while (tx_start == 0) #1;
            if (tx_start) begin

                // CR/LF Logic Check (This should happen on the last 2 cycles)
                if (byte_to_send == 8'h0D) $display("Time: %0t | EOL Phase 1: Sending CR (0x0D)", $time);
                else if (byte_to_send == 8'h0A) $display("Time: %0t | EOL Phase 2: Sending LF (0x0A)", $time);
                else if (byte_to_send == 8'hBB) $display("Time: %0t | DATA Byte Sent: 0xBB (Count %d)", $time, total_row_count);
                else if (byte_to_send == 8'h20) $display("Time: %0t | Space Sent", $time);

                pulse_end_of_byte;
            end
        end

        #50 $finish;
    end
endmodule