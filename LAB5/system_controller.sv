`timescale 1ns / 1ps

module system_controller #(
    parameter CLK_FREQ = 100_000_000
) (
    input  logic       clk,
    input  logic       reset,   // Active Low reset
    input  logic       btn_c,
    input  logic [7:0] num,
    input  logic [1:0] speed,
    input  logic [1:0] num_of_bytes,
    input  logic       rx_on,
    
    output logic       Tx_Start_Pulse,
    output logic       Rx_Enable_Pulse,
    output logic [7:0] latched_num,
    output logic [7:0] latched_speed,
    output logic [7:0] latched_num_of_bytes
);

    // --- 1. Smart Controller for Button Center (btn_c) ---
    logic btn_sync1, btn_sync2;
    logic btn_stable; 

    always_ff @(posedge clk) begin
        btn_sync1 <= btn_c;
        btn_sync2 <= btn_sync1;
    end
    
    assign btn_stable = btn_sync2;

    // --- 2. Timer and Long-Press Flag Logic ---
    logic [$clog2(CLK_FREQ)-1:0] timer_reg;
    logic one_sec_reached;
    
    assign one_sec_reached = (timer_reg == CLK_FREQ - 1);

    // This flag is crucial. It "remembers" if a long press has
    // already occurred during this specific press cycle.
    // This prevents a 'short_press_event' from firing
    // when the user *releases* the button after a long press.

    logic long_press_fired_reg;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            timer_reg            <= '0;
            long_press_fired_reg <= 1'b0;
        end else if (btn_stable) begin // --- Button is PRESSED ---
            if (!one_sec_reached) begin
                timer_reg <= timer_reg + 1; // Count up to 1 second
            end
             // If we've reached 1 second AND we haven't fired the flag yet
            if (one_sec_reached && !long_press_fired_reg) begin
                long_press_fired_reg <= 1'b1;
            end
        end else begin // --- Button is RELEASED ---
            timer_reg            <= '0;
            long_press_fired_reg <= 1'b0;
        end
    end

    // --- 3. Event Detection ---
    logic one_sec_reached_prev;
    logic btn_c_long_press_event;
    logic rx_select;

    // Long Press Event:
    //Rising edge detector on one_sec_reached to signal a Long press event
    always_ff @(posedge clk) begin
        one_sec_reached_prev <= one_sec_reached;
    end

    // The event fires when the signal is '1' now but was '0' last cycle
    //This signals note that a long press event happened
    assign btn_c_long_press_event = (one_sec_reached == 1'b1) && (one_sec_reached_prev == 1'b0);
    //if a long press event happened and rx_on conifugre the half_duplex system to recieve only
    assign rx_select              = (btn_c_long_press_event) && (rx_on);

    // --- 4. Translators (Combinational) ---
    logic [7:0] num_of_bytes_hex;
    logic [7:0] speed_dec;

    always_comb begin
        unique case (num_of_bytes)
            2'd0:    num_of_bytes_hex = 8'h01;
            2'd1:    num_of_bytes_hex = 8'h20;
            2'd2:    num_of_bytes_hex = 8'h80;
            2'd3:    num_of_bytes_hex = 8'hFF;
            default: num_of_bytes_hex = 8'h01;
        endcase

        unique case (speed)
            2'd0:    speed_dec = 8'h00;
            2'd1:    speed_dec = 8'h05;
            2'd2:    speed_dec = 8'h10;
            2'd3:    speed_dec = 8'h20;
            default: speed_dec = 8'h00;
        endcase
    end

    // --- 5. Latching Logic and Pulse Generation ---
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            latched_num          <= 8'h00;
            latched_speed        <= 8'h00;
            latched_num_of_bytes <= 8'h00;
            Tx_Start_Pulse       <= 1'b0;
            Rx_Enable_Pulse      <= 1'b0;
        end else if (btn_c_long_press_event) begin
            latched_num          <= num;
            latched_speed        <= speed_dec;
            latched_num_of_bytes <= num_of_bytes_hex;
            
            if (rx_on) begin
                Rx_Enable_Pulse <= 1'b1;
                Tx_Start_Pulse  <= 1'b0;
            end else begin
                Rx_Enable_Pulse <= 1'b0;
                Tx_Start_Pulse  <= 1'b1;
            end
        end else begin
            // Rx_Enable_Pulse <= 1'b0;
            Tx_Start_Pulse  <= 1'b0;
        end
    end

endmodule