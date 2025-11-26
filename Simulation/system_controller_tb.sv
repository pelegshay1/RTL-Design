//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 26.11.2025 20:44:35
// Design Name:
// Module Name: system_controller_tb
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

module system_controller_tb ;

    // --- 0. Parameters for Quick Testing ---
    // Reduced CLK_FREQ for simulation (1000 cycles for 1-second press)
    localparam CLK_FREQ_TB = 1000;
    localparam T_CLK = 10;              // Clock Period: 10 ns (100 MHz)

    // --- 1. TB Signals (Inputs are REG, Outputs are WIRE) ---
    reg  clk;
    reg  reset;
    reg  btn_c;
    reg  [7:0] num;
    reg  [1:0] speed;
    reg  [1:0] num_of_bytes_in;

    // Outputs to monitor
    wire one_sec_push;       // The 1-cycle pulse from the FSM
    wire [7:0] latched_num;  // Latched data value
    wire [7:0] latched_speed;
    wire [7:0] latched_num_of_bytes;

    // 2. Instantiate Unit Under Test (UUT)
    system_controller #(.CLK_FREQ(CLK_FREQ_TB)) uut (
        .clk(clk),
        .reset(reset),
        .btn_c(btn_c),
        .one_sec_push(one_sec_push),
        .num(num),
        .latched_num(latched_num),
        .speed(speed),
        .latched_speed(latched_speed),
        .num_of_bytes(num_of_bytes_in),
        .latched_num_of_bytes(latched_num_of_bytes)
    );

    // 3. Clock Generation
    initial begin
        clk = 0;
        forever #(T_CLK / 2) clk = ~clk;
    end

    // 4. Test Stimulus
    initial begin
        // 4.1 Initial Reset and Setup
        reset = 1;
        btn_c = 0;
        num = 8'hBB;
        speed = 2'h3;
        num_of_bytes_in = 2'h1;

        #20;
        reset = 0; // Active Low Reset
        #20;
        reset = 1; // Release Reset
        $display("Time: %0t | System Ready.", $time);

        // ====================================================================
        // TEST 1: Long Press Event (Verify 1-cycle pulse and data latch)
        // ====================================================================
        #50;
        $display("\n--- TEST 1: Long Press (Target %d cycles) ---", CLK_FREQ_TB);
        btn_c = 1; // Press the button
        $display("Time: %0t | Button Pressed.", $time);

        // Hold button for press duration + 2 cycles for stability
        #((CLK_FREQ_TB + 2) * T_CLK);

        // Verification: Check if the pulse was asserted
        if (one_sec_push == 1) begin
            $display("Time: %0t | SUCCESS: one_sec_push asserted. Checking pulse width...", $time);

            // Check pulse width: Should be HIGH for exactly 1 cycle
            @(negedge clk);
            #1;
            if (one_sec_push == 1) begin
                $display("Time: %0t | FAILURE: one_sec_push is still HIGH. Pulse is > 1 cycle.", $time);
            end else begin
                $display("Time: %0t | SUCCESS: Pulse width is exactly 1 clock cycle.", $time);
            end
        end else begin
            $display("Time: %0t | FAILURE: one_sec_push never asserted.", $time);
        end

        // Release the button
        btn_c = 0;
        $display("Time: %0t | Button Released. Latch reset.", $time);


        // ====================================================================
        // TEST 2: Short Press (Verify NO Trigger)
        // ====================================================================
        #100;
        $display("\n--- TEST 2: Short Press (Expected NO push) ---");
        btn_c = 1;
        $display("Time: %0t | Button Pressed.", $time);

        // Hold button for half the required time
        #((CLK_FREQ_TB / 2) * T_CLK);

        // Release the button before the timer reaches target
        btn_c = 0;
        $display("Time: %0t | Button Released prematurely.", $time);

        #100;

        if (one_sec_push == 0) begin
            $display("Time: %0t | SUCCESS: one_sec_push was correctly NOT asserted for short press.", $time);
        end else begin
            $display("Time: %0t | FAILURE: one_sec_push asserted unexpectedly.", $time);
        end

        // ====================================================================
        // TEST 3: Verification of Latched Data Update
        // ====================================================================
        #100;
        $display("\n--- TEST 3: Verification of Latched Data Update ---");
        // Set new values and run a new long press
        num = 8'h1A;
        speed = 2'h0; // New speed config
        num_of_bytes_in = 2'h3; // New byte config

        btn_c = 1;
        #((CLK_FREQ_TB + 2) * T_CLK);
        btn_c = 0;

        // Final verification of latched outputs
        #10;
        $display("Time: %0t | Latch verification complete.", $time);
        $display("   Data (expected 1A): %h (LATCHED)", latched_num);
        $display("   Speed (expected 00): %h (LATCHED)", latched_speed);
        $display("   Bytes (expected FF): %h (LATCHED)", latched_num_of_bytes);


        #100 $finish;
    end

    // Monitors the rising edge of the pulse
    always @(posedge one_sec_push) begin
        $display("Time: %0t | *** one_sec_push RISING EDGE *** (Start of 1-cycle pulse)", $time);
    end

endmodule