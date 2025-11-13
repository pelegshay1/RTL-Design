/*
 *  7-Segment Display Controller.
 *
 * This module receives a binary number (for hex display) and a BCD number
 * (for decimal display) and multiplexes them to the 7-segment display.
 *
 * Key features:
 * 1. Uses a "Tick Generator" (e.g., 400Hz) instead of a problematic
 * Generated Clock.
 * 2. Manages the display refresh cycle.
 * 3. Receives the corresponding segments back from the decoder.
 * 4. Manages which cathode (digit) to light up.
 */



module seg_controller #(
    parameter CLK400HZ = 250000
    ) (
    input clk,          // Main system clock (e.g., 100MHz)
    input reset,        // Active-High reset

    // Data inputs
    input [15:0] num_binary, // 4 hex digits
    input [19:0] num_bcd,    // 5 BCD digits
    input mode_is_hex,  // 1 = Display Hex, 0 = Display BCD

    // Physical display outputs
    output wire [4:0] out_seg_anode, // one hot Active-Low
    output wire [6:0] cathode        // segment selector-decoded Active-Low
);

//========================================================================================    
    // --- 1. Tick Generator (400Hz) ---
    // This creates a single-cycle pulse at the desired refresh rate.
    // 100,000,000 Hz / 400 Hz = 250,000 cycles
    reg [$clog2(CLK400HZ)-1:0] clk_div_reg;
    wire tick_400hz;

    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            clk_div_reg <= 0;
        end else if (clk_div_reg == CLK400HZ - 1) begin
            clk_div_reg <= 0;
        end else begin
            clk_div_reg <= clk_div_reg + 1;
        end
    end
    
    // The 'tick' is active for exactly one clock cycle
    assign tick_400hz = (clk_div_reg == CLK400HZ - 1);


//========================================================================================

    // --- 2. Digit Index Counter (0-4) ---
    reg [2:0] digit_index_reg;

    // This is a digit cyclit counter- to register what anode to light up 
    //in the segment display
    always @(posedge clk or negedge reset) begin
        if (~reset) begin
            digit_index_reg <= 0;
        end else if (tick_400hz) begin // Advance the counter only on the tick
            if (~mode_is_hex) begin // If mode is Decimal view - 5 digits needed
                if (digit_index_reg == 4) begin
                    digit_index_reg <= 0;
                end else begin
                    digit_index_reg <= digit_index_reg + 1;
                end
            end else if (mode_is_hex)begin //If mode is Hexa view - 4 digits needed
                if (digit_index_reg == 3) begin
                    digit_index_reg <= 0;
                end else begin
                    digit_index_reg <= digit_index_reg + 1;
                end
            end
        end
    end
//========================================================================================

    // --- 3. Combinational Logic for Data and Cathode and Anode Selection ---
    // This block determines *which* anode (current digit) to display and 
    //*which* cathodes(segment decoder)
    // to light up based on the current index.

    reg [3:0] curr_digit_comb= 4'hf;
    reg [4:0] Anode = 5'b11111;

    always @* begin
        if (mode_is_hex) begin
            // In Hex mode, we only display 4 digits 
                case (digit_index_reg)
                    0: curr_digit_comb = num_binary[3:0];
                    1: curr_digit_comb = num_binary[7:4];
                    2: curr_digit_comb = num_binary[11:8];
                    3: curr_digit_comb = num_binary[15:12];
                endcase

            Anode = ~(1 << digit_index_reg);


            // If digit_index_reg is 4, everything stays off (default)
        end else begin
            // In BCD mode, we display all 5 digits 
            case (digit_index_reg)
                0: curr_digit_comb = num_bcd[3:0];
                1: curr_digit_comb = num_bcd[7:4];
                2: curr_digit_comb = num_bcd[11:8];
                3: curr_digit_comb = num_bcd[15:12];
                4: curr_digit_comb = num_bcd[19:16];
            endcase

            Anode = ~(1 << digit_index_reg);

        end
    end

//========================================================================================
    // --- 4. seven seg decoder ---
reg [6:0] segments_active_high;

    always @(*) begin
        case (curr_digit_comb) // the mapping is as follow: 7'bABCDEFG (1=ON)
            4'd0:    segments_active_high = 7'b1111110; //0 (G off)
            4'd1:    segments_active_high = 7'b0110000; //1 (B, C on)
            4'd2:    segments_active_high = 7'b1101101; //2
            4'd3:    segments_active_high = 7'b1111001; //3
            4'd4:    segments_active_high = 7'b0110011; //4
            4'd5:    segments_active_high = 7'b1011011; //5
            4'd6:    segments_active_high = 7'b1011111; //6
            4'd7:    segments_active_high = 7'b1110000; //7
            4'd8:    segments_active_high = 7'b1111111; //8 (All on)
            4'd9:    segments_active_high = 7'b1111011; //9
            4'hA:    segments_active_high = 7'b1110111; //A
            4'hB:    segments_active_high = 7'b0011111; //B
            4'hC:    segments_active_high = 7'b1001110; //C
            4'hD:    segments_active_high = 7'b0111101; //D
            4'hE:    segments_active_high = 7'b1001111; //E
            4'hF:    segments_active_high = 7'b1000111; //F
            default: segments_active_high = 7'b0000000; // Blank (All off)
        endcase
    end

//========================================================================================

//Outputs

//Assign the output port cathode to the curr_segment
//Connect the segment_decoder to the cathode - Toggle bits
assign cathode = ~segments_active_high;

//Assign the output port out_seg_anode to the current Anode - 
//Connect the Anode shift register and light the currect anode 

assign out_seg_anode = Anode;



endmodule