`timescale 1ns/1ps

module top_level_tb;

    // --- 1. SCALING PARAMETERS FOR FAST SIMULATION ---
    parameter SIM_CLK_FREQ = 100_000_000;
    parameter SIM_ONE_SEC_COUNT = 200;  // Long Press limit (201 cycles)
    parameter SIM_REFRESH_COUNT = 20;   // Multiplexing rate (21 cycles)
    parameter CLK_PERIOD = 10;          // 10ns = 100MHz

    // --- 2. Signals for DUT (Matching top_level ports) ---
    reg clk;
    reg reset; 
    reg [15:0] num_in; 
    reg btn_c; // Center button
    reg btn_d; // Down button
    
    // Outputs
    wire [6:0] seg_catode; // Segment Data (Cathode)
    wire [4:0] seg_anode;  // Anode Select

    // --- 3. Internal Wires/Signals ---
    wire [19:0] num_bcd;
    wire [15:0] latched_num;
    wire display_is_hex;

    //==============================================================
    // 4. Module Instantiation (Replicating top_level with scaling)
    //==============================================================

    // 4.1 System Controller (Scaled for Long Press Check)
    system_controller #(
        .CLK_FREQ(SIM_ONE_SEC_COUNT) // We override CLK_FREQ to set the counter limit directly
    ) u_sys_ctrl (
        .clk(clk),
        .reset(reset),
        .sw(num_in),
        .btn_c(btn_c),
        .btn_d(btn_d),
        .latched_switch_value(latched_num),
        .display_is_hex(display_is_hex)
    );

    // 4.2 Binary to BCD Converter 
    binary_to_bcd_16_bit u_bcd_converter (
        .binary_in(latched_num),
        .bcd_ones(num_bcd[3:0]),
        .bcd_tens(num_bcd[7:4]),
        .bcd_hundreds(num_bcd[11:8]),
        .bcd_thousands(num_bcd[15:12]),
        .bcd_tens_thousands(num_bcd[19:16])
    );

    // 4.3 Segment Controller (Scaled for Multiplexing Speed)
    seg_controller #(
        .CLK400HZ(SIM_REFRESH_COUNT)
    ) u_seg_ctrl (
        .clk(clk),
        .reset(reset),
        .num_binary(latched_num),
        .num_bcd(num_bcd),
        .mode_is_hex(display_is_hex),
        .out_seg_anode(seg_anode),
        .cathode(seg_catode)
    );

    //==============================================================
    // 5. Clock Generation
    //==============================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //==============================================================
    // 6. Test Scenarios (Flow Control)
    //==============================================================

    initial begin
        // Initialization (Active Low Reset - Asserted)
        reset = 0; 
        num_in = 16'hFFFF;
        btn_c = 0;
        btn_d = 0;
        
        @(posedge clk) #1; 

        // 1. Release Reset and wait for stability (Initial state is DEC: 0x0000, is_hex=0)
        reset = 1;
        repeat (5) @(posedge clk); 
        
        // -----------------------------------------------------------------
        // SCENARIO A: LATCH VALUE (Long Press on btn_c)
        // Latch 0xBEEF (48879 Dec)
        // -----------------------------------------------------------------
        $display("Time=%0t: SCENARIO A: Latching 0xBEEF (48879 Dec)", $time);
        num_in = 16'hBEEF; 
        
        // Long Press: Hold for 50 cycles beyond the 200 cycle limit
        btn_c = 1;
        repeat (SIM_ONE_SEC_COUNT + 50) @(posedge clk); 
        btn_c = 0; 
        
        // Check: latched_num should be 0xBEEF. Mode should remain Decimal (0).
        repeat (SIM_REFRESH_COUNT * 5) @(posedge clk);


        // -----------------------------------------------------------------
        // SCENARIO B: TOGGLE MODE TO HEX (btn_d)
        // -----------------------------------------------------------------
        $display("Time=%0t: SCENARIO B: Toggle Mode to HEX via btn_d", $time);
        
        // Simple Press on btn_d to toggle mode to HEX (1)
        btn_d = 1;
        @(posedge clk) #1;
        btn_d = 0;
        
        // Check: display_is_hex should be 1. Display should switch to B.E.E.F.
        repeat (SIM_REFRESH_COUNT * 5) @(posedge clk);


        // -----------------------------------------------------------------
        // SCENARIO C: TOGGLE MODE TO DECIMAL (btn_c)
        // -----------------------------------------------------------------
        $display("Time=%0t: SCENARIO C: Toggle Mode to DEC via btn_c", $time);
        
        // Short Press on btn_c to toggle mode back to DECIMAL (0)
        btn_c = 1;
        repeat (50) @(posedge clk); // Below the long press limit
        btn_c = 0;
        
        // Check: display_is_hex should be 0. Display should switch to 4.8.8.7.9.
        repeat (SIM_REFRESH_COUNT * 5) @(posedge clk);


        // -----------------------------------------------------------------
        // SCENARIO D: FULL SYSTEM RESET CHECK
        // -----------------------------------------------------------------
        $display("Time=%0t: SCENARIO D: Triggering Final Reset Check", $time);
        
        // Assert Reset (Active Low)
        reset = 0;
        repeat (10) @(posedge clk);
        reset = 1;
        
        // Check: latched_num should be 0x0000, display_is_hex should be 0 (Decimal).
        repeat (SIM_REFRESH_COUNT * 5) @(posedge clk);
        
        // --- END SIMULATION ---
        $display("--- Simulation Finished ---");
        $finish;
    end

endmodule