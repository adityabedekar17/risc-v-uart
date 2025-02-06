module icesugar 
  (input [0:0] clk_12Mhz_i 
  ,input [0:0] rst_ni 
  ,input [0:0] rx_i 
  ,output [0:0] tx_o);

  reg [0:0] sync_rx_q1, sync_rx_q2, sync_rst_n_q1, sync_rst_d2, sync_rst_q2;
  always @(posedge clk_12Mhz_i) begin
    sync_rx_q1 <= rx_i;
    sync_rx_q2 <= sync_rx_q1;

    sync_rst_n_q1 <= rst_ni;
    sync_rst_q2 <= sync_rst_d2;
  end
  always @(*) begin
    sync_rst_d2 = ~sync_rst_n_q1;
  end

  picorv_uart #(
    .ClkFreq(12000000),
    .BaudRate(115200)
  ) pu_inst (
    .clk_i(clk_12Mhz_i),
    .reset_i(sync_rst_q2),
    .rx_i(sync_rx_q2),
    .tx_o(tx_o)
  );
endmodule
