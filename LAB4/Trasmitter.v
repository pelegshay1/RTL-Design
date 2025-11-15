`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.11.2025 21:51:00
// Design Name: 
// Module Name: Trasmitter
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


module Transmitter #(parameter CLK_FREQ = 100_000_000)
    (
        input clk,
        input reset,
        input [7:0] num,
        input [1:0] speed,
        input [1:0] num_of_bytes,
        output byte_on_off,
        output special_char,
        output wait_s,
        output done,
        output byte_count,
        output data_out
    );
endmodule
