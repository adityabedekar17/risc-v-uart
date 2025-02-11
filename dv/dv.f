
dv/dv_pkg.sv

dv/picorv_uart_tb.sv

// files for uart_sender
dv/uart_sender.sv
third_party/alexforencich_uart/rtl/uart.v
third_party/alexforencich_uart/rtl/uart_rx.v
third_party/alexforencich_uart/rtl/uart_tx.v


--timing
-j 0
-Wall
--assert
--trace-fst
--trace-structs
--main-top-name "-"

// Run with +verilator+rand+reset+2
--x-assign unique
--x-initial unique

-Werror-IMPLICIT
-Werror-USERERROR
-Werror-LATCH

// Specifying c++14 may be required for some compilers
-CFLAGS -std=c++14

// for printing from picorv_uart
-DPRINT_MEM
