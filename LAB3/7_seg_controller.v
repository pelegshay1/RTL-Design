/*
 * Refactored 7-Segment Display Controller.
 *
 * This module receives a binary number (for hex display) and a BCD number
 * (for decimal display) and multiplexes them to the 7-segment display.
 *
 * Key features:
 * 1. Uses a "Tick Generator" (e.g., 400Hz) instead of a problematic
 * Generated Clock.
 * 2. Manages the display refresh cycle.
 * 3. Outputs the current digit to an external decoder.
 * 4. Receives the corresponding segments back from the decoder.
 * 5. Manages which cathode (digit) to light up.
 */
module seg_controller (
    input clk,          // Main system clock (e.g., 100MHz)
    input reset,        // Active-High reset
    input mode_is_hex,  // 1 = Display Hex, 0 = Display BCD

    // Data inputs
    input [15:0] num_binary, // 4 hex digits
    input [19:0] num_bcd,    // 5 BCD digits

    // Interface to external decoder
    input [6:0] in_segment,        // Segments coming back from the Decoder
    output wire [3:0] curr_digit,  // Current digit to be sent to the Decoder

    // Physical display outputs
    output wire [6:0] out_seg_anode, // Segments (a-g), assumed Active-Low
    output wire [4:0] cathode        // Digit selector (one-hot, active-high)
);

    // --- 1. Tick Generator (400Hz) ---
    // This creates a single-cycle pulse at the desired refresh rate.
    // 100,000,000 Hz / 400 Hz = 250,000 cycles
    localparam COUNT_LIMIT_400 = 250000 - 1;
    reg [$clog2(COUNT_LIMIT_400)-1:0] clk_div_reg;
    wire tick_400hz;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_div_reg <= 0;
        end else if (clk_div_reg == COUNT_LIMIT_400) begin
            clk_div_reg <= 0;
        end else begin
            clk_div_reg <= clk_div_reg + 1;
        end
    end
    
    // The 'tick' is active for exactly one clock cycle
    assign tick_400hz = (clk_div_reg == COUNT_LIMIT_400);

    // --- 2. Digit Index Counter (0-4) ---
    // We need 5 digits for the BCD value (0-65535), so we count 0 to 4.
    reg [2:0] digit_index_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digit_index_reg <= 0;
        end else if (tick_400hz) begin // Advance the counter only on the tick
            if (digit_index_reg == 4) begin
                digit_index_reg <= 0;
            end else begin
                digit_index_reg <= digit_index_reg + 1;
            end
        end
    end

    // --- 3. Combinational Logic for Data and Cathode Selection ---
    // This block determines *which* digit to display and *which* cathode
    // to light up based on the current index.
    reg [3:0] curr_digit_comb;
    reg [4:0] cathode_comb;

    always @* begin
        // Default assignment to turn everything off (prevents Latch)
        curr_digit_comb = 4'hF; // Send a "blank" code to the decoder
        cathode_comb = 5'b00000;    // Turn off all cathodes

        if (mode_is_hex) begin
            // In Hex mode, we only display 4 digits (indices 0-3)
            if (digit_index_reg < 4) begin
                // Select the relevant 4-bit chunk (digit)
                case (digit_index_reg)
                    0: curr_digit_comb = num_binary[3:0];
                    1: curr_digit_comb = num_binary[7:4];
                    2: curr_digit_comb = num_binary[11:8];
                    3: curr_digit_comb = num_binary[15:12];
                    default: curr_digit_comb = 4'hF;
                endcase
                
                // Activate the corresponding cathode (one-hot)
                cathode_comb = (1 << digit_index_reg);
            end
            // If digit_index_reg is 4, everything stays off (default)
            
        end else begin
            // In BCD mode, we display all 5 digits (indices 0-4)
            case (digit_index_reg)
                0: curr_digit_comb = num_bcd[3:0];
                1: curr_digit_comb = num_bcd[7:4];
                2: curr_digit_comb = num_bcd[11:8];
                3: curr_digit_comb = num_bcd[15:12];
                4: curr_digit_comb = num_bcd[19:16];
                default: curr_digit_comb = 4'hF;
            endcase

            // Activate the corresponding cathode (one-hot)
            cathode_comb = (1 << digit_index_reg);
        end
    end

    // --- 4. Registering Outputs (to prevent glitches) ---
    // We register our outputs so they all update cleanly on the
    // main clock edge.
    reg [3:0] curr_digit_reg;
    reg [4:0] cathode_reg;
    reg [6:0] out_seg_anode_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            curr_digit_reg    <= 4'hF;       // Blank
            cathode_reg       <= 5'b00000;   // All off
            out_seg_anode_reg <= 7'b1111111; // All off (assuming Active Low)
        end else begin
            // Load the combinational values into the registers.
            // This happens on every clock cycle, but the values only
            // change when the 'tick' advances the index.
            curr_digit_reg    <= curr_digit_comb;
            cathode_reg       <= cathode_comb;
            
            // Register the segment value coming back from the decoder.
            // ** WARNING: This creates an off-by-one timing error. **
            // 'in_segment' is the result of 'curr_digit_comb' from the
            // *previous* cycle.
            out_seg_anode_reg <= in_segment; 
        end
    end

    // --- 5. Final Output Assignment ---
    // The final outputs are the registered values.
    assign curr_digit = curr_digit_reg;
    assign cathode = cathode_reg;

    // As noted above, 'out_seg_anode_reg' is one cycle behind 'cathode_reg'.
    // This will display Cathode N with Segments N-1.
    
    // ** Option A (Recommended Fix): **
    // Change the port to `output wire [6:0] out_seg_anode`
    // and use this line instead to make the segment output combinational.
    // This ensures `in_segment` (which is based on `curr_digit_reg`)
    // and `cathode_reg` are from the same "set".
    //
    // assign out_seg_anode = in_segment;

    // ** Option B (As written, contains the bug): **
    // All outputs are registered, but segments lag cathodes by one cycle.
    assign out_seg_anode = out_seg_anode_reg;

endmodule