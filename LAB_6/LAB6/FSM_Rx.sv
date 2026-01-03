`timescale 1ns / 1ps

/**
 * Module: FSM_rx
 * Description: FSM for Lab 6 - RGB LED PWM Controller
 * Processes RGB pixel data from UART and handles button controls for color adjustment
 * Pixel format: {R___, G___, B___} - sRGB values (0-255)
 * LED selector: {L___} - "016" or "017"
 */

module FSM_rx (
    input  logic        clk,
    input  logic        reset,
    input  logic        read_en,
    
    // Interface from the PARSER
    input  logic [23:0] pixel_data_packet,  // RGB data: [R(23:16), G(15:8), B(7:0)]
    input  logic        msg_ready,          // New pixel data ready
    input  logic [7:0]  led_command,        // LED selector command (1 byte)
    input  logic        led_cmd_ready,      // LED command ready
    
    // Button inputs [3:0]: [0]=up, [1]=down, [2]=left, [3]=right
    input  logic [3:0]  buttons,            // Button inputs: [0]=up, [1]=down, [2]=left, [3]=right
    input  logic        btn_center,         // Center button - applies changes to RGB values
    
    // Interface to PWM Controller & 7-Segment Display
    output logic [7:0]  red_value,          // Red component (0-255)
    output logic [7:0]  green_value,        // Green component (0-255)
    output logic [7:0]  blue_value,         // Blue component (0-255)
    output logic [1:0]  led_select,         // LED selector: 0=LED16, 1=LED17
    output logic [1:0]  color_selector,     // Selected color: 00=R, 01=G, 10=B
    output logic        led_rx_on           // RX indicator
);

    // FSM State Machine: ST_IDLE (wait for data), ST_UPDATE (process data)
    typedef enum logic { ST_IDLE = 1'b0, ST_UPDATE = 1'b1 } state_t;
    state_t current_state, next_state;

    // Selection mode: 00=LED, 01=Red, 10=Green, 11=Blue (left to right order)
    logic [1:0] selected_mode;
    
    // Button edge detection (assumes pre-debounced buttons)
    logic [3:0] buttons_prev;
    logic btn_center_prev;
    logic btn_up_edge, btn_down_edge, btn_left_edge, btn_right_edge, btn_center_edge;
    
    // Temporary RGB values (modified by buttons, committed on center button)
    logic [7:0] temp_red_value, temp_green_value, temp_blue_value;
    logic [1:0] temp_led_select;  // Temporary LED selection (committed on center button)

    assign led_rx_on = read_en;
    assign color_selector = selected_mode;  // Exports selection mode (00=LED, 01=R, 10=G, 11=B)

    // Button edge detection: buttons[0]=up, [1]=down, [2]=left, [3]=right
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            buttons_prev    <= 4'b0000;
            btn_center_prev <= 1'b0;
        end else begin
            buttons_prev    <= buttons;
            btn_center_prev <= btn_center;
        end
    end

    assign btn_up_edge     = buttons[0] && !buttons_prev[0];
    assign btn_down_edge   = buttons[1] && !buttons_prev[1];
    assign btn_left_edge   = buttons[2] && !buttons_prev[2];
    assign btn_right_edge  = buttons[3] && !buttons_prev[3];
    assign btn_center_edge = btn_center && !btn_center_prev;

    // FSM State Register
    always_ff @(posedge clk or negedge reset) begin
        if (!reset || !read_en) begin
            current_state <= ST_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM Next State Logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            ST_IDLE:   if (msg_ready) next_state = ST_UPDATE;
            ST_UPDATE: next_state = ST_IDLE;
            default:   next_state = ST_IDLE;
        endcase
    end

    // RGB Value Registers and Control Logic
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            red_value       <= 8'h00;
            green_value     <= 8'h00;
            blue_value      <= 8'h00;
            temp_red_value  <= 8'h00;
            temp_green_value <= 8'h00;
            temp_blue_value  <= 8'h00;
            selected_mode   <= 2'b00;  // Start with LED selected (leftmost)
            led_select      <= 2'b0;   // Default to LED16
            temp_led_select <= 1'b0;   // Default to LED16
        end else begin
            // UART updates in ST_UPDATE, buttons only work in ST_IDLE
            
            // UART pixel data: Update both actual and temporary RGB values
            if (current_state == ST_UPDATE) begin
                red_value      <= pixel_data_packet[23:16];  // R
                green_value    <= pixel_data_packet[15:8];   // G
                blue_value     <= pixel_data_packet[7:0];    // B
                temp_red_value <= pixel_data_packet[23:16];
                temp_green_value <= pixel_data_packet[15:8];
                temp_blue_value  <= pixel_data_packet[7:0];
            end
            
            // Center button: Commit temporary values to actual outputs (RGB and LED)
            if (btn_center_edge && current_state == ST_IDLE) begin
                red_value   <= temp_red_value;
                green_value <= temp_green_value;
                blue_value  <= temp_blue_value;
                led_select  <= temp_led_select;  // Commit LED selection
            end
            
            // Up button: Increment value (no wrap around)
            if (btn_up_edge && current_state == ST_IDLE) begin
                case (selected_mode)
                    2'b00: if (temp_led_select == 2'b01) temp_led_select <= 2'b10;  // LED: LED16->LED17
                    2'b01: temp_red_value   <= (temp_red_value   == 8'hFF) ? 8'hFF : temp_red_value   + 1;
                    2'b10: temp_green_value <= (temp_green_value == 8'hFF) ? 8'hFF : temp_green_value + 1;
                    2'b11: temp_blue_value  <= (temp_blue_value  == 8'hFF) ? 8'hFF : temp_blue_value  + 1;
                endcase
            end
            
            // Down button: Decrement value (no wrap around)
            if (btn_down_edge && current_state == ST_IDLE) begin
                case (selected_mode)
                    2'b00: if (temp_led_select == 2'b10) temp_led_select <= 2'b01;  // LED: LED17->LED16
                    2'b01: temp_red_value   <= (temp_red_value   == 8'h00) ? 8'h00 : temp_red_value   - 1;
                    2'b10: temp_green_value <= (temp_green_value == 8'h00) ? 8'h00 : temp_green_value - 1;
                    2'b11: temp_blue_value  <= (temp_blue_value  == 8'h00) ? 8'h00 : temp_blue_value  - 1;
                endcase
            end
            
            // Right button: Move selector right (LED->R->G->B, stops at B, no cyclic)
            if (btn_right_edge && current_state == ST_IDLE) begin
                if (selected_mode <= 2'b11) selected_mode <= selected_mode + 1;
            end
            
            // Left button: Move selector left (B->G->R->LED, stops at LED, no cyclic)
            if (btn_left_edge && current_state == ST_IDLE) begin
                if (selected_mode >= 2'b00) selected_mode <= selected_mode - 1;
            end
            
            // LED command from UART: Only accept 16 or 17 (update both actual and temp)
            if (led_cmd_ready) begin
                case (led_command)
                    8'd16: begin
                        led_select <= 2'b01;  // LED16
                        temp_led_select <= 2'b01;  // Also update temp
                    end
                    8'd17: begin
                        led_select <= 2'b10;  // LED17
                        temp_led_select <= 2'b10;  // Also update temp
                    end
                    default: begin
                        led_select <= led_select;  // Invalid: keep current selection
                        temp_led_select <= temp_led_select;
                    end
                endcase
            end
        end
    end

endmodule