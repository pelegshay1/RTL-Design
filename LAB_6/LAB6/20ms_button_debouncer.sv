`timescale 1ns / 1ps

module button_debouncer #(parameter CLK_FREQ = 100_000_000) (
	input logic clk,    // Clock
	input logic reset, // reset
	input logic btn,  // Asynchronous reset active low
	output logic btn_debounce
);
	localparam int TWENTY_MS = CLK_FREQ / 50 ;

// --- 1. Button synchronizing to clk ---
	logic btn_sync1, btn_sync2;
	logic btn_stable;

	always_ff @(posedge clk or negedge reset) begin
		if (!reset) begin
			btn_sync1 <= 1'b0;
			btn_sync2 <= 1'b0;
		end else begin
			btn_sync1 <= btn;
			btn_sync2 <= btn_sync1;
		end
	end

	assign btn_stable = btn_sync2;

// --- 2. Timer for 20 ms press ---
	logic [$clog2(TWENTY_MS)-1:0] timer_reg;
	logic twenty_ms_reached;

	assign twenty_ms_reached = (timer_reg == TWENTY_MS - 1);

	logic press_fired;

	always_ff @(posedge clk or negedge reset) begin
		if (!reset) begin
			timer_reg            <= '0;
			press_fired <= 1'b0;
		end else if (btn_stable) begin // --- Button is PRESSED ---
			if (!twenty_ms_reached) begin
				timer_reg <= timer_reg + 1; // Count up to 1 second
			end
			// If we've reached 1 second AND we haven't fired the flag yet
			if (twenty_ms_reached && !press_fired) begin
				press_fired <= 1'b1;
			end
		end else begin // --- Button is RELEASED ---
			timer_reg            <= '0;
			press_fired <= 1'b0;
		end
	end

	assign btn_debounce = press_fired;

endmodule : button_debouncer