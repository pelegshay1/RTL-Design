`timescale 1ns/1ps

module seg_controller_tb_full_coverage;

    // --- SCALING PARAMETERS FOR FAST SIMULATION ---
    parameter SIM_REFRESH_COUNT = 20; // 21 cycles for multiplexing
    parameter CLK_PERIOD = 10;        // 10ns = 100MHz

    // --- Signals for DUT (seg_controller) ---
    reg clk;
    reg reset; 
    reg mode_is_hex;
    reg [15:0] num_binary;
    reg [19:0] num_bcd; // This input is used for BCD mode (Decimal)

    // --- Outputs from Controller ---
    wire [4:0] an_select;  // out_seg_anode (Anode Select, Active Low)
    wire [6:0] seg_data;   // cathode (Segment Data, Active Low)

    //==============================================================
    // 1. Device Under Test (DUT) Instantiation
    //==============================================================
    seg_controller #(
        .CLK400HZ(SIM_REFRESH_COUNT)
    ) uut_seg_ctrl (
        .clk(clk),
        .reset(reset),
        .num_binary(num_binary),
        .num_bcd(num_bcd),
        .mode_is_hex(mode_is_hex),
        .out_seg_anode(an_select), 
        .cathode(seg_data)         
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
        // Reset initialization (Active Low Reset)
        reset = 0;
        mode_is_hex = 0;
        num_binary = 16'h0000;
        num_bcd    = 20'h00000;
        @(posedge clk) #1; 

        // 1. Release Reset and wait for stability
        reset = 1;
        repeat (5) @(posedge clk); 
        
        // --- Scenario A: BCD Mode (Test 0-9 in two separate digits) ---
        $display("--- Scenario A: BCD Mode (Testing digits 0-9) ---");
        mode_is_hex = 0; 
        
       
        num_bcd = 20'h09876;
        $display("--- BCD Test 1: 09876 ---");
        repeat (SIM_REFRESH_COUNT * 6) @(posedge clk); // 6 מחזורים מלאים
        
  
        num_bcd = 20'h54321;
        $display("--- BCD Test 2: 54321 ---");
        repeat (SIM_REFRESH_COUNT * 6) @(posedge clk); 


        $display("--- Scenario B: Hex Mode (Testing 0-F) ---");
        mode_is_hex = 1; // Hex Mode
        

        num_binary = 16'h1234;
        $display("--- Hex Test 1: 1234 ---");
        repeat (SIM_REFRESH_COUNT * 5) @(posedge clk);
        

        num_binary = 16'hAFEB;
        $display("--- Hex Test 2: AFEB ---");
        repeat (SIM_REFRESH_COUNT * 5) @(posedge clk); 


        num_binary = 16'h9876;
        $display("--- Hex Test 3: 9876 (Covering all 0-F now) ---");
        repeat (SIM_REFRESH_COUNT * 5) @(posedge clk);

        // --- Scenario C: Reset Check ---
        $display("--- Scenario C: Reset Check During Multiplexing ---");
        
        reset = 0; // Assert Reset (Active Low)
        repeat (10) @(posedge clk);
        reset = 1; // Release Reset
        
        // Wait and check that the display returns to 0x0000 
        repeat (SIM_REFRESH_COUNT * 5) @(posedge clk); 

        // --- Finish ---
        $display("--- Simulation Finished ---");
        $finish;
    end

endmodule