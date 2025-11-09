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
 * It outputs the two main states for the rest of the system to use.
 */
module system_controller #(
    parameter CLK_FREQ = 100_000_000
) (
    input wire clk,
    input wire reset, // Active-Low reset
    
    // Raw inputs from the physical board
    input wire [15:0] sw,
    input wire btn_c,
    input wire btn_d,
    
    // Clean "State" outputs
    output reg [15:0] latched_switch_value, // The value to be displayed
    output reg display_is_hex        // 1 = Hex, 0 = Decimal
);

    // --- 1. Smart Controller for Button Center (btn_c) ---
    wire btn_c_long_press_event;
    wire btn_c_short_press_event;

    // We instantiate the smart_button_controller *inside* this module
    smart_button_controller #(
        .CLK_FREQ(CLK_FREQ)
    ) btn_c_ctrl (
        .clk(clk),
        .reset(reset),
        .btn_in(btn_c),
        .long_press_event(btn_c_long_press_event),
        .short_press_event(btn_c_short_press_event)
    );

    // --- 2. Simple Press Detector for Button Down (btn_d) ---
    reg btn_d_sync1, btn_d_sync2, btn_d_prev;
    
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
    
    wire btn_d_short_press_event = (btn_d_sync2 == 1'b1) && (btn_d_prev == 1'b0);

    // --- 3. State Register: Latched Value ---
    // (This logic is identical to before)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            latched_switch_value <= 16'h0000;
        end else if (btn_c_long_press_event) begin 
            latched_switch_value <= sw;
        end
    end

    // --- 4. State Register: Display Mode ---
    // (This logic is identical to before)
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            display_is_hex <= 1'b1;
        end else if (btn_c_short_press_event) begin 
            display_is_hex <= 1'b0;
        end else if (btn_d_short_press_event) begin
            display_is_hex <= 1'b1;
        end
    end

endmodule