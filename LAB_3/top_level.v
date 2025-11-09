module top_level (
	input clk100,    // Clock
	input reset,// Asynchronous reset active low
	input [15:0] num,
	input load,
	input center_button,
	input down_button,
	output [6:0] seg_catode,
	output [6:0] seg_anode
);
	
	wire [19:0] num_bcd;
	wire [6:0] curr_seg;
	wire [3:0] curr_digit;
	wire [15:0] latched_num;

	smart_button_controller #(.CLK_FREQ(100_000_000)) button_ctrl
		(
		.clk(clk100),
		.reset(reset),
		.btn_in(center_button),
		.long_press_event(long_press),
		.short_press_event(short_press)
		);



	binary_to_bcd_16_bit bcd (
		.binary_in(num),
		.bcd_ones(num_bcd[3:0]),
		.bcd_tens(num_bcd[7:4]),
		.bcd_hundreds(num_bcd[11:8]),
		.bcd_thousands(num_bcd[15:12]),
		.bcd_tens_thousands(num_bcd[19:16])
	);

	seg_controller ctrl(
		.clk(clk100),
		.reset(reset),
		.in_segment(curr_seg),
		.num_binary(num),
		.num_bcd(num_bcd),
		.curr_digit(curr_digit),
		.out_seg_anode (seg_catode),
		.cathode (seg_anode)
	);

	seg_decoder dec (
		.digit_in(curr_digit),
		.segments(curr_seg)
		);

endmodule