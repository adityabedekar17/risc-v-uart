/* verilator lint_off PINMISSING */

`timescale 1ns/1ps
`include "hpdcache_pkg.svh"

module picorv_uart #(
  parameter ClkFreq = 12000000,
  parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [0:0] rx_i
  ,output [0:0] tx_o);

  import hpdcache_pkg::*;

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

  // HPDcache signals
  hpdcache_req_t core_req;
  hpdcache_rsp_t core_rsp;
  logic core_req_valid, core_req_ready, core_req_abort;
  logic [31:0] core_req_tag;
  hpdcache_pma_t core_req_pma;
  logic core_rsp_valid;

  // Cache adapter
  picorv_cache_adapter #(
    .hpdcache_req_t(hpdcache_req_t),
    .hpdcache_rsp_t(hpdcache_rsp_t)
  ) cache_adapter (
    .clk_i(clk_i),
    .rst_ni(~reset_i),
    
    // PicoRV32 interface
    .mem_valid_i(mem_valid),
    .mem_ready_o(mem_ready), 
    .mem_addr_i(mem_addr),
    .mem_wdata_i(mem_wdata),
    .mem_wstrb_i(mem_wstrb),
    .mem_rdata_o(mem_rdata),

    // HPDcache interface  
    .core_req_o(core_req),
    .core_req_valid_o(core_req_valid),
    .core_req_ready_i(core_req_ready),
    .core_req_abort_o(core_req_abort),
    .core_req_tag_o(core_req_tag),
    .core_req_pma_o(core_req_pma),
    .core_rsp_i(core_rsp),
    .core_rsp_valid_i(core_rsp_valid)
  );

  // HPDcache instance
  hpdcache #(
    .HPDcacheCfg                     (HPDcacheCfg),
    .hpdcache_tag_t                  (hpdcache_tag_t),
    .hpdcache_req_t                  (hpdcache_req_t), 
    .hpdcache_rsp_t                  (hpdcache_rsp_t),
    // ...other parameterization from hpdcache_pkg...
  ) hpdcache_i (
    .clk_i(clk_i),
    .rst_ni(~reset_i),

    // Cache control
    .wbuf_flush_i(1'b0),
    .cfg_enable_i(1'b1),
    
    // Core request interface
    .core_req_valid_i('{core_req_valid}),
    .core_req_ready_o('{core_req_ready}),
    .core_req_i('{core_req}),
    .core_req_abort_i('{core_req_abort}),
    .core_req_tag_i('{core_req_tag}),
    .core_req_pma_i('{core_req_pma}),

    // Core response interface  
    .core_rsp_valid_o('{core_rsp_valid}),
    .core_rsp_o('{core_rsp}),

    // Memory interfaces
    .mem_req_read_ready_i(uart_rd_ready),
    .mem_req_read_valid_o(),
    .mem_req_read_o(),
    .mem_resp_read_ready_o(),
    .mem_resp_read_valid_i(),
    .mem_resp_read_i(),
    
    .mem_req_write_ready_i(),
    .mem_req_write_valid_o(), 
    .mem_req_write_o(),
    .mem_req_write_data_ready_i(),
    .mem_req_write_data_valid_o(),
    .mem_req_write_data_o(),
    .mem_resp_write_ready_o(),
    .mem_resp_write_valid_i(),
    .mem_resp_write_i()
  );

endmodule
