`timescale 1ns / 1ps

/**
* Module: buffer_checker
* Description: Accumulates 16 bytes and validates the message format:
* { R d d d , C d d d , V d d d }
*/

// module Buffer_Checker (
//     input  logic         clk,
//     input  logic         reset,
//     input  logic [7:0]   rx_byte,      // From Receiver [cite: 43]
//     input  logic         rx_done,      // From Receiver [cite: 45]
//     output logic [127:0] valid_msg,    // Full 16-byte message for Parser
//     output logic         msg_ready,     // Pulse when a valid message is locked
//     output logic         shift_buff
// );

//     logic [127:0] shift_buffer;
//     logic [3:0]   byte_count;
//     logic is_valid_sample, rx_done_sample;

//     // --- 1. Buffer Accumulation ---
//     always_ff @(posedge clk or negedge reset) begin
//         if (!reset) begin
//             shift_buffer <= '0;
//             byte_count   <= '0;
//         end else begin
//             shift_buff <= 1'b0;
//             if (rx_done) begin
//                 // Shift in the new byte from the right (LSB side of buffer)
//                 shift_buffer <= {shift_buffer[119:0], rx_byte};
//                 shift_buff <= 1'b1;
//                 // Increment count until we have a full frame (16 bytes)
//                 if (byte_count < 15)
//                     byte_count <= byte_count + 1;
//                 else
//                     byte_count <= 0; // Stay at 15 once buffer is primed
//             end
//         end
//     end

//     // --- 2. Combinational Validity Check ---
//     // Checking specific fixed positions according to: {Rddd,Cddd,Vddd}
//     // Indexing: Byte 15 is shift_buffer[127:120], Byte 0 is [7:0]

//     logic is_valid;
//     always_comb begin
//         is_valid =
//             (shift_buffer[119:112] == 8'h7B) && // '{' Byte 0
//             (shift_buffer[111:104] == 8'h52) && // 'R' byte 1
//             (shift_buffer[79:72]   == 8'h2C) && // ',' byte 5
//             (shift_buffer[71:64]   == 8'h43) && // 'C' byte 6
//             (shift_buffer[39:32]   == 8'h2C) && // ',' byte 10
//             (shift_buffer[31:24]   == 8'h56) && // 'V' byte 11
//             (rx_byte               == 8'h7D);   // '}' byte 15
//     end

//     // --- 3. Output Generation ---
//     always_ff @(posedge clk or negedge reset) begin
//         if (!reset) begin
//             valid_msg    <= '0;
//             msg_ready    <= 1'b0;
//         end else begin
//             msg_ready <= 1'b0; // Default pulse
//             // We trigger only if we have at least 16 bytes and the pattern matches
//             is_valid_sample <= is_valid;
//             // rx_done_sample <= rx_done;
//             if (is_valid) begin
//                 valid_msg <= {rx_byte, shift_buffer[119:0]};
//                 msg_ready <= 1'b1;
//                 is_valid_sample<=0;
//             end
//         end
//     end

// endmodule

// `timescale 1ns / 1ps

/**
* Module: buffer_checker
* Description: Accumulates 16 bytes and validates the message format:
* { R d d d , C d d d , V d d d }
*/

// module Buffer_Checker (
//     input  logic         clk,
//     input  logic         reset,
//     input  logic [7:0]   rx_byte,      // From Receiver [cite: 43]
//     input  logic         rx_done,      // From Receiver [cite: 45]
//     output logic [127:0] valid_msg,    // Full 16-byte message for Parser
//     output logic         msg_ready,     // Pulse when a valid message is locked
//     output logic         shift_buff
// );

//     logic [127:0] shift_buffer;
//     logic [3:0]   byte_count;
//     logic is_valid_sample, rx_done_sample;

//     // --- 1. Buffer Accumulation ---
//     always_ff @(posedge clk or negedge reset) begin
//         if (!reset) begin
//             shift_buffer <= '0;
//             byte_count   <= '0;
//         end else begin
//             shift_buff <= 1'b0;
//             if (rx_done) begin
//                 // Shift in the new byte from the right (LSB side of buffer)
//                 shift_buffer <= {shift_buffer[119:0], rx_byte};
//                 shift_buff <= 1'b1;
//                 // Increment count until we have a full frame (16 bytes)
//                 if (byte_count < 15)
//                     byte_count <= byte_count + 1;
//                 else
//                     byte_count <= 0; // Stay at 15 once buffer is primed
//             end
//         end
//     end

//     // --- 2. Combinational Validity Check ---
//     // Checking specific fixed positions according to: {Rddd,Cddd,Vddd}
//     // Indexing: Byte 15 is shift_buffer[127:120], Byte 0 is [7:0]

//     logic is_valid;
//     always_comb begin
//         is_valid =
//             (shift_buffer[119:112] == 8'h7B) && // '{' Byte 0
//             (shift_buffer[111:104] == 8'h52) && // 'R' byte 1
//             (shift_buffer[79:72]   == 8'h2C) && // ',' byte 5
//             (shift_buffer[71:64]   == 8'h43) && // 'C' byte 6
//             (shift_buffer[39:32]   == 8'h2C) && // ',' byte 10
//             (shift_buffer[31:24]   == 8'h56) && // 'V' byte 11
//             (rx_byte               == 8'h7D);   // '}' byte 15
//     end

//     // --- 3. Output Generation ---
//     always_ff @(posedge clk or negedge reset) begin
//         if (!reset) begin
//             valid_msg    <= '0;
//             msg_ready    <= 1'b0;
//         end else begin
//             msg_ready <= 1'b0; // Default pulse
//             // We trigger only if we have at least 16 bytes and the pattern matches
//             is_valid_sample <= is_valid;
//             // rx_done_sample <= rx_done;
//             if (is_valid) begin
//                 valid_msg <= {rx_byte, shift_buffer[119:0]};
//                 msg_ready <= 1'b1;
//                 is_valid_sample<=0;
//             end
//         end
//     end

// endmodule

// UART RX Buffer - Collects 16 bytes (128 bits) and validates format
// Validates each byte as it arrives - resets immediately if invalid
// Syncs on '{' (0x7B) and validates frame format byte-by-byte

// Buffer state type (exported for use in top module)


module Buffer_Checker (
    input  logic         clk,
    input  logic         reset,
    input  logic [7:0]   rx_byte,
    input  logic         rx_done,
    output logic [127:0] valid_msg,
    output logic         msg_ready,
    output logic         shift_buff   // 
);

    // הגדרת מצבי המכונה
    typedef enum logic {
        IDLE_WAIT_FOR_START, // 
        COLLECTING_BYTES     // 
    } state_t;

    state_t current_state;
    logic [3:0]   byte_index;   // 
    logic [127:0] temp_buffer;  // 

    // Inline Validation)
    // Note: byte_index 0 is handled in IDLE_WAIT_FOR_START state, so validation starts from byte_index 1
    // Numbers must be in range 0-255 (3-digit decimal: 000-255)
    // Incremental validation approach: validates hundreds must be 0-2, then tens/ones based on previous digits
    logic byte_is_valid;

    always_comb begin
        byte_is_valid = 1'b0; // Default invalid

        case (byte_index)
            4'd1:  byte_is_valid = (rx_byte == 8'h52); // 'R'

            // Row hundreds digit (byte_index 2) - must be '0', '1', or '2' (0-255 range)
            4'd2:  byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h32); // '0', '1', or '2'

            // Row tens digit (byte_index 3) - validate based on hundreds (byte_index 2 stored at [23:16])
            4'd3:  begin
                if (temp_buffer[23:16] == 8'h32) begin  // If hundreds is '2'
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5' (20x-25x)
                end else begin
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9' (0xx-1xx)
                end
            end

            // Row ones digit (byte_index 4) - validate based on hundreds and tens
            4'd4:  begin
                if (temp_buffer[23:16] == 8'h32 && temp_buffer[31:24] == 8'h35) begin  // If "25x"
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5' (250-255)
                end else begin
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9' (others)
                end
            end

            4'd5:  byte_is_valid = (rx_byte == 8'h2C); // ','
            4'd6:  byte_is_valid = (rx_byte == 8'h43); // 'C'

            // Col hundreds digit (byte_index 7) - must be '0', '1', or '2'
            4'd7:  byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h32); // '0', '1', or '2'

            // Col tens digit (byte_index 8) - validate based on hundreds (byte_index 7 stored at [63:56])
            4'd8:  begin
                if (temp_buffer[63:56] == 8'h32) begin  // If hundreds is '2'
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5'
                end else begin
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9'
                end
            end

            // Col ones digit (byte_index 9) - validate based on hundreds and tens
            4'd9:  begin
                if (temp_buffer[63:56] == 8'h32 && temp_buffer[71:64] == 8'h35) begin  // If "25x"
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5'
                end else begin
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9'
                end
            end

            4'd10: byte_is_valid = (rx_byte == 8'h2C); // ','
            4'd11: byte_is_valid = (rx_byte == 8'h56); // 'V'

            // Value hundreds digit (byte_index 12) - must be '0', '1', or '2'
            4'd12: byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h32); // '0', '1', or '2'

            // Value tens digit (byte_index 13) - validate based on hundreds (byte_index 12 stored at [103:96])
            4'd13: begin
                if (temp_buffer[103:96] == 8'h32) begin  // If hundreds is '2'
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5'
                end else begin
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9'
                end
            end

            // Value ones digit (byte_index 14) - validate based on hundreds and tens
            4'd14: begin
                if (temp_buffer[103:96] == 8'h32 && temp_buffer[111:104] == 8'h35) begin  // If "25x"
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h35);  // '0'-'5'
                end else begin
                    byte_is_valid = (rx_byte >= 8'h30 && rx_byte <= 8'h39);  // '0'-'9'
                end
            end

            4'd15: byte_is_valid = (rx_byte == 8'h7D); // '}'
            default: byte_is_valid = 1'b0;
        endcase
    end

    // 
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            current_state <= IDLE_WAIT_FOR_START;
            byte_index    <= '0;
            temp_buffer   <= '0;
            valid_msg     <= '0;
            msg_ready     <= 1'b0;
            shift_buff    <= 1'b0;
        end else begin
            msg_ready  <= 1'b0; // 
            shift_buff <= 1'b0;

            if (rx_done) begin
                shift_buff <= 1'b1; // 

                case (current_state)
                    IDLE_WAIT_FOR_START: begin
                        if (rx_byte == 8'h7B) begin // '{'
                            temp_buffer[7:0] <= rx_byte; // Store '{' as byte 0 (LSB side)
                            byte_index <= 4'd1;
                            current_state <= COLLECTING_BYTES;
                        end
                    end

                    COLLECTING_BYTES: begin
                        // Validate byte before storing
                        if (byte_is_valid) begin
                            // Store bytes from LSB to MSB (byte 0 at [7:0], byte 15 at [127:120])
                            // This matches friend's code structure
                            case (byte_index)
                                4'd1:  temp_buffer[15:8]   <= rx_byte;
                                4'd2:  temp_buffer[23:16]  <= rx_byte;
                                4'd3:  temp_buffer[31:24]  <= rx_byte;
                                4'd4:  temp_buffer[39:32]  <= rx_byte;
                                4'd5:  temp_buffer[47:40]  <= rx_byte;
                                4'd6:  temp_buffer[55:48]  <= rx_byte;
                                4'd7:  temp_buffer[63:56]  <= rx_byte;
                                4'd8:  temp_buffer[71:64]  <= rx_byte;
                                4'd9:  temp_buffer[79:72]  <= rx_byte;
                                4'd10: temp_buffer[87:80]  <= rx_byte;
                                4'd11: temp_buffer[95:88]  <= rx_byte;
                                4'd12: temp_buffer[103:96] <= rx_byte;
                                4'd13: temp_buffer[111:104] <= rx_byte;
                                4'd14: temp_buffer[119:112] <= rx_byte;
                                4'd15: temp_buffer[127:120] <= rx_byte;
                            endcase

                            // Check if frame is complete
                            if (byte_index == 4'd15) begin
                                // All 16 bytes valid - construct complete buffer with current byte
                                valid_msg <= {rx_byte, temp_buffer[119:0]};  // Include current byte + previous 15 bytes
                                msg_ready <= 1'b1;
                                byte_index <= '0;
                                current_state <= IDLE_WAIT_FOR_START;  // Wait for next '{'
                            end else begin
                                // Continue collecting
                                if (rx_done) begin
                                    byte_index <= byte_index + 1;
                                end
                            end
                        end else begin
                            if(!byte_is_valid) begin
                                current_state <= IDLE_WAIT_FOR_START;
                                byte_index <= '0;
                                temp_buffer <= '0;
                            end
                        end
                    end
                endcase
            end
        end
    end
endmodule

