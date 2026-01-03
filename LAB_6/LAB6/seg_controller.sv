`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Peleg chip company
// Engineer: Shay Peleg
//
// Create Date: 15.11.2025 22:07:21
// Design Name: 7-seg display
// Module Name: segment_controller
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

module seg_controller #(parameter CLK400HZ = 250000) (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] num,
    input  logic [7:0] blue_value,
    input  logic [7:0] speed,
    input  logic [7:0] num_of_bytes, // total bytes to send in hex
    input  logic [7:0] byte_count,   // total
    input  logic       rx_select,
    input  logic [7:0] red_value,
    input  logic [7:0] green_value,
    input  logic [1:0] led_select,
    output logic [7:0] cathode,
    output logic [7:0] anode
);

//========================================================================================
    // --- 1. Tick Generator (400Hz) ---
    // This creates a single-cycle pulse at the desired refresh rate.
    // 100,000,000 Hz / 400 Hz = 250,000 cycles
    logic [$clog2(CLK400HZ)-1:0] clk_div_reg;
    logic tick_400hz;

    always_ff @(posedge clk or negedge reset) begin
        if (~reset) begin
            clk_div_reg <= '0;
        end else begin
            if (clk_div_reg == CLK400HZ - 1) begin
                clk_div_reg <= '0;
            end else begin
                clk_div_reg <= clk_div_reg + 1;
            end
        end
    end

    // The 'tick' is active for exactly one clock cycle
    assign tick_400hz = (clk_div_reg == CLK400HZ - 1);

//========================================================================================

    // --- 2. Digit Index Counter (0-7) ---
    logic [3:0] digit_index_reg; // Changed to 3 bits as it counts 0-7

    // This is a digit cyclic counter- to register what anode to light up
    // in the segment display
    always_ff @(posedge clk or negedge reset) begin
        if (~reset) begin
            digit_index_reg <= '0;
        end else if (tick_400hz) begin // Advance the counter only on the tick
            // In SystemVerilog, a 3-bit counter will naturally roll over from 7 to 0,
            // but keeping your explicit logic for clarity:
            if (digit_index_reg == 7) begin
                digit_index_reg <= '0;
            end else begin
                digit_index_reg <= digit_index_reg + 1;
            end
        end
    end

//========================================================================================
    // --- 3. Combinational Logic for Data and Cathode and Anode Selection ---
    // This block determines *which* anode (current digit) to display and
    //*which* cathodes(segment decoder)
    // to light up based on the current index.

    logic [3:0] curr_digit_comb = 4'hf;
    logic [7:0] Anode = 8'b11111111;
    logic       don = 1'b0;

    always_comb begin
        don = 1'b0;
        curr_digit_comb = 4'b0000;

        if (rx_select) begin
            unique case (digit_index_reg)
            4'd0:   curr_digit_comb = blue_value[3:0];
            4'd1:   curr_digit_comb = blue_value[7:4];
            4'd2:   curr_digit_comb = green_value[3:0];
            4'd3:   curr_digit_comb = green_value[7:4];
            4'd4:   curr_digit_comb = red_value[3:0];
            4'd5:   curr_digit_comb = red_value[7:4];
            4'd6:   curr_digit_comb = led_select[0];
            4'd7:   curr_digit_comb = led_select[1];
            endcase
        end else begin
            unique case (digit_index_reg)
                4'd0: curr_digit_comb = num[3:0];
                4'd1: curr_digit_comb = num[7:4];
                4'd2: curr_digit_comb = speed[3:0];
                4'd3: begin
                    curr_digit_comb = speed[7:4];
                    don = 1'b1;
                end
                4'd4: curr_digit_comb = num_of_bytes[3:0];
                4'd5: curr_digit_comb = num_of_bytes[7:4];
                4'd6: curr_digit_comb = byte_count[3:0];
                4'd7: curr_digit_comb = byte_count[7:4];
            endcase
        end

        Anode = ~(1 << digit_index_reg);
    end

//========================================================================================
    // --- 4. seven seg decoder ---
    logic [7:0] segments_active_high;

    always_comb begin
        unique case (curr_digit_comb) // the mapping is as follow: 7'bABCDEFG (1=ON)
            // Segment Format {ABCDEFG, DP=don}
            4'h0:    segments_active_high = {7'b1111110, don}; // 0 (G off)
            4'h1:    segments_active_high = {7'b0110000, don}; // 1 (B, C on)
            4'h2:    segments_active_high = {7'b1101101, don}; // 2
            4'h3:    segments_active_high = {7'b1111001, don}; // 3
            4'h4:    segments_active_high = {7'b0110011, don}; // 4
            4'h5:    segments_active_high = {7'b1011011, don}; // 5
            4'h6:    segments_active_high = {7'b1011111, don}; // 6
            4'h7:    segments_active_high = {7'b1110000, don}; // 7
            4'h8:    segments_active_high = {7'b1111111, don}; // 8 (All on)
            4'h9:    segments_active_high = {7'b1111011, don}; // 9
            4'hA:    segments_active_high = {7'b1110111, don}; // A
            4'hB:    segments_active_high = {7'b0011111, don}; // B
            4'hC:    segments_active_high = {7'b1001110, don}; // C
            4'hD:    segments_active_high = {7'b0111101, don}; // D
            4'hE:    segments_active_high = {7'b1001111, don}; // E
            4'hF:    segments_active_high = {7'b1000111, don}; // F
            default: segments_active_high = 8'b00000000;       // Blank
        endcase
    end

//========================================================================================

//Outputs

//Assign the output port cathode to the curr_segment
//Connect the segment_decoder to the cathode - Toggle bits
    assign cathode = ~segments_active_high;

//Assign the output port out_seg_anode to the current Anode -
//Connect the Anode shift register and light the currect anode

    assign anode = Anode;

endmodule