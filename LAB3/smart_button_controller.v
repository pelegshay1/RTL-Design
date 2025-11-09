/*
 * Module: smart_button_controller
 *
 * Description:
 * Takes a raw, noisy button input and detects two distinct events:
 * 1. A 'long_press_event' (a single-cycle pulse) if the button is held
 * for ONE_SEC_COUNT (e.g., 1 second).
 * 2. A 'short_press_event' (a single-cycle pulse) if the button is
 * released *before* the 1-second mark.
 *
 * This uses a timer and a flag to differentiate the two.
 */
module smart_button_controller #(
    parameter CLK_FREQ = 100_000_000 // System clock frequency (100MHz)
) (
    input wire clk,
    input wire reset, // Active-High reset
    input wire btn_in,  // Raw, asynchronous button input
    
    output wire long_press_event,  // Single-cycle pulse on 1-sec hold
    output wire short_press_event // Single-cycle pulse on short release
);

    // --- 1. Constants ---
    // Calculate the number of clock cycles for a 1-second timer
    localparam ONE_SEC_COUNT = CLK_FREQ - 1;

    // --- 2. Input Synchronization (Metastability Protection) ---
    // A 2-flop synchronizer to safely bring the async 'btn_in'
    // into the 'clk' domain.
    reg btn_sync1, btn_sync2;
    wire btn_stable; // This is the stable, synchronized button signal

    always @(posedge clk) begin
        btn_sync1 <= btn_in;
        btn_sync2 <= btn_sync1;
    end
    assign btn_stable = btn_sync2;

    // --- 3. Timer and Long-Press Flag Logic ---
    reg [$clog2(CLK_FREQ)-1:0] timer_reg;
    wire one_sec_reached = (timer_reg == ONE_SEC_COUNT);
    
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
    //falling edge detector on one_sec_reached to signal a Long press event
    reg one_sec_reached_prev;
    always @(posedge clk) begin
        one_sec_reached_prev <= one_sec_reached;
    end
    
    // The event fires when the signal is '1' now but was '0' last cycle
    assign long_press_event = (one_sec_reached == 1'b1) && (one_sec_reached_prev == 1'b0);


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
    assign short_press_event = btn_released_event && !long_press_fired_reg;

endmodule