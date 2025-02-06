module picorv_uart_runner;
  logic [0:0] clk_i;
  logic [0:0] reset_i;
  logic [0:0] rx_i;
  logic [0:0] tx_o;

  localparam realtime ClockPeriod = 5ms;

  initial begin
    clk_i = 0;
    forever begin
      #(ClockPeriod/2);
      clk_i = !clk_i;
    end
  end

  picorv_uart_sim picorv_uart_sim (.*);

  task automatic reset;
    reset_i = 1;
    repeat (100) @(posedge clk_i);
    reset_i = 0;
  endtask
endmodule
