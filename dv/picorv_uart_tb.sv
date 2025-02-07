`timescale 1ns/1ps
module picorv_uart_tb
    import config_pkg::*;
    import dv_pkg::*;
    ;

picorv_uart_runner picorv_uart_runner ();

initial begin
    picorv_uart_runner.rx_i = 1'b1; // idle?
    // li x1,1
    //li x2,2
    // add x3,x1,x2 // check at x3 whether i can see result is 3
    // to check whether it is really 3 im guessing i have to look somewhere in the RISC-V IP
    
    picorv_uart_runner.picorv_uart.ram_inst
   

    repeat(20) @(posedge runner.clk_i) begin
      if (picorv_uart_runner.picorv_uart.mem_valid) && (picorv_uart_runner.picorv_uart.mem_ready) begin // ready valid
        $display("Time=%0t: Memory Access @ %h = %h", 
                $time, 
                picorv_uart_runner.picorv_uart.mem_addr,
                picorv_uart_runner.picorv_uart.mem_rdata);
      end
    end
    

     // Waveform dump
  initial begin
    $dumpfile("pico_uart_tb.vcd");
    $dumpvars(0, pico_uart_tb);
  end


    
    
    
    
    
    
    /*
    $dumpfile( "dump.fst" );
    $dumpvars;
    $display( "Begin simulation." );
    $urandom(100);
    $timeformat( -3, 3, "ms", 0);

    picorv_uart_runner.reset();

    $display( "End simulation." );
    $finish;*/
end


endmodule
