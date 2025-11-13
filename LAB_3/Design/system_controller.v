/*
 * Module: system_controller
 *
 * Description:
 * This is the "brain" of the system. It encapsulates all
 * state management and input-handling logic.
 * - It takes raw button inputs.
 * - It decides when to latch a new value from the switches.
 * - It decides what the current display mode (Hex/Dec) should be.
 *
 * It outputs the two main states for the rest of the system to use, and the latched num- binary value
 */
module system_controller #(
    parameter CLK_FREQ = 100_000_000
) (
    input wire clk,
    input wire reset, // Active-Low reset
    
    // Raw inputs from the physical board - Switches and push - buttons
    input wire [15:0] sw,
    input wire btn_c,
    input wire btn_d,
    
    // Clean "State" outputs
    output reg [15:0] latched_switch_value, // The value to be displayed
    output reg display_is_hex       // 1 = Hex, 0 = Decimal
);

  
    wire btn_c_long_press_event;
    wire btn_c_short_press_event;


//===========================================================================================================
  // --- 1. Smart Controller for Button Center (btn_c) ---
  //This code should detect if a Long pressed or a Short Pressed event happened with center Button input
 reg btn_sync1, btn_sync2;

    wire btn_stable; // This is the stable, synchronized button signal

    always @(posedge clk) begin
        btn_sync1 <= btn_c;
        btn_sync2 <= btn_sync1;
    end
    assign btn_stable = btn_sync2;

    // --- 3. Timer and Long-Press Flag Logic ---
    reg [$clog2(CLK_FREQ)-1:0] timer_reg;
    wire one_sec_reached = (timer_reg == CLK_FREQ-1);
    
    // This flag is crucial. It "remembers" if a long press has
    // already occurred during this specific press cycle.
    // This prevents a 'short_press_event' from firing
    // when the user *releases* the button after a long press.
    reg long_press_fired_reg; 

    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            timer_reg <= 0;
            long_press_fired_reg <= 1'b0;
        end else if (btn_stable) begin // --- Button is PRESSED ---
            if (!one_sec_reached) begin
                timer_reg <= timer_reg + 1; // Count up to 1 second
            end

            // If we've reached 1 second AND we haven't fired the flag yet
            if (one_sec_reached && !long_press_fired_reg) begin
                long_press_fired_reg <= 1'b1; // Set the flag
            end
        end else begin // --- Button is RELEASED ---
            // As soon as the button is released, reset everything
            timer_reg <= 0;
            long_press_fired_reg <= 1'b0;
        end
    end

    // --- 4. Event Pulse Generation (Edge Detectors) ---

    // 4a. Long Press Event:
    //Rising edge detector on one_sec_reached to signal a Long press event
    reg one_sec_reached_prev;
    always @(posedge clk) begin
        one_sec_reached_prev <= one_sec_reached;
    end
    
    // The event fires when the signal is '1' now but was '0' last cycle
    //This signals note that a long press event happened
    assign btn_c_long_press_event = (one_sec_reached == 1'b1) && (one_sec_reached_prev == 1'b0);


    // 4b. Short Press Event:
    // We need a falling-edge detector on 'btn_stable' to know
    // *when* the button was released.
    reg btn_stable_prev;
    always @(posedge clk) begin
        btn_stable_prev <= btn_stable;
    end
    
    // Pulse fires when the signal was '1' last cycle and is '0' now
    wire btn_released_event = (btn_stable_prev == 1'b1) && (btn_stable == 1'b0);

    // The 'short_press_event' fires ONLY IF:
    // 1. The button was just released (btn_released_event)
    // 2. The long press flag was *never* set (long_press_fired_reg is false)
    assign btn_c_short_press_event = btn_released_event && !long_press_fired_reg;



//===========================================================================================================
    // --- 2. Simple Press Detector for Button Down (btn_d) Latching block and represetation method---


    // This code:
    // A. detect short press of down button 
    //B. latches the sw input into a register according to long press flag
    //C. Decides the number representation ( Hex or Decimal) according to center and down push buttons short press flags


    reg btn_d_sync1, btn_d_sync2, btn_d_prev;
    // Input stable block for down- push button
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            btn_d_sync1 <= 1'b0;
            btn_d_sync2 <= 1'b0;
            btn_d_prev  <= 1'b0;
        end else begin
            btn_d_sync1 <= btn_d;
            btn_d_sync2 <= btn_d_sync1;
            btn_d_prev  <= btn_d_sync2;
        end
    end
    // Rising edge detector for stabled down- push button short pressed event
    wire btn_d_short_press_event = (btn_d_sync2 == 1'b1) && (btn_d_prev == 1'b0);

    // --- 3. State Register: Latched Value ---
    // If a long-pressed happened - 
    //Latching the sw input from the board into latched_switch_value output register
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            latched_switch_value <= 16'h0000;
        end else if (btn_c_long_press_event) begin 
            latched_switch_value <= sw;
        end
    end

    // --- 4. State Register: Display Mode ---
always @(posedge clk or negedge reset) begin
    if (!reset) begin
        display_is_hex <= 1'b0; 
    end 
    else begin
        if (btn_d_short_press_event) begin
            display_is_hex <= 1'b1;
        end 
        else if (btn_c_short_press_event || btn_c_long_press_event) begin
            display_is_hex <= 1'b0;
        end else begin
            display_is_hex <= display_is_hex;
        end
    end
end

endmodule