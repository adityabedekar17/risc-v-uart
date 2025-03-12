/* verilator lint_off PINMISSING */

`timescale 1ns/1ps
`include "hpdcache_typedef.svh"

module picorv_uart 
import config_pkg::*; #(
  parameter ClkFreq = 12000000,
  parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [0:0] rx_i
  ,output [0:0] tx_o);

  wire [31:0] mem_addr, mem_wdata, mem_rdata;
  wire [3:0] mem_wstrb;
  wire [0:0] mem_valid, mem_ready;
  picorv32 #(
  ) picorv_inst (
    .clk(clk_i),
    .resetn(~reset_i),
    .mem_valid(mem_valid),
    .mem_ready(mem_ready),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_rdata(mem_rdata)
  );

  wire [31:0] uart_rd_data;
  wire [0:0] uart_rd_ready;

  uart_ram #(
    .ClkFreq(ClkFreq),
    .BaudRate(BaudRate)
  ) ur_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .rx_i(rx_i),
    .tx_o(tx_o),
    .mem_valid_i(mem_valid),
    .mem_wstrb_i(mem_wstrb),
    .addr_i(mem_addr),
    .wr_data_i(mem_wdata),
    .rd_data_o(uart_rd_data),
    .ready_o(uart_rd_ready)
  );

  assign mem_rdata = uart_rd_data;
  assign mem_ready = uart_rd_ready;
  
  hpdcache_wrapper hpdcache_inst (
    clk_i,
    rst_ni,

    wbuf_flush_i,
    wbuf_empty_o,

    core_req_valid_i,
    core_req_ready_o,
    core_req_i,
    core_req_abort_i,
    core_req_tag_i,
    core_req_pma_i,
    core_rsp_valid_o,
    core_rsp_o,

    mem_req_read_ready_i,
    mem_req_read_valid_o,
    mem_req_read_o,

    mem_resp_read_ready_o,
    mem_resp_read_valid_i,
    mem_resp_read_i,
    
    mem_req_write_ready_i,
    mem_req_write_valid_o,
    mem_req_write_o,
    
    mem_req_write_data_ready_i,
    mem_req_write_data_valid_o,
    mem_req_write_data_o,
    
    mem_resp_write_ready_o,
    mem_resp_write_valid_i,
    mem_resp_write_i
  );
endmodule
