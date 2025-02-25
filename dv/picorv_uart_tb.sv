`timescale 1ns/1ps
module picorv_uart_tb
  import config_pkg::*;
  import dv_pkg::*;
  ;

  picorv_uart_runner runner ();

  initial begin
    $dumpfile("dump.fst");
    $dumpvars;
    $display("Begin simulation.");
    $urandom(100);
    $timeformat( -3, 3, "ms", 0);

    runner.reset();
    while (1) begin
      runner.repeat_mem(1);
    end

    $display("End simulation.");
    $finish;  
  end
endmodule
