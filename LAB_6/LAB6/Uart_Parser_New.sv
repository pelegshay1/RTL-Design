`timescale 1ns / 1ps

/**
 * Module: uart_parser
 * Description: Extracts Red, Green, and Blue values from a 128-bit validated RGB message
 * and outputs them as a combined 24-bit vector with a ready pulse.
 * Also passes through LED command messages from buffer_checker.
 */

module uart_parser (
    input  logic         clk,
    input  logic         reset,         // Active Low
    input  logic [127:0] valid_msg,     // RGB message from buffer_checker
    input  logic         msg_ready,     // RGB message ready pulse from buffer_checker
    input  logic [7:0]   led_command_in, // LED command from buffer_checker (16 or 17)
    input  logic         led_cmd_ready_in, // LED command ready pulse from buffer_checker
    
    // Outputs to the Main FSM
    output logic [23:0]  pixel_data_packet, // RGB data: [R(23:16), G(15:8), B(7:0)]
    output logic         msg_ready_out,     // Pulse when RGB packet is valid
    output logic [7:0]   led_command,       // LED selector command (16 or 17)
    output logic         led_cmd_ready      // Pulse when LED command is ready
);

    // Internal wires for binary RGB values
    logic [7:0] red_bin, green_bin, blue_bin;
    logic msg_ready_prev , msg_ready_prev_1;
    // ===========================================================================
    // BLOCK 1: RGB Message Parsing - ASCII to Binary Conversion
    // ===========================================================================
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            red_bin           <= '0;
            green_bin         <= '0;
            blue_bin          <= '0;
            pixel_data_packet <= '0;
            msg_ready_out     <= 1'b0;
            led_command       <= 8'd0;
            led_cmd_ready     <= 1'b0;
        end else begin
            msg_ready_out <= 1'b0; // Default pulse state
            led_cmd_ready <= 1'b0; // Default pulse state
            msg_ready_prev <= msg_ready;
            msg_ready_prev_1 <= msg_ready_prev;


            // Parse RGB message: {Rddd,Cddd,Vddd}
            // R digits at [23:16], [31:24], [39:32] -> Red
            // C digits at [63:56], [71:64], [79:72] -> Green
            // V digits at [103:96], [111:104], [119:112] -> Blue
            if (msg_ready_prev_1) begin
                // Convert Red (R) ASCII digits to binary
                red_bin <= ( (valid_msg[23:16] - 8'h30) * 100 ) + 
                           ( (valid_msg[31:24] - 8'h30) * 10  ) + 
                           ( (valid_msg[39:32] - 8'h30)       );
                
                // Convert Green (C) ASCII digits to binary
                green_bin <= ( (valid_msg[63:56] - 8'h30) * 100 ) + 
                             ( (valid_msg[71:64] - 8'h30) * 10  ) + 
                             ( (valid_msg[79:72] - 8'h30)       );
                
                // Convert Blue (V) ASCII digits to binary
                blue_bin <= ( (valid_msg[103:96] - 8'h30) * 100 ) + 
                            ( (valid_msg[111:104] - 8'h30) * 10  ) + 
                            ( (valid_msg[119:112] - 8'h30)       );

                // Combine into 24-bit vector: [R(23:16), G(15:8), B(7:0)] and pulse ready
                msg_ready_out     <= 1'b1;
            end

             pixel_data_packet <= {red_bin, green_bin, blue_bin};

            // Pass through LED command from buffer_checker
            if (led_cmd_ready_in) begin
                led_command   <= led_command_in;
                led_cmd_ready <= 1'b1;
            end
        end
    end

endmodule