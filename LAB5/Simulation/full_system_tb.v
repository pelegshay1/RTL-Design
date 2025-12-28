`timescale 1ns / 1ps

module tb_full_system();

    // --- Signals ---
    logic clk;
    logic reset;
    logic rx_line;
    logic [7:0] rx_byte;
    logic rx_done;
    logic [127:0] valid_msg;
    logic msg_ready;
    logic [23:0] pixel_data_packet;
    logic msg_ready_out; 
    logic [7:0] col_index, row_index, pixel_val, num_Rx;

    // --- System Controller Signals ---
    logic btn_c;
    logic [7:0] num_sw = 8'hAA;    // Example data
    logic [1:0] speed_sw = 2'b01;  // Example speed
    logic [1:0] num_bytes_sw = 2'b10;
    logic rx_on_sw;
    logic rx_en;                   // Driven by System Controller [cite: 119, 147]
    logic Tx_Start_Pulse;
    logic [7:0] latched_num, latched_speed, latched_num_of_bytes;

    // --- Constants & Timing ---
    // Using 1MHz for simulation speed while maintaining logic ratios
    localparam int SIM_CLK_FREQ = 100_000_000; 
    localparam int CLK_PERIOD   = 10; // 100MHz physical clock = 10ns period
    localparam int BIT_TIME     = 17361; // 57600 Baud in ns [cite: 168]

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // --- System Controller Instance ---
    // Internal timer triggers when count reaches CLK_FREQ - 1 [cite: 124]
    system_controller #(.CLK_FREQ(10000)) sys_ctrl (
        .clk(clk),
        .reset(reset),
        .btn_c(btn_c),
        .num(num_sw),
        .speed(speed_sw),
        .num_of_bytes(num_bytes_sw),
        .rx_on(rx_on_sw),
        .Tx_Start_Pulse(Tx_Start_Pulse),
        .Rx_Enable_Pulse(rx_en),
        .latched_num(latched_num),
        .latched_speed(latched_speed),
        .latched_num_of_bytes(latched_num_of_bytes)
    );

    // --- Receiver Instance ---
    Reciever #(
        .CLK_FREQ(SIM_CLK_FREQ), 
        .BAUDRATE(57_600)
    ) rx_phy (
        .clk(clk),
        .reset(reset),
        .rx_line(rx_line),
        .rx_en(rx_en), 
        .rx_byte(rx_byte),
        .rx_done(rx_done)
    );

    Buffer_Checker buffer_checker_inst(
        .clk(clk),
        .reset(reset),
        .rx_byte(rx_byte),
        .rx_done(rx_done),
        .valid_msg(valid_msg),
        .msg_ready(msg_ready)
    );

    uart_parser parser (
        .clk(clk),
        .reset(reset),
        .valid_msg(valid_msg),
        .msg_ready(msg_ready),
        .pixel_data_packet(pixel_data_packet),
        .msg_ready_out(msg_ready_out)
    );

    FSM_rx fsm_rx_inst (
        .clk(clk),
        .reset(reset),
        .read_en(rx_en),
        .pixel_data_packet(pixel_data_packet),
        .msg_ready(msg_ready),
        .row_index(row_index),
        .col_index(col_index),
        .pixel_val(num_Rx),
        .led_rx_on()
    );

    seg_controller #(.CLK400HZ(25000)) segment_ctrl (
        .clk           (clk),
        .reset         (reset),
        .num           (),
        .num_Rx        (num_Rx),
        .speed         (),
        .num_of_bytes  (),
        .byte_count    (),
        .rx_select     (rx_en),
        .row_index     (row_index),
        .col_index     (col_index),
        .cathode       (),
        .anode         ()
    );


    // --- UART Tasks ---
    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            rx_line = 0; // Start Bit [cite: 16]
            #(BIT_TIME);
            for (i = 0; i < 8; i = i + 1) begin
                rx_line = data[i]; // LSB First [cite: 17]
                #(BIT_TIME);
            end
            rx_line = 1; // Stop Bit [cite: 18]
            #(BIT_TIME);
        end
    endtask

    task send_full_msg(input [127:0] msg);
        integer j;
        for (j = 15; j >= 0; j = j - 1) begin
            send_uart_byte(msg[j*8 +: 8]); 
        end
    endtask

    // --- Test Messages ---
    logic [127:0] msg1 = "{R007,C001,V005}";
    logic [127:0] msg2 = "{R126,C200,V255}";
    logic [127:0] msg3 = "{R126C200V255}"; //Not valid massege
    logic [127:0] msg4 = "{R255,C255,V255}";

    // --- Test Sequence ---
    initial begin
        // Initialize
        reset = 0;
        btn_c = 0;
        rx_on_sw = 0;
        rx_line = 1;
        #(CLK_PERIOD * 10);
        reset = 1;
        #(CLK_PERIOD * 10);

        // --- Step 1: Long Press to enable RX Mode ---
        rx_on_sw = 1; 
        #(CLK_PERIOD * 5);
        
        $display("Starting Long Press simulation...");
        btn_c = 1;
        // Wait for timer_reg to reach SIM_CLK_FREQ [cite: 124, 128]
        #(100000 + 1000); 
        btn_c = 0;
        
        #(CLK_PERIOD * 100);
        if (rx_en) $display("SUCCESS: RX Mode Enabled (rx_en is high)");
        else $display("FAILURE: RX Mode not enabled. Check button logic.");

        // --- Step 2: Send UART Messages ---
        #(CLK_PERIOD * 100);
        $display("Sending Message 1: %s", msg1);
        send_full_msg(msg1);
        
        #(BIT_TIME * 50); // Gap between messages
        
        $display("Sending Message 2: %s", msg2);
        send_full_msg(msg2);

        #(BIT_TIME * 50); // Gap between messages
        
        $display("Sending Message 2: %s", msg3);
        send_full_msg(msg3);

        #(BIT_TIME * 50); // Gap between messages
        
        $display("Sending Message 2: %s", msg4);
        send_full_msg(msg4);

        #(BIT_TIME * 100);
        $display("Simulation Finished.");
        $stop;
    end

    // Monitor
    always @(posedge clk) begin
        if (msg_ready_out) $display("FULL MESSAGE PARSED! Row: %d, Col: %d, Val: %d", 
                                     pixel_data_packet[23:16], 
                                     pixel_data_packet[15:8], 
                                     pixel_data_packet[7:0]);
    end

endmodule