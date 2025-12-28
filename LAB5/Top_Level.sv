
module top_level (
    input  logic       clk100,         // Clock 100MHz
    input  logic       reset,          // Asynchronous reset active low
    input  logic [7:0] num,
    input  logic [1:0] speed,
    input  logic [1:0] num_of_bytes,
    input  logic       center_button,
    input  logic       rx_on,
    input  logic       rx_data_in,
    output logic       tx_data_out,
    output logic       led_byte,
    output logic [7:0] catode,
    output logic [7:0] anode,
    output logic       led_rx_on,
    output logic       led_start,
    output logic       led_recieve,
    output logic       led_stop,
    output logic       led_recieve_done,
    // output logic       led_shift_buff,
    output logic       led_buffer_msg_ready,
    output logic       led_parser_msg_ready
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
    logic       rx_on_latched;
    logic [7:0] rx_byte;
    logic       rx_done;
    logic       is_col_cmd, is_end_msg, is_row_cmd, is_val_cmd, is_start_msg;
    logic [7:0] converted_val;
    
    // Signals for RX and Display connectivity
    logic [7:0] num_Rx;
    logic [7:0] row_index, col_index;
    logic [127:0] valid_msg;
    logic msg_ready ,msg_ready_out;
    logic [23:0] packet;

    assign led_recieve_done = rx_done;

    assign led_buffer_msg_ready = msg_ready;

    assign led_parser_msg_ready = msg_ready_out;

    // assign led_shift_buff = shift_buff; 
    // ===========================================================================
    // 1. System Controller (Button & Mode Logic)
    // ===========================================================================
    system_controller #(.CLK_FREQ(100_000_000)) button_ctrl (
        .clk                 (clk100),
        .reset               (reset),
        .btn_c               (center_button),
        .Tx_Start_Pulse      (write_en),
        .num                 (num),
        .latched_num         (latched_num),
        .speed               (speed),
        .latched_speed       (latched_speed),
        .num_of_bytes        (num_of_bytes),
        .latched_num_of_bytes(latched_num_of_bytes),
        .rx_on               (rx_on),
        .Rx_Enable_Pulse     (rx_on_latched)
    );

    // ===========================================================================
    // 2. UART Transmitter Core
    // ===========================================================================
    Transmitter #(.CLK_FREQ(100_000_000), .BAUDRATE(57600)) tx (
        .clk          (clk100),
        .tx_start     (tx_start),
        .reset        (reset),
        .byte_to_send (byte_to_send),
        .end_of_byte  (end_of_byte),
        .data_out     (tx_data_out)
    );

    // ===========================================================================
    // 3. Transmitter FSM (Managing sequences/delays)
    // ===========================================================================
    FSM_tx fsm_tx_inst ( // Renamed to avoid confusion with module name
        .clk             (clk100),
        .reset           (reset),
        .write_en        (write_en),
        .num_of_bytes    (latched_num_of_bytes),
        .speed           (latched_speed),
        .end_of_byte     (end_of_byte),
        .data_tx         (latched_num),
        .led             (led_byte),
        .total_row_count (byte_count),
        .byte_to_send    (byte_to_send),
        .tx_start        (tx_start),
        .finished        (finished)
    );

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
        .num_Rx        (num_Rx),
        .speed         (latched_speed),
        .num_of_bytes  (latched_num_of_bytes),
        .byte_count    (byte_count),
        .rx_select     (rx_on_latched),
        .row_index     (row_index),
        .col_index     (col_index),
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
        .pixel_data_packet(packet),
        .msg_ready_out (msg_ready_out)
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
        .row_index    (row_index),
        .col_index    (col_index),
        .pixel_val    (num_Rx),
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
        .msg_ready(msg_ready)
        // .shift_buff(shift_buff)
        );


endmodule