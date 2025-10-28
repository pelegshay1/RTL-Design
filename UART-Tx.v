module UART_Tx (
	input clk,    // Clock
	input reset,		//RESET signal
	input write_en, // Clock Enable
	input [31:0] data_out_perallel,  // data_in to be trasmitted 
	output data_out, // bit by bit data out
	output reg busy	//busy signal to data source - active when trasmitting data
);

endmodule