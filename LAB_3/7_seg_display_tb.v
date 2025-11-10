`timescale 1ns/1ps

module 7_seg_display_tb ;

	reg reset, clk, center_button, down_button;
	reg [15:0] num;
	reg [6:0] catode,anode;
	clk=0;
	reset=0;
	always #5 clk = ~clk;

	top_level mod_top (.clk100(clk),.reset(reset),.num(num),.center_button(center_button),
		.down_button(down_button),.seg_catode(catode),.seg_anode(anode));
	initial begin
		@ (posedge clk);
		reset=0;
		repeat (5) @ (posedge clk);
		reset=1;
		@ (posedge clk);

		num=16'h0000;
		center_button=1; //long press latch
		#100;
		center_button=0;
		#10;

		center_button=1;//short press Decimal view
		#20;
		center_button=0;

		down_button=1;//short press Decimal view
		#20;

		@ (posedge clk);
		reset=0;
		repeat (5) @ (posedge clk);
		reset=1;
		@ (posedge clk);


		num=16'hFFFF;
		center_button=1; //long press latch
		#100;
		center_button=0;
		#10;

		center_button=1;//short press Decimal view
		#20;
		center_button=0;

		down_button=1;//short press Decimal view
		#20;


		num=16'hDEAD;
		center_button=1; //long press latch
		#100;
		center_button=0;
		#10;

		num=16'hBEEF;//Check so the next num would not latch for #20 delay
		center_button=1;//short press Decimal view
		#20;
		center_button=0;

		down_button=1;//short press Decimal view
		#20;


		num=16'hBEEF;
		center_button=1; //long press latch
		#100;
		center_button=0;
		#10;

		center_button=1;//short press Decimal view
		#20;
		center_button=0;

		down_button=1;//short press Decimal view
		#20;



	end
endmodule : 7_seg_display_tb


//In waveforms, I would expect to see a
//1. Binary input
//2. Decoded decimal/hex value
//3. Decoded 7-segment digits (ten-thousands, thousands, hundreds, ...)
//4. The Anode + Cathode control signals