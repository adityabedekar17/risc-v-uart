module picorv_uart_runner;
  logic [0:0] clk_i;
  logic [0:0] reset_i;
  logic [0:0] rx_i;
  logic [0:0] tx_o;

  initial begin
    clk_i = 0;
    forever begin
      #4.167ns;
      clk_i = !clk_i;
    end
  end

  picorv_uart #(
    .ClkFreq(12000000),
    .BaudRate(115200)
  ) picorv_uart (.*);

  task automatic reset;
    reset_i = 1;
    repeat (100) @(posedge clk_i);
    reset_i = 0;
  endtask
endmodule
