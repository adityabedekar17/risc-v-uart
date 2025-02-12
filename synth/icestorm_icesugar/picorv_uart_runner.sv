module picorv_uart_runner;

  logic [0:0] clk_i, reset_i, rx_i, tx_o;

  parameter ClkFreq = 12000000;
  parameter BaudRate = 115200;

  initial begin
    clk_i = 0;
    forever begin
      #4.167ns;
      clk_i = !clk_i;
    end
  end

  icesugar icesugar(
    .clk_12Mhz_i(clk_i),
    .rst_ni(~reset_i),
    .rx_i(rx_i),
    .tx_o(tx_o)
  );

  uart_sender #(
    .ClkFreq(ClkFreq),
    .BaudRate(BaudRate)
  ) us_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    // what the picorv_uart sends will be what the c program receives
    .rx_i(tx_o),
    .tx_o(rx_i)
  );

  task automatic wait_clk(input int cycles);
    repeat (cycles) @(posedge clk_i);
  endtask
  
  task automatic repeat_mem(input int times);
    repeat (times) begin
      us_inst.recv_word();
      us_inst.send_word();
    end
  endtask

  task automatic reset;
    reset_i = 1;
    repeat (100) @(posedge clk_i);
    reset_i = 0;
  endtask
endmodule
