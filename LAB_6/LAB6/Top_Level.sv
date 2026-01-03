
module top_level (
    input  logic       clk100,         // Clock 100MHz
    input  logic       reset,          // Asynchronous reset active low
    // input  logic [7:0] num,
    // input  logic [1:0] speed,
    /*input  logic [1:0] num_of_bytes,*/
    // input  logic       center_button,
    input  logic [4:0] button,
    // input  logic       rx_on,
    input  logic       rx_data_in,
    // output logic       tx_data_out,
    // output logic       led_byte,
    output logic [7:0] catode,
    output logic [7:0] anode,
    output logic       led_rx_on,
    output logic       led_start,
    output logic       led_recieve,
    output logic       led_stop,
    output logic       led_recieve_done,
    // output logic       led_shift_buff,
    output logic       led_buffer_msg_ready,
    output logic       led_parser_msg_ready,
    output logic       [2:0] pwm_out_16,
    output logic       [2:0] pwm_out_17
);

    // ===========================================================================
    // Internal Signals (Logic)
    // ===========================================================================
    logic       write_en;
    logic [7:0] latched_num;
    logic [7:0] latched_speed;
    logic [7:0] latched_num_of_bytes;
    logic       end_of_byte;
    logic [7:0] byte_count;
    logic [7:0] byte_to_send;
    logic       tx_start;
    logic       finished;
    logic       rx_on_latched = 1'b1;
    logic [7:0] rx_byte;
    logic       rx_done;
    logic       is_col_cmd, is_end_msg, is_row_cmd, is_val_cmd, is_start_msg;
    logic [7:0] converted_val;
    logic [7:0] led_command, led_command_fsm;
    logic       led_cmd_ready, led_cmd_ready_fsm;
    logic [1:0] led_select;


    // Signals for RX and Display connectivity
    logic [7:0] blue_value;
    logic [7:0] red_value, green_value;
    logic [127:0] valid_msg;
    logic msg_ready ,msg_ready_out;
    logic [23:0] packet;
    logic [1:0] color_selector;
    logic [10:0] red_pwm_out, green_pwm_out, blue_pwm_out;

    logic [10:0] duty_cycle [2:0];
    // ==============================================================================

    logic [4:0] buttons_clean;

    assign led_recieve_done = rx_done;

    assign led_buffer_msg_ready = msg_ready;

    assign led_parser_msg_ready = msg_ready_out;

    assign duty_cycle[0] = red_pwm_out;
    assign duty_cycle[1] = green_pwm_out;
    assign duty_cycle[2] = blue_pwm_out;

    // assign led_shift_buff = shift_buff;

    // ===========================================================================
    // 1. System Controller (Button & Mode Logic)
    // ===========================================================================
    // system_controller #(.CLK_FREQ(100_000_000)) button_ctrl (
    //     .clk                 (clk100),
    //     .reset               (reset),
    //     .btn_c               (center_button),
    //     .Tx_Start_Pulse      (write_en),
    //     .num                 (num),
    //     .latched_num         (latched_num),
    //     .speed               (speed),
    //     .latched_speed       (latched_speed),
    //     .num_of_bytes        (num_of_bytes),
    //     .latched_num_of_bytes(latched_num_of_bytes),
    //     .rx_on               (rx_on),
    //     .Rx_Enable_Pulse     (rx_on_latched)
    // );

    // // ===========================================================================
    // // 2. UART Transmitter Core
    // // ===========================================================================
    // Transmitter #(.CLK_FREQ(100_000_000), .BAUDRATE(57600)) tx (
    //     .clk          (clk100),
    //     .tx_start     (tx_start),
    //     .reset        (reset),
    //     .byte_to_send (byte_to_send),
    //     .end_of_byte  (end_of_byte),
    //     .data_out     (tx_data_out)
    // );

    // // ===========================================================================
    // // 3. Transmitter FSM (Managing sequences/delays)
    // // ===========================================================================
    // FSM_tx fsm_tx_inst ( // Renamed to avoid confusion with module name
    //     .clk             (clk100),
    //     .reset           (reset),
    //     .write_en        (write_en),
    //     .num_of_bytes    (latched_num_of_bytes),
    //     .speed           (latched_speed),
    //     .end_of_byte     (end_of_byte),
    //     .data_tx         (latched_num),
    //     .led             (led_byte),
    //     .total_row_count (byte_count),
    //     .byte_to_send    (byte_to_send),
    //     .tx_start        (tx_start),
    //     .finished        (finished)
    // );

    // ===========================================================================
    // 4. UART Reciever Core
    // ===========================================================================
    Reciever #(.CLK_FREQ(100_000_000), .BAUDRATE(57600)) rx (
        .clk       (clk100),
        .reset     (reset),
        .rx_line   (rx_data_in),
        .rx_en     (rx_on_latched),
        .rx_byte   (rx_byte),
        .rx_done   (rx_done),
        .led_start (led_start),
        .led_recieve(led_recieve),
        .led_stop   (led_stop)
    );

    // ===========================================================================
    // 5. 7-Segment Display Controller
    // ===========================================================================
    seg_controller #(.CLK400HZ(250000)) segment_ctrl (
        .clk           (clk100),
        .reset         (reset),
        .num           (latched_num),
        .blue_value        (blue_value),
        .speed         (latched_speed),
        .num_of_bytes  (latched_num_of_bytes),
        .byte_count    (byte_count),
        .rx_select     (rx_on_latched),
        .red_value     (red_value),
        .green_value     (green_value),
        .led_select  (led_select),
        .cathode       (catode),
        .anode         (anode)
    );

    // ===========================================================================
    // 6. UART Parser
    // ===========================================================================
    uart_parser parser (
        .clk          (clk100),
        .reset        (reset),
        .valid_msg    (valid_msg),
        .msg_ready      (msg_ready),
        .led_command_in   (led_command),
        .led_cmd_ready_in    (led_cmd_ready),
        .pixel_data_packet(packet),
        .msg_ready_out (msg_ready_out),
        .led_command (led_command_fsm),
        .led_cmd_ready (led_cmd_ready_fsm)
    );

    // ===========================================================================
    // 7. Reciever FSM
    // ===========================================================================

    FSM_rx fsm_rx_inst (
        .clk          (clk100),
        .reset        (reset),
        .read_en      (rx_on_latched),
        .pixel_data_packet (packet),
        .msg_ready    (msg_ready_out),
        .led_command      (led_command_fsm),
        .led_cmd_ready    (led_cmd_ready_fsm),
        .buttons          ({buttons_clean[3], buttons_clean[2], buttons_clean[1], buttons_clean[0]}),
        .btn_center       (buttons_clean[4]),
        .red_value    (red_value),
        .green_value    (green_value),
        .blue_value    (blue_value),
        .led_select       (led_select),
        .color_selector   (color_selector),
        .led_rx_on    (led_rx_on)
    );

    // ===========================================================================
    // 8. Buffer Checker - Validates message and Buffering 128 bit
    // ===========================================================================

    Buffer_Checker buffer_checker_inst(
        .clk      (clk100),
        .reset    (reset),
        .rx_byte  (rx_byte),
        .rx_done  (rx_done),
        .valid_msg(valid_msg),
        .msg_ready(msg_ready),
        .led_command (led_command),
        .led_cmd_ready (led_cmd_ready),
        .shift_buff()
    );

    // ===========================================================================
    // 9. Button Debouncer - Debounces the push-buttons input ( 20 ms )
    // ===========================================================================

    genvar i;
    generate
        for (i = 0; i < 5; i++) begin : debounce_gen
            button_debouncer #(.CLK_FREQ(100_000_000)) debounce (
                .clk         (clk100),
                .reset       (reset),
                .btn         (button[i]),
                .btn_debounce (buttons_clean[i])
            );
        end
    endgenerate

    /* * GENERATE BLOCK NOTES:
    * ---------------------
    * The 'debounce_gen' label is required to create a predictable hierarchical path.
    * To reference a specific instance in simulation or constraints (XDC),
    * use the following naming convention:
    * * debounce_gen[i].debounce
    * * Example:
    * - Instance 0 (Center Button):  debounce_gen[0].debounce
    * - Instance 1 (Up Button):      debounce_gen[1].debounce
    * * Note: Without the 'debounce_gen' label, the compiler would assign
    * generic names (like genblk1), making debugging much harder.
    */

    // ===========================================================================
    // 10. CIE Scailing Unit - converts RGBs values to scaled linear values and
    // calculates the LEDs PWM
    // ===========================================================================

    CIE_scaling_unit #(.PWM_SLOTS(1024)) CIE (
        .clk          (clk100),
        .reset        (reset),
        .red_value    (red_value),
        .green_value  (green_value),
        .blue_value   (blue_value),
        .red_pwm_out  (red_pwm_out),
        .green_pwm_out(green_pwm_out),
        .blue_pwm_out (blue_pwm_out)
    );

    // ===========================================================================
    // 11. PWM Generator - recieves the calculated duty cycle fro the CIE unit and
    // generates the PWM signal activating the RGB leds 0 = RED 1 = GREEN 2 = BLUE
    // ===========================================================================

    genvar j;
    generate
        for (j = 0; j < 3; j++) begin : PWM_gen
            PWM_generator #(.PWM_SLOTS(1024)) PWM_generator (
                .clk         (clk100),
                .reset       (reset),
                .duty_cycle         (duty_cycle[j]),
                .led_select(led_select),
                .pwm_out_16 (pwm_out_16[j]),
                .pwm_out_17 (pwm_out_17[j])
            );
        end
    endgenerate


endmodule