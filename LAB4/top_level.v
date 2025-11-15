module top_level (
	input clk100,    // Clock
	input reset,  // Asynchronous reset active low
	input [7:0] num,
	input [1:0] speed,
	input [1:0] num_of_bytes,
	input center_button,
	output tx_data_out,
	output led_byte,
	output [7:0] catode,
	output [7:0] anode
);

	wire one_sec_push;
	wire [7:0] latched_num;
	wire [1:0] latched_speed;
	wire [1:0] latched_num_of_bytes;
	wire done_s;
	wire wait_s;
	wire special_char_s;
	wire byte_s;
	wire byte_count;


	system_controller #(.CLK_FREQ(100_000_000)) button_ctrl
		(
			.clk(clk100),										//input
			.reset(reset), 										//input
			.btn_c(center_button), 								//input
			.one_sec_push (one_sec_push), 						//output - FSM
			.num(num), 											//input
			.latched_num(latched_num), 							//output - Tx
			.speed (speed), 									//input
			.latched_speed (latched_speed), 					//output - Tx
			.num_of_bytes(num_of_bytes), 						//input
			.latched_num_of_bytes(latched_num_of_bytes)					 //output -Tx
		);

	Transmitter #(.CLK_FREQ(100_000_000)) tx
		(
			.clk(clk100), 						//input
			.reset (reset), 					//input
			.num (latched_num), 				//input from system controller
			.speed (latched_speed), 			//input from system controller
			.num_of_bytes (latched_num_of_bytes), //input from system controller
			.byte_on_off (byte_s), 				//output to FSM - decide if led is on or off (to seperate states) 1.BYTE_ON='1' 2.BYTE_OFF='0'
			.special_char (special_char_s), 	//output to FSM - switch to SPECIAL_CHAR state
			.wait_s (wait_s), 					//output to FSM - switch to WAIT state
			.done (done_s), 					//output to FSM - switch to  IDLE state
			.byte_count(byte_count),			//output to segment controller for display
			.data_out (tx_data_out)				//output to nexys7
		);

	FSM fsm (
		.clk(clk100),
		.reset(reset),
		.one_sec_push (one_sec_push),		 //input
		.done(done_s),						//input
		.wait_s(wait_s),						//input
		.special_char(special_char_s),		//input
		.byte_s(byte_s),						//input
		.led(led_byte)						//output to led on nexys7
	);

	seg_controller  #(.CLK_FREQ(100_000_000)) segment_ctrl
		(
			.clk(clk100),						//input
			.reset(reset),						//input
			.num(latched_num),					//input T0 - selected byte
			.speed(latched_speed),				//input T1 - speed configuration
			.num_of_bytes (latched_num_of_bytes),//input T2 -total bytes to send
			.byte_count (byte_count),			//input T3 - trasmitted bytes
			.cathode (catode),					//output seg display catode
			.anode (anode)						//output seg display anode
		);



endmodule