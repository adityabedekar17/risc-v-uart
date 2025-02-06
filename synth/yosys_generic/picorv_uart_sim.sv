
module picorv_uart_sim (
    input  logic clk_i,
    input  logic reset_i,
    input  logic rx_i,
    output logic tx_o
);

picorv_uart #(
  .ClkFreq(12000000),
  .BaudRate(115200)
) picorv_uart (.*);

endmodule
