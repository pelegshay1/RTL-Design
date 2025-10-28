module top_level (input wire clk,
input wire reset,
input wire switch01,
input wire switch02,
input wire switch03,
input wire push01,
input wire push02,
input wire push03,
output wire led1,
output wire led2,
output wire led3,
input wire [31:0] databus_out_parallel,
input wire databus_uart_in,
output wire databus_uart_out,
input wire write_en_uart_tx,
input wire read_en_uart_rx,
output wire [31:0] databus_in_parallel
  );

  // general
  //eg clk;

  // UART Tx
  //wire reset_uart_tx;
  //wire write_en_uart_tx;
  //wire [31:0] data_out_uart_tx;
 // wire databus_uart;
 // wire busy_uart_tx;

  // UART Rx
  wire reset_uart_rx;
  //wire read_en_uart_rx;
  //wire data_in_uart_rx;
  //wire [31:0] data_in_uart_rx_paralle;
  wire ready_to_read_uart_rx;

  // UART_TX instance
  UART_Tx TX (
    .clk(clk),
    .reset(reset),
    .write_en(write_en_uart_tx),
    .data_out_perallel(databus_out_parallel),
    .data_out(databus_uart_out),
    .busy(busy_uart_tx)
  );

  // UART_RX instance

  UART_Rx RX (
    .clk(clk),
    .reset(reset),
    .read_en(read_en_uart_rx),
    .data_in_parallel(databus_in_parallel),
    .data_in(databus_uart_in),
    .ready_to_read(ready_to_read_uart_rx)
  );

  assign led1 = busy_uart_tx;
  assign led2 = ready_to_read_uart_rx;

endmodule
