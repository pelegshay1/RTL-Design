`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: FSM
// Description: System-Level UART Controller (Main State Machine).
//              Controls the flow of data transmission, including:
//              - Fetching data to send.
//              - Managing inter-byte delays.
//              - Inserting special characters (Space, CR, LF).
//              - Handling end-of-row logic (32 characters).
//////////////////////////////////////////////////////////////////////////////////

module FSM #(parameter CLK_FREQ  = 100_000_000 // System Clock Frequency
) (
    input  wire       clk,
    input  wire       reset,
    input  wire       write_en,       // Start trigger (Long press from system_controller)
    input  wire [7:0] num_of_bytes,   // Total number of bytes to transmit (Limit)
    input  wire [7:0] speed,          // Speed configuration (Delay settings)
    input  wire       end_of_byte,    // Feedback from Transmitter (Tx Done)
    input  wire [7:0] data_tx,
    output reg        led,            // Toggles on every data byte transmission
    output reg  [7:0] total_row_count, // Counter for transmitted rows of bytes (displayed on 7-Seg)
    output reg  [7:0] byte_to_send,   // Data payload to Transmitter
    output reg        tx_start,       // Trigger signal for Transmitter to start sending
    output reg        finished
);

    // ===========================================================================
    // 1. State Encoding (One-Hot)
    // ===========================================================================
    // Using One-Hot encoding for glitch-free decoding and timing efficiency.
    localparam S_IDLE         = 6'b000001; // Waiting for start command
    localparam S_TX_DATA      = 6'b000010; // Transmitting the actual data byte
    localparam S_WAIT_DATA    = 6'b000100; // Waiting for UART to finish sending data
    localparam S_DELAY        = 6'b001000; // Inter-byte delay (based on speed config)
    localparam S_TX_SPECIAL   = 6'b010000; // Transmitting special char (Space/CR/LF)
    localparam S_WAIT_SPECIAL = 6'b100000; // Waiting for UART to finish sending special char

    reg [5:0] current_state, next_state;

    // ===========================================================================
    // 2. Internal Signals & Counters
    // ===========================================================================
    reg [31:0] delay_ctr;      // Counter for the inter-byte delay
    reg [31:0] delay_target;    // Target cycle count for delay (derived from 'speed')
    reg [7:0]  row_char_ctr;    // Counter for characters in the current row (0-32)
    reg        send_lf_flag;    // Flag: 1 = We just sent CR, next must be LF.

    // Data Pattern: For this lab, we transmit the counter value itself as data.
    reg [7:0] data_pattern; //register to hold the data byte
    reg [7:0] actual_row_width; // width of row
    reg [7:0] total_row_count; // rows counter
    reg  [19:0] byte_count; // total bytes sent of square
    reg [19:0] total_bytes_in_square;
    reg end_of_byte_sampled;
    // ===========================================================================
    // 3. Delay Calculation Logic (Combinational)
    // ===========================================================================
    // Maps the decoded 'speed' input (from system_controller) to clock cycles.
    always @(*) begin
        case (speed)
            8'h00: delay_target = 0;                // No Delay
            8'h05: delay_target = CLK_FREQ / 20;    // 50ms (100M / 20)
            8'h10: delay_target = CLK_FREQ / 10;    // 100ms (100M / 10)
            8'h20: delay_target = CLK_FREQ / 5;     // 200ms (100M / 5)
            default: delay_target = 0;
        endcase
    end
    always @* begin
        case (num_of_bytes)
            8'h01: actual_row_width = 8'h01;   // 1 Byte
            8'h20: actual_row_width = 8'd32;   // 32 Bytes in row
            8'h80: actual_row_width = 8'd128;  // 128 Bytes in row
            8'hFF: actual_row_width = 8'd256;  // 256 Bytes in row
            default: actual_row_width = 8'h01;
        endcase
    end

    always @* begin
        case (num_of_bytes)
            8'h01: total_bytes_in_square = 20'h01; //1 byte in square
            8'h20: total_bytes_in_square = 20'd1024; //1024 = sqrt(128) bytes in square
            8'h80: total_bytes_in_square = 20'd16384; //16,384 = sqrt(128) bytes in sqaure
            8'hFF: total_bytes_in_square = 20'd65536; //d65536 = sqrt(256) bytes in sqaure
            default : total_bytes_in_square = 20'h01; //1 byte in square
        endcase
    end

    // ===========================================================================
    // BLOCK 1: Sequential Logic (State Memory)
    // ===========================================================================
    always @(posedge clk or negedge reset) begin
        if (!reset)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end

    // ===========================================================================
    // BLOCK 2: Combinational Logic (Next State Decoder)
    // ===========================================================================
    always @(*) begin
        next_state = current_state; // Default: Stay in current state

        case (current_state)
            // --- Idle State ---
            S_IDLE: begin                                               //01                                       
                if (write_en) begin
                    finished=0; 
                    next_state = S_TX_DATA; // Start sequence on trigger only when byte to send is loaded with data
                end
            end

            // --- Transmit Data State ---
            S_TX_DATA: begin                                           //02
                // This state pulses 'tx_start', so we move immediately to wait.
                     next_state = S_WAIT_DATA;
            end

            // --- Wait for Data Transmission ---
            S_WAIT_DATA: begin  //04
                if (end_of_byte_sampled) //wait for end of byte signal from trasmitter
                    next_state = S_DELAY; // Transmission done, start delay
            end

            // --- Inter-Byte Delay State ---
            S_DELAY: begin                                              //08
                // Wait until timer reaches target (or skip if target is 0)
                if (delay_ctr > delay_target)
                    next_state = S_TX_SPECIAL; // Time to send delimiter/newline
            end

            // --- Transmit Special Character (Space / CR / LF) ---
            S_TX_SPECIAL: begin  //10
                // Pulse 'tx_start' for the special char, then wait.
                next_state = S_WAIT_SPECIAL;
            end

            // --- Wait for Special Char Transmission ---
            S_WAIT_SPECIAL: begin                                       //20
                if (end_of_byte_sampled) begin
                    // LOGIC: Check what to do next with priority first - end of row , second end of square , third just a space

                    // 1. End of Row Logic: Handling CR -> LF sequence
                    // If we are at end of row AND 'send_lf_flag' is LOW,
                    // it means we just sent CR (0x0D). We must go back to send LF (0x0A).
                    if ((row_char_ctr == actual_row_width) && (send_lf_flag == 1'b1)) begin
                         next_state = S_TX_SPECIAL;
                     end

                    // if (send_lf_flag == 1'b1) begin
                    //      next_state = S_TX_SPECIAL; 
                    // end

                     // 2. Check if we transmitted ALL required bytes
                    else if (byte_count >= total_bytes_in_square && (send_lf_flag == 1'b0)) begin
                        next_state = S_IDLE; // Job done
                        finished=1;
                    end 


                    // 3. Normal operation: Go fetch the next data byte
                    else begin
                        next_state = S_TX_DATA;
                    end
                end
            end

            // Safety for One-Hot
            default: next_state = S_IDLE;
        endcase
    end

    // ===========================================================================
    // BLOCK 3: Sequential Logic (Registered Outputs & Counters)
    // ===========================================================================
    // This block updates outputs based on the *Next State* (Look-Ahead)
    // to ensure signals are asserted in the exact clock cycle of the state transition.
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            tx_start     <= 1'b0;
            byte_to_send <= 8'h00;
            byte_count   <= 8'h00;
            led          <= 1'b0;
            total_row_count<= 8'h00;
            row_char_ctr <= 0;
            delay_ctr    <= 0;
            send_lf_flag <= 1'b0;
            end_of_byte_sampled <= 0;
        end else begin

            end_of_byte_sampled <= end_of_byte;

            // Default: clear pulse signals to avoid latches
            tx_start <= 1'b0;

            // --- Timer Management ---
            // Increment timer only when in DELAY state
            if (current_state == S_DELAY)
                delay_ctr <= delay_ctr + 1;
            else
                delay_ctr <= 0;

            // --- Reset Counters on IDLE ---
            if (current_state == S_IDLE) begin
                byte_count   <= 0;
                row_char_ctr <= 0;
                send_lf_flag <= 0;
                led          <= 0;
                total_row_count<= 0;
                byte_to_send <=0 ;
            end



            // --- Output Logic based on Next State ---
            case (next_state)

                // Case A: Sending Data Byte
                S_TX_DATA: begin
                    byte_to_send <= data_tx;
                    tx_start     <= 1'b1;         // Trigger Transmitter
                    byte_count   <= byte_count + 1; // Increment total bytes - this counter counts bytes of total square
                    row_char_ctr <= row_char_ctr + 1; // Increment row counter - this counter counts bytes inside a row
                    led          <= ~led;         // Toggle LED;
                end


                // Case B: Sending Special Character (Space / CR / LF)
                S_TX_SPECIAL: begin
                    tx_start <= 1'b1; // Trigger Transmitter

                    // Check if we reached the end of the row (32 chars)
                    if (row_char_ctr == actual_row_width) begin
                        // Logic for CR/LF Sequence
                        if (send_lf_flag == 1'b0) begin
                            // Step 1: Send Carriage Return (CR)
                            byte_to_send <= 8'h0D; //send end of line charchter
                            send_lf_flag <= 1'b1;  // Set flag: Next pass will be LF
                        end else begin
                            // Step 2: Send Line Feed (LF) - lf_flag- signals end_of_row
                            byte_to_send <= 8'h0A; //begin the line with a space
                            send_lf_flag <= 1'b0;  // Clear flag 
                            row_char_ctr <= 0;     // Reset row counter for new line - started a new line
                            total_row_count<=total_row_count+1; //raise the row counter
                        end
                    end else begin
                        // Not end of row -> Send standard Space
                        byte_to_send <= 8'h20;
                    end
                end

            endcase
        end
    end

endmodule