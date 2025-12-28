`timescale 1ns / 1ps

/**
 * Module: FSM_rx
 * Description: Simplified FSM that updates display registers from a 24-bit packet.
 */

module FSM_rx (
    input  logic        clk,
    input  logic        reset,
    input  logic        read_en,
    
    // Interface from the PARSER
    input  logic [23:0] pixel_data_packet, 
    input  logic        msg_ready,         
    
    // Interface to 7-Segment Controller
    output logic [7:0]  row_index,
    output logic [7:0]  col_index,
    output logic [7:0]  pixel_val,
    output logic        led_rx_on
);

    // Internal State
    typedef enum logic { ST_IDLE = 1'b0, ST_UPDATE = 1'b1 } state_t;
    state_t current_state, next_state;

    assign led_rx_on = read_en;

    // Sequential Logic
    always_ff @(posedge clk or negedge reset) begin
        if (!reset || !read_en) begin
            current_state <= ST_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational Next State
    always_comb begin
        next_state = current_state;
        case (current_state)
            ST_IDLE:   if (msg_ready) next_state = ST_UPDATE;
            ST_UPDATE: next_state = ST_IDLE;
            default:   next_state = ST_IDLE;
        endcase
    end

    // Register Update Logic
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            row_index <= 8'h00;
            col_index <= 8'h00;
            pixel_val <= 8'h00;
        end else if (current_state == ST_UPDATE) begin
            // Unpack 32-bit vector: [Reserved(31:24), Row(23:16), Col(15:8), Val(7:0)]
            row_index <= pixel_data_packet[23:16];
            col_index <= pixel_data_packet[15:8];
            pixel_val <= pixel_data_packet[7:0];
        end
    end

endmodule