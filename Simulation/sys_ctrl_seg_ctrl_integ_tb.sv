//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.11.2025 14:49:45
// Design Name:
// Module Name: integration_tb
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

module integration_tb ;

    // --- 1. Parameters & Constants ---
    // Reduced frequency for faster simulation of 1-sec press
    localparam CLK_FREQ_TB = 1000;
    localparam T_CLK = 10; // 100 MHz clock period

    // --- 2. TB Signals ---
    reg clk;
    reg reset;

    // System Controller Inputs
    reg btn_c;
    reg [7:0] sw_num;          // Input from switches (Byte to send)
    reg [1:0] sw_speed;        // Input from switches (Speed config)
    reg [1:0] sw_num_of_bytes; // Input from switches (Total bytes config)

    // Simulated External Counter (from FSM)
    reg [7:0] byte_count_sim;

    // Interconnect Wires (System Controller -> Segment Controller)
    wire one_sec_push;       // Debug/Internal use
    wire [7:0] latched_num;
    wire [7:0] latched_speed;
    wire [7:0] latched_num_of_bytes;

    // Outputs from Segment Controller (to Display)
    wire [7:0] cathode;
    wire [7:0] anode;

    // --- 3. Instantiate Modules ---

    // 3.1 System Controller (UUT 1)
    system_controller #(.CLK_FREQ(CLK_FREQ_TB)) sys_ctrl_inst (
        .clk(clk),
        .reset(reset),
        .btn_c(btn_c),
        .one_sec_push(one_sec_push),
        .num(sw_num),
        .latched_num(latched_num),
        .speed(sw_speed),
        .latched_speed(latched_speed),
        .num_of_bytes(sw_num_of_bytes),
        .latched_num_of_bytes(latched_num_of_bytes)
    );

    // 3.2 Segment Controller (UUT 2)
    // Using default refresh rate or faster for simulation visibility
    seg_controller #(.CLK400HZ(100)) seg_ctrl_inst (
        .clk(clk),
        .reset(reset),
        .num(latched_num),               // Connected to latch
        .speed(latched_speed),           // Connected to latch
        .num_of_bytes(latched_num_of_bytes), // Connected to latch
        .byte_count(byte_count_sim),     // Connected to TB simulated counter
        .cathode(cathode),
        .anode(anode)
    );

    // --- 4. Clock Generation ---
    initial begin
        clk = 0;
        forever #(T_CLK / 2) clk = ~clk;
    end

    // --- 5. Test Stimulus ---
    initial begin
        // 5.1 Initialize Inputs
        reset = 1;
        btn_c = 0;
        sw_num = 8'h00;
        sw_speed = 2'b00;
        sw_num_of_bytes = 2'b00;
        byte_count_sim = 8'h00;

        // 5.2 Reset Sequence
        #50;
        reset = 0; // Active Low Reset
        #50;
        reset = 1; // Release Reset
        $display("Time: %0t | System Reset Complete", $time);

        // ============================================================
        // TEST 1: Latch Data via Long Press
        // ============================================================
        $display("\n--- TEST 1: Latching Data (Long Press) ---");

        // Set desired values on switches
        sw_num = 8'hAB;           // Data to latch
        sw_speed = 2'd2;          // Speed index 2 -> Expect latched value 0x10
        sw_num_of_bytes = 2'd1;   // Bytes index 1 -> Expect latched value 0x20

        // Perform Long Press
        btn_c = 1;
        #((CLK_FREQ_TB + 5) * T_CLK); // Wait for > 1 sec (simulated)
        btn_c = 0;

        #100; // Wait for stabilization

        // Check if values were latched correctly
        if (latched_num === 8'hAB && latched_speed === 8'h10 && latched_num_of_bytes === 8'h20) begin
            $display("Time: %0t | SUCCESS: Data Latched Correctly: Num=%h, Speed=%h, Bytes=%h",
                $time, latched_num, latched_speed, latched_num_of_bytes);
        end else begin
            $display("Time: %0t | FAILURE: Latch Mismatch! Latched: %h, %h, %h",
                $time, latched_num, latched_speed, latched_num_of_bytes);
        end

        // ============================================================
        // TEST 2: Simulate External Byte Counter (0 to 255)
        // ============================================================
        $display("\n--- TEST 2: Simulating Byte Counter (0-255) ---");

        // Loop to increment the simulated FSM counter
        // The segment controller should display this value on the last 2 digits
        repeat (256) begin
            #1200; // Wait a bit between increments
            byte_count_sim = byte_count_sim + 1;
        end

        $display("Time: %0t | Counter simulation finished.", $time);

        // ============================================================
        // TEST 3: Verify Segment Scanning (Visual Check in Waveform)
        // ============================================================
        $display("\n--- TEST 3: Running for display scanning ---");
        // Let simulation run to observe Anode switching in waveform
        #2000;

        $finish;
    end

endmodule

