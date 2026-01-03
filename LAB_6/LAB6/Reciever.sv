`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: uart_receiver
// Description: This module implements the UART PHY RX. It handles synchronization,
//              start bit detection, and 5-point oversampling to ensure accurate
//              data capture at 57600 bps.
//////////////////////////////////////////////////////////////////////////////////

module Reciever #(
    parameter CLK_FREQ  = 100_000_000, // 100MHz System Clock [cite: 11]
    parameter BAUDRATE = 57_600       // Baud rate per lab requirements [cite: 37]
) (
    input  logic       clk,
    input  logic       reset,    // Active Low Reset [cite: 12]
    input  logic       rx_line,  // Physical UART RX line [cite: 29]
    input  logic       rx_en,    // Enable signal from system controller [cite: 26]
    output logic [7:0] rx_byte,  // Received 8-bit ASCII character [cite: 43]
    output logic       rx_done,  // Pulse indicating valid byte received
    output logic       led_start,
    output logic       led_recieve,
    output logic       led_stop
);

    // Timing parameters based on 100MHz clock and 57600 baud rate
    // Bit period is approx 1736 clock cycles [cite: 37]
    localparam int BIT_PERIOD    = CLK_FREQ / BAUDRATE;
    localparam int HALF_BIT      = BIT_PERIOD / 2;
    localparam int SAMPLE_OFFSET = 100; // Offset for oversampling points

    // FSM State Definition
    typedef enum logic [1:0] {
        IDLE        = 2'b00,
        START_BIT   = 2'b01,
        RECEIVE     = 2'b10,
        STOP_BIT    = 2'b11
    } state_t;

    state_t current_state, next_state;

    // Internal Registers
    logic [$clog2(BIT_PERIOD)-1:0] baud_counter;
    logic [3:0] bit_counter;
    logic [7:0] shift_reg;
    logic [4:0] samples;        // 5 samples for Majority Voting
    logic rx_sync_0, rx_sync_1; // Synchronizer stages
    logic rx_prev;              // Delayed signal for edge detection
    logic falling_edge;

    // ===========================================================================
    // BLOCK 1: Input Synchronization & Edge Detection
    // Taming the asynchronous RX line and detecting the 'High-to-Low' transition
    // marking the start of a frame.
    // ===========================================================================

    // Falling Edge Detection Logic
    // Synchronize rx_line to system clock to prevent metastability
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
            rx_prev   <= 1'b1;
        end else begin
            rx_sync_0 <= rx_line;
            rx_sync_1 <= rx_sync_0;
            rx_prev   <= rx_sync_1;
        end
    end

    // Detect falling edge: signal was '1' and is now '0'
    assign falling_edge = (rx_prev == 1'b1) && (rx_sync_1 == 1'b0);

    // ===========================================================================
    // BLOCK 2: Majority Voting Logic (Noise Reduction)
    // Uses 5 samples taken at the bit center. If 3 or more are High, bit is '1'.
    // This maximizes noise margins.
    // ===========================================================================

    // Majority Voting Logic (3 out of 5)
    logic bit_decision;
    always_comb begin
        int sum;
        sum = samples[0] + samples[1] + samples[2] + samples[3] + samples[4];
        bit_decision = (sum >= 3); // Decide '1' if 3 or more samples are High
    end

    // ===========================================================================
    // BLOCK 3: FSM State Transition
    // Standard synchronous state machine memory.
    // ===========================================================================

    // Sequential State Transition
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // ===========================================================================
    // BLOCK 4: Next State Decoder
    // Combinational logic deciding the next operational state.
    // ===========================================================================

    // Combinational Next State Logic
    always_comb begin
        next_state = current_state;
        led_start = 1'b0;
        led_recieve = 1'b0;
        led_stop = 1'b0;
        unique case (current_state)
            IDLE: begin
                // Transition to START_BIT if RX is enabled by user [cite: 26]
                if (rx_en && falling_edge ) next_state = START_BIT;
            end
            START_BIT: begin
                // Synchronize with start bit center and transition
                led_start = 1'b1;
                if (baud_counter == BIT_PERIOD - 1) next_state = RECEIVE;
            end
            RECEIVE: begin
                // Collect 8 data bits [cite: 41, 43]
                led_recieve = 1'b1;
                if (bit_counter == 7 && baud_counter == BIT_PERIOD - 1)
                    next_state = STOP_BIT;
            end
            STOP_BIT: begin
                // Wait for stop bit period before returning to IDLE
                led_stop = 1'b1;
                if (baud_counter == HALF_BIT) next_state = IDLE;
            end
        endcase
    end

    // ===========================================================================
    // BLOCK 5: Counters and Data Capture Logic
    // Manages the baud counter, oversampling points, and the data shift register.
    // ===========================================================================

    // Sequential Logic for Counters and Data Sampling [cite: 41, 42]
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            baud_counter <= '0;
            bit_counter  <= '0;
            shift_reg    <= '0;
            rx_byte      <= '0;
            rx_done      <= 1'b0;
            samples      <= '0;
        end else begin
            rx_done <= 1'b0; // Default pulse state

            unique case (current_state)
                IDLE: begin
                    baud_counter <= '0;
                    bit_counter  <= '0;
                end

                START_BIT: begin
                    // Monitor start bit and increment baud counter
                    if (baud_counter == BIT_PERIOD - 1) begin
                        baud_counter <= '0;
                    end else begin
                        baud_counter <= baud_counter + 1;
                    end
                end

                RECEIVE: begin
                    // Perform 5-point oversampling near the middle of each bit
                    if (baud_counter == HALF_BIT - (2*SAMPLE_OFFSET)) samples[0] <= rx_sync_1;
                    if (baud_counter == HALF_BIT - SAMPLE_OFFSET)     samples[1] <= rx_sync_1;
                    if (baud_counter == HALF_BIT)                     samples[2] <= rx_sync_1; // True Middle
                    if (baud_counter == HALF_BIT + SAMPLE_OFFSET)     samples[3] <= rx_sync_1;
                    if (baud_counter == HALF_BIT + (2*SAMPLE_OFFSET)) samples[4] <= rx_sync_1;

                    // At the end of the bit period, shift in the bit decision
                    if (baud_counter == BIT_PERIOD - 1) begin
                        baud_counter <= '0;
                        bit_counter  <= bit_counter + 1;
                        shift_reg    <= {bit_decision, shift_reg[7:1]}; // UART sends LSB first
                    end else begin
                        baud_counter <= baud_counter + 1;
                    end
                end

                STOP_BIT: begin
                    // Finalize byte reception and pulse rx_done signal [cite: 41]
                        rx_byte <= shift_reg;
                        if (baud_counter == 0) begin
                            rx_done <= 1'b1;
                        end else begin
                            rx_done <= 1'b0;
                        end
                        

                    if (baud_counter == HALF_BIT) begin
                        baud_counter <= '0;
                    end else begin
                        baud_counter <= baud_counter + 1;
                    end
                end
            endcase
        end
    end

endmodule