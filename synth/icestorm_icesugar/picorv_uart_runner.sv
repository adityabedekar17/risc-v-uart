module picorv_uart_runner;
  logic [0:0] clk_12Mhz_i;
  logic [0:0] rst_ni;
  logic [0:0] rx_i;
  logic [0:0] tx_o;

  initial begin
    clk_12Mhz_i = 0;
    forever begin
      #4.167ns;
      clk_12Mhz_i = !clk_12Mhz_i;
    end
  end

  icesugar icesugar(.*);

  task automatic reset;
    rst_ni = 0;
    repeat (100) @(posedge clk_12Mhz_i);
    rst_ni = 1;
  endtask
endmodule
