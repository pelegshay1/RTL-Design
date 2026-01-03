module Buffer_Checker (
    input  logic         clk,
    input  logic         reset,
    input  logic [7:0]   rx_byte,
    input  logic         rx_done,
    output logic [127:0] valid_msg,      // RGB message output (16 bytes)
    output logic         msg_ready,      // RGB message ready flag
    output logic [7:0]   led_command,    // LED command output (16 or 17)
    output logic         led_cmd_ready,  // LED command ready flag
    output logic         shift_buff      // Shift buffer indicator
);

    typedef enum logic {
        IDLE_WAIT_FOR_START, // 
        COLLECTING_BYTES     // 
    } state_t;

    state_t current_state;
    logic [3:0]   byte_index;   // Current byte index in message
    logic [127:0] temp_buffer;  // Temporary buffer for accumulating bytes
    logic         msg_type;     // 0=RGB message, 1=LED message

    // Byte validation logic
    // RGB message: {Rddd,Cddd,Vddd} - 16 bytes total
    // LED message: {L016} or {L017} - 6 bytes total
    logic byte_is_valid;

    always_comb begin
        byte_is_valid = 1'b0; // Default invalid

        case (byte_index)
            4'd1:  begin
                // Byte 1 determines message type: 'R' for RGB, 'L' for LED
                if (rx_byte == 8'h52) begin  // 'R' - RGB message
                    byte_is_valid = 1'b1;
                end else if (rx_byte == 8'h4C) begin  // 'L' - LED message
                    byte_is_valid = 1'b1;
                end else begin
                    byte_is_valid = 1'b0;
                end
            end

            4'd2:  begin
                // RGB: R hundreds digit; LED: '0' digit
                if (msg_type == 1'b0) begin
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h32); // 'R' hundreds digit
                end else begin
                    byte_is_valid = (rx_byte == 8'h30); // LED: '0'
                end
            end
            4'd3:  begin
                // RGB: R tens digit; LED: '1' digit
                if (msg_type == 1'b0) begin
                    if (temp_buffer[23:16] == 8'h32) begin  // If hundreds is '2'
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5' (20x-25x)
                    end else begin
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9' (0xx-1xx)
                    end
                end else begin
                    byte_is_valid = (rx_byte == 8'h31); // LED: '1'
                end
            end
            4'd4:  begin
                // RGB: R ones digit; LED: '6' or '7' digit
                if (msg_type == 1'b0) begin
                    if (temp_buffer[23:16] == 8'h32 && temp_buffer[31:24] == 8'h35) begin  // If "25x"
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5' (250-255)
                    end else begin
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9' (others)
                    end
                end else begin
                    byte_is_valid = (rx_byte == 8'h36 || rx_byte == 8'h37); // LED: '6' or '7'
                end
            end
            4'd5:  begin
                // RGB: ','; LED: '}'
                if (msg_type == 1'b0) begin
                    byte_is_valid = (rx_byte == 8'h2C); // ','
                end else begin
                    byte_is_valid = (rx_byte == 8'h7D); // '}'
                end
            end
            4'd6:  byte_is_valid = (msg_type == 1'b0) && (rx_byte == 8'h47); // 'G' (RGB only)

            // Col hundreds digit (byte_index 7) - must be '0', '1', or '2' (RGB only)
            4'd7:  byte_is_valid = (msg_type == 1'b0) && (rx_byte >= 8'h30 && rx_byte <= 8'h32); // '0', '1', or '2'

            // Col tens digit (byte_index 8) - validate based on hundreds (byte_index 7 stored at [63:56]) (RGB only)
            4'd8:  begin
                if (msg_type == 1'b0) begin
                    if (temp_buffer[63:56] == 8'h32) begin  // If hundreds is '2'
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5'
                    end else begin
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9'
                    end
                end else begin
                    byte_is_valid = 1'b0;  // LED messages don't have byte 8
                end
            end

            // Col ones digit (byte_index 9) - validate based on hundreds and tens (RGB only)
            4'd9:  begin
                if (msg_type == 1'b0) begin
                    if (temp_buffer[63:56] == 8'h32 && temp_buffer[71:64] == 8'h35) begin  // If "25x"
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5'
                    end else begin
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9'
                    end
                end else begin
                    byte_is_valid = 1'b0;  // LED messages don't have byte 9
                end
            end

            4'd10: byte_is_valid = (msg_type == 1'b0) && (rx_byte == 8'h2C); // ',' (RGB only)
            4'd11: byte_is_valid = (msg_type == 1'b0) && (rx_byte == 8'h42); // 'V' (RGB only)

            // Value hundreds digit (byte_index 12) - must be '0', '1', or '2' (RGB only)
            4'd12: byte_is_valid = (msg_type == 1'b0) && (rx_byte >= 8'h30 && rx_byte <= 8'h32); // '0', '1', or '2'

            // Value tens digit (byte_index 13) - validate based on hundreds (byte_index 12 stored at [103:96]) (RGB only)
            4'd13: begin
                if (msg_type == 1'b0) begin
                    if (temp_buffer[103:96] == 8'h32) begin  // If hundreds is '2'
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5'
                    end else begin
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9'
                    end
                end else begin
                    byte_is_valid = 1'b0;  // LED messages don't have byte 13
                end
            end

            // Value ones digit (byte_index 14) - validate based on hundreds and tens (RGB only)
            4'd14: begin
                if (msg_type == 1'b0) begin
                    if (temp_buffer[103:96] == 8'h32 && temp_buffer[111:104] == 8'h35) begin  // If "25x"
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5'
                    end else begin
                        byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9'
                    end
                end else begin
                    byte_is_valid = 1'b0;  // LED messages don't have byte 14
                end
            end

            4'd15: byte_is_valid = (msg_type == 1'b0) && (rx_byte == 8'h7D); // '}' (RGB only)
            default: byte_is_valid = 1'b0;
        endcase
    end

    // Main state machine and buffer logic
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            current_state  <= IDLE_WAIT_FOR_START;
            byte_index     <= '0;
            temp_buffer    <= '0;
            valid_msg      <= '0;
            msg_ready      <= 1'b0;
            led_command    <= 8'd0;
            led_cmd_ready  <= 1'b0;
            msg_type       <= 1'b0;
            shift_buff     <= 1'b0;
        end else begin
            msg_ready      <= 1'b0;
            led_cmd_ready  <= 1'b0;
            shift_buff     <= 1'b0;

            if (rx_done) begin
                shift_buff <= 1'b1; // 

                case (current_state)
                    IDLE_WAIT_FOR_START: begin
                        if (rx_byte == 8'h7B) begin // '{'
                            temp_buffer[7:0] <= rx_byte; // Store '{' as byte 0 (LSB side)
                            byte_index <= 4'd1;
                            msg_type <= 1'b0; // Will be determined at byte_index 1
                            current_state <= COLLECTING_BYTES;
                        end
                    end

                    COLLECTING_BYTES: begin
                        // Validate byte before storing
                        if (byte_is_valid) begin
                            // Determine message type at byte_index 1
                            if (byte_index == 4'd1) begin
                                msg_type <= (rx_byte == 8'h4C); // 'L' = LED message, 'R' = RGB message
                            end
                            
                            // Store bytes from LSB to MSB
                            case (byte_index)
                                4'd1:  temp_buffer[15:8]   <= rx_byte;
                                4'd2:  temp_buffer[23:16]  <= rx_byte;
                                4'd3:  temp_buffer[31:24]  <= rx_byte;
                                4'd4:  temp_buffer[39:32]  <= rx_byte;
                                4'd5:  begin
                                    temp_buffer[47:40] <= rx_byte;
                                    // LED message completes at byte 5 (6 bytes total including '{')
                                    if (msg_type == 1'b1) begin
                                        // Extract LED command: byte 4 contains '6' or '7'
                                        // temp_buffer[39:32] has byte 4
                                        if (temp_buffer[39:32] == 8'h36) begin  // '6'
                                            led_command <= 8'd16;
                                        end else if (temp_buffer[39:32] == 8'h37) begin  // '7'
                                            led_command <= 8'd17;
                                        end
                                        led_cmd_ready <= 1'b1;
                                        byte_index <= '0;
                                        current_state <= IDLE_WAIT_FOR_START;
                                    end
                                end
                                4'd6:  temp_buffer[55:48]  <= rx_byte;
                                4'd7:  temp_buffer[63:56]  <= rx_byte;
                                4'd8:  temp_buffer[71:64]  <= rx_byte;
                                4'd9:  temp_buffer[79:72]  <= rx_byte;
                                4'd10: temp_buffer[87:80]  <= rx_byte;
                                4'd11: temp_buffer[95:88]  <= rx_byte;
                                4'd12: temp_buffer[103:96] <= rx_byte;
                                4'd13: temp_buffer[111:104] <= rx_byte;
                                4'd14: temp_buffer[119:112] <= rx_byte;
                                4'd15: begin
                                    temp_buffer[127:120] <= rx_byte;
                                    // RGB message completes at byte 15 (16 bytes total)
                                    if (msg_type == 1'b0) begin
                                        // All 16 bytes valid - construct complete buffer with current byte
                                        valid_msg <= {rx_byte, temp_buffer[119:0]};  // Include current byte + previous 15 bytes
                                        msg_ready <= 1'b1;
                                        byte_index <= '0;
                                        current_state <= IDLE_WAIT_FOR_START;  // Wait for next '{'
                                    end
                                end
                            endcase

                            // Continue collecting bytes (increment for next byte)
                            // LED messages complete at byte 5, RGB messages complete at byte 15
                            // Both are handled in their respective case statements above
                            if (!((msg_type == 1'b1 && byte_index == 4'd5) || (msg_type == 1'b0 && byte_index == 4'd15))) begin
                                byte_index <= byte_index + 1;
                            end
                        end else begin
                            // Invalid byte detected - reset
                            current_state <= IDLE_WAIT_FOR_START;
                            byte_index <= '0;
                            temp_buffer <= '0;
                            msg_type <= 1'b0;
                        end
                    end
                endcase
            end
        end
    end
endmodule

