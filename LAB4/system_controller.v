`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.11.2025 21:34:55
// Design Name:
// Module Name: system_controller
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


module system_controller #(parameter CLK_FREQ = 100_000_000) (
    input clk,
    input reset,
    input btn_c,
    output one_sec_push,
    input [7:0] num,
    output reg [7:0] latched_num,
    input [1:0] speed,
    output reg [1:0] latched_speed,
    input [1:0] num_of_bytes,
    output reg [1:0] latched_num_of_bytes
);
//===========================================================================================================
  // --- 1. Smart Controller for Button Center (btn_c) ---
  //This code should detect if a Long pressed event happened with center Button input
    reg btn_sync1, btn_sync2;
    wire btn_stable; // stable synchronized button signal
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

    // Long Press Event:
    //Rising edge detector on one_sec_reached to signal a Long press event
    reg one_sec_reached_prev;
    always @(posedge clk) begin
        one_sec_reached_prev <= one_sec_reached;
    end
    
    // The event fires when the signal is '1' now but was '0' last cycle
    //This signals note that a long press event happened
    assign btn_c_long_press_event = (one_sec_reached == 1'b1) && (one_sec_reached_prev == 1'b0);


    //If a long press event happened - latch the values: Input byte , speed and number of bytes
    //these values will be connected to the 7 seg display controller and the UART trasmitter
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            latched_num <= 8'h00;
            latched_speed <= 2'h0;
            latched_num_of_bytes <= 2'h0;
        end else if (btn_c_long_press_event) begin 
            latched_num <= num;
            latched_speed <= speed;
            latched_num_of_bytes <= num_of_bytes;
        end
    end
endmodule
