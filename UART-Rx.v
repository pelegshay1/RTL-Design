module UART_Rx (
	input clk,    // Clock
	input reset, // reset 
	input read_en,  // Asynchronous reset active low
	input data_in,
	output reg [31:0] data_in_parallel,
	output ready_to_read
);

endmodule 