module picorv_uart_tb
    import config_pkg::*;
    import dv_pkg::*;
    ;

picorv_uart_runner picorv_uart_runner ();

initial begin
    $dumpfile( "dump.fst" );
    $dumpvars;
    $display( "Begin simulation." );
    $urandom(100);
    $timeformat( -3, 3, "ms", 0);

    picorv_uart_runner.reset();

    $display( "End simulation." );
    $finish;
end
endmodule
