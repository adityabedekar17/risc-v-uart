module picorv_uart #(
  parameter ClkFreq = 1200000,
  parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [0:0] rx_i
  ,output [0:0] tx_o);

  localparam Prescale = (ClkFreq / (BaudRate * 8));

  wire [3:0] __unused__ = {clk_i, reset_i, rx_i, tx_o};
endmodule
