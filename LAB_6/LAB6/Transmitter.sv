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

module Transmitter #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUDRATE = 57600
) (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] byte_to_send,
    input  logic       tx_start,
    output logic       end_of_byte,
    output logic       data_out
);

// ===========================================================================
// 1. State Encoding (Using SystemVerilog Enum)
// ===========================================================================
    typedef enum logic [2:0] {
        S_IDLE     = 3'b001,
        S_START    = 3'b010,
        S_TRANSMIT = 3'b100
    } state_t;

    state_t current_state, next_state;

//========================================================================================
    // --- 1. End of Bit counter- so set the 57600 bps BAUD ---
    // This creates a single-cycle pulse at the desired rate.
    // 100,000,000 Hz / 57600 Hz = 1736 cycles
    logic [$clog2(CLK_FREQ/BAUDRATE)-1:0] end_bit_counter;
    logic end_of_bit;

    always_ff @(posedge clk or negedge reset) begin
        if (~reset) begin
            end_bit_counter <= '0;
        end else begin
            if (current_state != S_TRANSMIT) begin  // make sure to reset the counter when not trasnmitting
                end_bit_counter <= '0;
            end else begin
                if (end_bit_counter == CLK_FREQ/BAUDRATE - 1) begin //threshold counter 1735 clk cycles 
                    end_bit_counter <= '0;
                end else begin
                    end_bit_counter <= end_bit_counter + 1; //raise counter
                end
            end
        end
    end

    // The 'tick' is active for exactly one clock cycle
    assign end_of_bit = (end_bit_counter == CLK_FREQ/BAUDRATE - 1);

//========================================================================================

// ===========================================================================
// 2. Internal Signals & Counters
// ===========================================================================
    logic [3:0]  bit_counter;
    logic [10:0] shift_tx;
    
    assign data_out = shift_tx[0];
    
// ===========================================================================
// BLOCK 1: Sequential Logic (State Memory)
// ===========================================================================
    always_ff @(posedge clk or negedge reset) begin
        if (!reset)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end
    
// ===========================================================================
// BLOCK 2: Combinational Logic (Next State Decoder)
// ===========================================================================
    always_comb begin
        next_state = current_state; // Default: Stay in current state

        case (current_state)
            S_IDLE: begin
                if (tx_start) begin
                    next_state = S_START;
                end
            end

            S_START: begin
                next_state = S_TRANSMIT;
            end

            S_TRANSMIT: begin
                if (end_of_byte) begin
                    next_state = S_IDLE;
                end
            end

            default: next_state = S_IDLE;
        endcase
    end
    
// ===========================================================================
// BLOCK 3: Sequential Logic (Registered Outputs & Counters)
// ===========================================================================
//This block implenets the shift register that trasmites the data

    always_ff @(posedge clk or negedge reset) begin
        if(~reset) begin
            end_of_byte <= 1'b0;
            bit_counter <= '0;
            shift_tx    <= 11'b11111111111;
        end else begin
            if (current_state == S_IDLE) begin
                end_of_byte <= 1'b0;
            end
            
            if (current_state == S_START) begin
                shift_tx <= {
                    1'b1,                       // Stop Bit (shift_tx[10])
                    1'b1,                       // Stop Bit (shift_tx[9])
                    byte_to_send[7],            // D7 (shift_tx[8])
                    byte_to_send[6],            // D6 (shift_tx[7])
                    byte_to_send[5],            // D5 (shift_tx[6])
                    byte_to_send[4],            // D4 (shift_tx[5])
                    byte_to_send[3],            // D3 (shift_tx[4])
                    byte_to_send[2],            // D2 (shift_tx[3])
                    byte_to_send[1],            // D1 (shift_tx[2])
                    byte_to_send[0],            // D0 (shift_tx[1])
                    1'b0                        // Start Bit (shift_tx[0])
                };  // Load the shift register with cuurent byte
            end
            
            if (end_of_bit) begin
                if (current_state == S_TRANSMIT && bit_counter < 10) begin
                    shift_tx <= {1'b1, shift_tx[9:1]}; // shift reg.
                    bit_counter <= bit_counter + 1;
                end else if (current_state == S_TRANSMIT && bit_counter >= 10) begin
                    bit_counter <= '0;
                    end_of_byte <= 1'b1;
                end
            end
        end
    end

endmodule