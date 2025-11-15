`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.11.2025 22:07:21
// Design Name: 
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


module seg_controller #(parameter CLK_FREQ = 100_000_000)
    (
     input clk,
     input reset,
     input num,
     input speed,
     input num_of_bytes,
     input byte_count,
     output cathode,
     output anode
    );
endmodule
