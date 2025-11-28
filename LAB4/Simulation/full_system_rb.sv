//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.11.2025 19:24:44
// Design Name:
// Module Name: full_system_tb
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

module full_system_tb ;

    // --- 1. Simulation Parameters ---
    // We scale down the frequency and baudrate to make the simulation run fast
    // while keeping the logic valid.
    localparam CLK_FREQ_SIM = 1000;  // 1 Second = 1000 clocks
    localparam BAUDRATE_SIM = 100;   // 10 clocks per bit (Fast UART)
    localparam T_CLK        = 10;    // 10ns clock period

    // --- 2. Signals ---
    reg clk;
    reg reset;

    // System Inputs
    reg btn_c;
    reg [7:0] sw_num;
    reg [1:0] sw_speed;
    reg [1:0] sw_num_of_bytes;

    // Interconnect Wires
    // System Controller -> FSM / Seg
    wire one_sec_push;
    wire [7:0] latched_num;
    wire [7:0] latched_speed;
    wire [7:0] latched_num_of_bytes;

    // FSM <-> Transmitter
    wire tx_start;
    wire end_of_byte;
    wire [7:0] byte_to_send;

    // FSM -> Seg / LEDs
    wire [7:0] total_row_count; // Connects to FSM output
    wire led_byte;
    wire finished;

    // Transmitter Output
    wire tx_data_out;

    // Segment Controller Outputs
    wire [7:0] cathode;
    wire [7:0] anode;

    // --- 3. Modules Instantiation ---

    // 3.1 System Controller
    system_controller #(
        .CLK_FREQ(CLK_FREQ_SIM)
    ) sys_ctrl (
        .clk(clk),
        .reset(reset),
        .btn_c(btn_c),
        .one_sec_push(one_sec_push), // Connects to FSM write_en
        .num(sw_num),
        .latched_num(latched_num),
        .speed(sw_speed),
        .latched_speed(latched_speed),
        .num_of_bytes(sw_num_of_bytes),
        .latched_num_of_bytes(latched_num_of_bytes)
    );

    // 3.2 FSM (Main Controller)
    FSM #(
        .CLK_FREQ(CLK_FREQ_SIM)
    ) fsm_inst (
        .clk(clk),
        .reset(reset),
        .write_en(one_sec_push),         // Start trigger from System Controller
        .num_of_bytes(latched_num_of_bytes),
        .speed(latched_speed),
        .end_of_byte(end_of_byte),       // From Transmitter
        .data_tx(latched_num),           // Data to send
        .led(led_byte),
        .total_row_count(total_row_count), // Rows sent (Note: Seg Ctrl expects bytes, see note below)
        .byte_to_send(byte_to_send),     // To Transmitter
        .tx_start(tx_start),             // To Transmitter
        .finished(finished)
    );

    // 3.3 Transmitter (UART PHY)
    Transmitter #(
        .CLK_FREQ(CLK_FREQ_SIM),
        .BAUDRATE(BAUDRATE_SIM)
    ) tx_inst (
        .clk(clk),
        .reset(reset),
        .byte_to_send(byte_to_send),
        .tx_start(tx_start),
        .end_of_byte(end_of_byte),
        .data_out(tx_data_out)
    );

    // 3.4 Segment Controller
    seg_controller #(
        .CLK400HZ(100) // Fast refresh for simulation
    ) seg_inst (
        .clk(clk),
        .reset(reset),
        .num(latched_num),
        .speed(latched_speed),
        .num_of_bytes(latched_num_of_bytes),
        // NOTE: Connecting FSM's total_row_count output.
        // Ideally, if you want total bytes, you should expose 'byte_count' from FSM.
        .byte_count(total_row_count),
        .cathode(cathode),
        .anode(anode)
    );

    // --- 4. Clock Generation ---
    initial begin
        clk = 0;
        forever #(T_CLK / 2) clk = ~clk;
    end

    // --- 5. Test Scenario ---
    initial begin
        // Init
        reset = 1;
        btn_c = 0;
        sw_num = 8'hAA;         // Data to send
        sw_speed = 2'b00;       // No Delay
        sw_num_of_bytes = 2'b01;// 32 Bytes (One Row)

        // Reset Pulse
        #50;
        reset = 0;
        #50;
        reset = 1;
        $display("Time: %0t | System Reset", $time);

        // ============================================================
        // TEST 1: Latch Configuration (Long Press)
        // ============================================================
        $display("\n--- TEST 1: Long Press Button ---");
        btn_c = 1;
        // Wait for the simulated 1 second (1000 clocks * 10ns = 10000ns)
        // We add a safety margin
        #((CLK_FREQ_SIM + 20) * T_CLK);
        btn_c = 0;

        // Check if FSM started (one_sec_push should have triggered it)
        #100;
        if (latched_num === 8'hAA)
            $display("Time: %0t | Latch Successful: Data AA", $time);
        else
            $display("Time: %0t | ERROR: Latch Failed", $time);

        // ============================================================
        // TEST 2: Monitor Transmission
        // ============================================================
        $display("\n--- TEST 2: Monitor UART Transmission ---");

        // Wait for start of transmission
        wait(tx_start == 1);
        $display("Time: %0t | FSM triggered transmission start.", $time);

        // Monitor internal FSM byte counter (Hierarchical access for debug)
        // Since 'byte_count' is internal to FSM, we use .path.to.signal
        $monitor("Time: %0t | Bytes Sent (Internal): %d | Row Count (Output): %d | TX Line: %b",
            $time, fsm_inst.byte_count, total_row_count, tx_data_out);

        // ============================================================
        // TEST 3: Wait for Completion
        // ============================================================
        $display("\n--- TEST 3: Waiting for Sequence Completion ---");

        // Timeout protection
        fork
            begin
                wait(finished == 1);
                $display("\nTime: %0t | SUCCESS: FSM Finished Signal Asserted.", $time);
            end
            begin
                #1000000; // Fail-safe timeout
                $display("\nTime: %0t | ERROR: Simulation Timed Out.", $time);
                $finish;
            end
        join_any

        #200;
        $display("Final Byte Count on Display Port: %h", total_row_count);
        $finish;
    end

endmodule