module top_level (
	input clk100,    // Clock
	input reset,// Asynchronous reset active low
	input [15:0] num,
	input center_button,
	input down_button,
	output [6:0] seg_catode,
	output [4:0] seg_anode
);
	
	wire [19:0] num_bcd;
	wire [6:0] curr_seg;
	wire [3:0] curr_digit;
	wire [15:0] latched_num;
	wire display_is_hex;

	system_controller #(.CLK_FREQ(100_000_000)) button_ctrl
		(
		.clk(clk100),
		.reset(reset),
		.sw(num),
		.btn_c(center_button),
		.btn_d(down_button),
		.latched_switch_value(latched_num),
		.display_is_hex (display_is_hex)
		);



	binary_to_bcd_16_bit bcd_converter (
		.binary_in(latched_num),
		.bcd_ones(num_bcd[3:0]),
		.bcd_tens(num_bcd[7:4]),
		.bcd_hundreds(num_bcd[11:8]),
		.bcd_thousands(num_bcd[15:12]),
		.bcd_tens_thousands(num_bcd[19:16])
	);

	seg_controller segment_ctrl(
		.clk(clk100),
		.reset(reset),
		.num_binary(latched_num),
		.num_bcd(num_bcd),
		.mode_is_hex(display_is_hex),
		.out_seg_anode (seg_anode),
		.cathode (seg_catode)
	);


endmodule