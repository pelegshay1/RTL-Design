`timescale 1ns/1ps

module system_controller_tb;

    // --- SCALING PARAMETERS FOR FAST SIMULATION ---
    parameter SIM_CLK_FREQ_COUNT = 200; // The actual target count (0 to 200 = 201 cycles)
    parameter CLK_PERIOD = 10;          // 10ns = 100MHz clock period.

    // --- Signals for DUT ---
    reg clk;
    reg reset; 
    reg [15:0] sw_input;
    reg btn_c_in; // Center button
    reg btn_d_in; // Down button

    // --- Outputs from Controller ---
    wire [15:0] latched_value;
    wire display_mode; // display_is_hex (1=Hex, 0=Dec)

    //==============================================================
    // 1. Device Under Test (DUT) Instantiation
    //==============================================================
    // We instantiate the DUT and override the CLK_FREQ parameter 
    // to control the ONE_SEC_COUNT derived value (100M-1 becomes 200).
    system_controller #(
        .CLK_FREQ(SIM_CLK_FREQ_COUNT) 
    ) uut_sys_ctrl (
        .clk(clk),
        .reset(reset),
        .sw(sw_input),
        .btn_c(btn_c_in),
        .btn_d(btn_d_in),
        .latched_switch_value(latched_value),
        .display_is_hex(display_mode)
    );

    //==============================================================
    // 2. Clock Generation
    //==============================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //==============================================================
    // 3. Test Scenarios
    //==============================================================
    initial begin
        // 3.1 INITIALIZATION (Active Low Reset)
        reset = 0; // Assert Reset (Active Low)
        sw_input = 16'hFFFF;
        btn_c_in = 0;
        btn_d_in = 0;
        
        @(posedge clk) #1; 
        
        // Assertions check: After reset, should be 0x0000 and Hex mode (1)
        $display("Time=%0t: Initial Reset Check. Latched=%h, Mode=%b", $time, latched_value, display_mode);
        
        // 3.2 RELEASE RESET
        reset = 1;
        repeat (5) @(posedge clk); 

        // -----------------------------------------------------------------
        // SCENARIO A: LONG PRESS (btn_c) -> Latch Value
        // -----------------------------------------------------------------
        $display("Time=%0t: SCENARIO A: Testing Long Press (Latch Value)", $time);
        
        sw_input = 16'hDEAD; // New input value
        
        // 1. Press and hold (SIM_CLK_FREQ_COUNT + 50 cycles total)
        btn_c_in = 1;
        repeat (SIM_CLK_FREQ_COUNT + 50) @(posedge clk); 
        
        // 2. Release
        btn_c_in = 0;
        
        // Check: Value should be latched (0xDEAD). Mode should remain dec. (1).
        $display("Time=%0t: Long Press Complete. Latched Value expected=DEAD, Actual=%h", $time, latched_value);


        // -----------------------------------------------------------------
        // SCENARIO B: SHORT PRESS (btn_c) -> Toggle Mode to Decimal
        // -----------------------------------------------------------------
        $display("Time=%0t: SCENARIO B: Testing Short Press (Toggle to DEC)", $time);
        
        // 1. Press and release quickly (50 cycles total) - below the 200 limit
        btn_c_in = 1;
        repeat (50) @(posedge clk);
        btn_c_in = 0;
        
        // Check: Mode should toggle to Decimal (0). Latched value should remain 0xDEAD.
        $display("Time=%0t: Short Press Complete. Mode expected=0, Actual=%b", $time, display_mode);


        // -----------------------------------------------------------------
        // SCENARIO C: SIMPLE PRESS (btn_d) -> Toggle Mode to Hex
        // -----------------------------------------------------------------
        $display("Time=%0t: SCENARIO C: Testing Simple Press (Toggle to HEX)", $time);
        
        // 1. Press and release btn_d
        btn_d_in = 1;
        @(posedge clk) #1;
        btn_d_in = 0;
        
        // Check: Mode should toggle back to Hex (1). Latched value remains 0xDEAD.
        $display("Time=%0t: Down Press Complete. Mode expected=1, Actual=%b", $time, display_mode);


        // -----------------------------------------------------------------
        // SCENARIO D: Reset Check (Verification)
        // -----------------------------------------------------------------
        $display("Time=%0t: SCENARIO D: Triggering Final Reset Check", $time);
        sw_input = 16'hBEEF; 
        
  
        $display("Time=%0t: Reset Released. Latched Value=%h, Mode=%b", $time, latched_value, display_mode);


        // -----------------------------------------------------------------
        // END SIMULATION
        // -----------------------------------------------------------------
        repeat (20) @(posedge clk); 
        $finish;
    end

endmodule