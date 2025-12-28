`timescale 1ns / 1ps

/**
 * Module: uart_parser
 * Description: Extracts Row, Col, and Pixel values from a 128-bit validated message
 * and outputs them as a combined 24-bit vector with a single ready pulse.
 */

module uart_parser (
    input  logic         clk,
    input  logic         reset,         // Active Low
    input  logic [127:0] valid_msg,     // From buffer_checker
    input  logic         msg_ready,     // Pulse from buffer_checker
    
    // Outputs to the Main FSM
    output logic [23:0]  pixel_data_packet, // Combined [Row(8b), Col(8b), Val(8b)]
    output logic         msg_ready_out      // Pulse when packet is valid
);

    // Internal wires for binary values
    logic [7:0] row_bin, col_bin, val_bin;

    // ===========================================================================
    // BLOCK 1: Parallel ASCII to Binary Conversion
    // ===========================================================================
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            row_bin <= '0;
            col_bin <= '0;
            val_bin <= '0;
            pixel_data_packet <= '0;
            msg_ready_out     <= 1'b0;
        end else begin
            msg_ready_out <= 1'b0; // Default pulse state

            if (msg_ready) begin
                
                row_bin = ( (valid_msg[23:16] - 8'h30) * 100 ) + 
                          ( (valid_msg[31:24]  - 8'h30) * 10  ) + 
                          ( (valid_msg[39:32]   - 8'h30)       );
                

                col_bin = ( (valid_msg[63:56] - 8'h30) * 100 ) + 
                          ( (valid_msg[71:64] - 8'h30) * 10  ) + 
                          ( (valid_msg[79:72] - 8'h30)       );
                
                
                val_bin = ( (valid_msg[103:96] - 8'h30) * 100 ) + 
                          ( (valid_msg[111:104] - 8'h30) * 10  ) + 
                          ( (valid_msg[119:112]  - 8'h30)       );

                // Combine into 24-bit vector and pulse ready
                pixel_data_packet <= {row_bin, col_bin, val_bin};
                msg_ready_out     <= 1'b1;
            end
        end
    end

endmodule