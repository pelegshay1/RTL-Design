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

	wire write_en;
	wire [7:0] latched_num;
	wire [7:0] latched_speed;
	wire [7:0] latched_num_of_bytes;
	wire end_of_byte;
	wire [7:0] byte_count;
	wire [7:0] byte_to_send;
	wire tx_start;
	wire finished;


	system_controller #(.CLK_FREQ(100_000_000)) button_ctrl
		(
			.clk(clk100),										//input
			.reset(reset), 										//input
			.btn_c(center_button), 								//input
			.one_sec_push (write_en), 						//output - FSM
			.num(num), 											//input
			.latched_num(latched_num), 							//output - Tx
			.speed (speed), 									//input
			.latched_speed (latched_speed), 					//output - Tx
			.num_of_bytes(num_of_bytes), 						//input
			.latched_num_of_bytes(latched_num_of_bytes)					 //output -Tx
		);

	Transmitter #(.CLK_FREQ(100_000_000), .BAUDRATE(57600)) tx
		(
			.clk(clk100), 						//input
			.tx_start(tx_start),				//input - start trasnmitting new byte
			.reset (reset), 					//input
			.byte_to_send (byte_to_send), 		//input from system controller
			.end_of_byte (end_of_byte), 		//output to FSM - switch to  IDLE state
			.data_out (tx_data_out)				//output to nexys7
		);

	FSM fsm (
		.clk(clk100),
		.reset(reset),
		.write_en (write_en),		 //input from system controller
		.num_of_bytes (latched_num_of_bytes), //input from system controller
		.speed (latched_speed), 			//input from system controller
		.end_of_byte(end_of_byte),			//input from Trasmitter for counter
		.data_tx(latched_num),				//input from system cotnroller - data to trasmit
		.led(led_byte),					//output to led on nexys7
		.total_row_count(byte_count),			//output to segment controller for display
		.byte_to_send (byte_to_send),		//output to tx - what byte we send
		.tx_start(tx_start),
		.finished ()
	);

	seg_controller #(.CLK400HZ(250000)) segment_ctrl
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