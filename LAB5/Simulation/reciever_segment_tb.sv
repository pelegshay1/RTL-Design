//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.12.2025 00:07:04
// Design Name: 
// Module Name: Reciever_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module tb_reciever_segment();

  // --- Signals ---
    logic clk;
    logic reset;
    logic rx_line;
    logic rx_en;
    logic [7:0] rx_byte;
    logic rx_done;
    logic [127:0] valid_msg;
    // Testbench monitoring register
    logic [7:0] Reg_Out;
    logic msg_ready;
    logic [23:0] pixel_data_packet;
    logic msg_ready_out; 
    logic [7:0] col_index, row_index, pixel_val,num_Rx;

    // --- Clock Generation (100MHz) ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- UUT Instance ---
    Reciever #(
        .CLK_FREQ(100_000_000),
        .BAUDRATE(57_600)
    ) uut (
        .clk(clk),
        .reset(reset),
        .rx_line(rx_line),
        .rx_en(rx_en),
        .rx_byte(rx_byte),
        .rx_done(rx_done)
    );


    Buffer_Checker buffer_checker_inst(
        .clk      (clk),
        .reset    (reset),
        .rx_byte  (rx_byte),
        .rx_done  (rx_done),
        .valid_msg(valid_msg),
        .msg_ready(msg_ready)
        );

    uart_parser parser (
        .clk          (clk),
        .reset        (reset),
        .valid_msg    (valid_msg),
        .msg_ready      (msg_ready),
        .pixel_data_packet(pixel_data_packet),
        .msg_ready_out    (msg_ready_out)
        );

        FSM_rx fsm_rx_inst (
        .clk          (clk),
        .reset        (reset),
        .read_en      (rx_en),
        .pixel_data_packet (pixel_data_packet),
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


    // Timing for 57600 Baud: 1/57600 = 17.361us [cite: 37]
    localparam BIT_TIME = 17361;

    // --- 128-bit Message Registers (16 Bytes each) ---
    // Protocol format: { R[ddd] C[ddd] V[ddd] } 
    // Messages with 1, 2, and 3 digit numbers
    logic [127:0] msg1 = "{R007,C001,V005}"; // Single digit numbers
    logic [127:0] msg2 = "{R049,C022,V088}"; // Two digit numbers
    logic [127:0] msg3 = "{R126,C200,V255}"; // Three digit numbers (Max 255)

    // --- Task: Send a single UART byte ---
    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            // Start Bit (Low) [cite: 40]
            rx_line = 0;
            #(BIT_TIME);
            
            // Data Bits (LSB First) [cite: 41]
            for (i = 0; i < 8; i = i + 1) begin
                rx_line = data[i];
                #(BIT_TIME);
            end
            
            // Stop Bit (High)
            rx_line = 1;
            #(BIT_TIME);
        end
    endtask

    // --- Task: Send a full 128-bit message (16 ASCII chars) ---
    task send_full_msg(input [127:0] msg);
        integer j;
        logic [7:0] char;
        begin
            // Messages are sent from left to right (MSB of the 128-bit reg to LSB)
            for (j = 15; j >= 0; j = j - 1) begin
                char = msg[j*8 +: 8]; // Extract 1 byte
                send_uart_byte(char);
            end
        end
    endtask

    //// Indexed Part-Select Breakdown: [Base_Index +: Width]
    // 1. Base_Index: The starting bit (LSB) of the slice. Can be a variable (e.g., j*8).
    // 2. +: Operator indicating to start from the Base_Index and count "up" toward MSB.
    // 3. Width: The number of bits to select. This MUST be a constant value.

    // --- Test Sequence ---
    initial begin
        // Initialize
        reset = 0;
        rx_line = 1; // Idle high
        rx_en = 0;
        Reg_Out = 8'h00;

        #(100);
        reset = 1;
        #(100);
        
        // Enable RX mode [cite: 26]
        rx_en = 1;
        #(200);

        // Inject Message 1: {R007,C001,V005}
        $display("Sending Message 1...");
        send_full_msg(msg1);
        #(BIT_TIME * 10);

        // Inject Message 2: {R049,C022,V088}
        $display("Sending Message 2...");
        send_full_msg(msg2);
        #(BIT_TIME * 10);

        // Inject Message 3: {R126,C200,V255}
        $display("Sending Message 3...");
        send_full_msg(msg3);

        #(1000);
        $display("Simulation Finished.");
        $stop;
    end

    // --- Capture logic for Reg_Out ---
    always @(posedge clk) begin
        if (rx_done) begin
            Reg_Out <= rx_byte; // Update Reg_Out every time a byte is completed
            $display("Byte Received: %h (ASCII: %c)", rx_byte, rx_byte);
        end
    end

endmodule


