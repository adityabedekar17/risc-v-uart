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
  
  logic [0:0]                   wbuf_flush;
  logic [0:0]                   wbuf_empty;

  logic [0:0]                   core_req_valid[HPDCACHE_NREQUESTERS];
  logic [0:0]                   core_req_ready[HPDCACHE_NREQUESTERS];
  hpdcache_req_t                core_req[HPDCACHE_NREQUESTERS];
  logic [0:0]                   core_req_abort[HPDCACHE_NREQUESTERS];
  hpdcache_tag_t                core_tag[HPDCACHE_NREQUESTERS];
  hpdcache_pkg::hpdcache_pma_t  core_pma[HPDCACHE_NREQUESTERS];
  logic [0:0]                   core_rsp_valid[HPDCACHE_NREQUESTERS];
  hpdcache_rsp_t                core_rsp[HPDCACHE_NREQUESTERS];

  logic [0:0]                   mem_req_read_ready;
  logic [0:0]                   mem_req_read_valid;
  hpdcache_mem_req_t            mem_req_read;

  logic [0:0]                   mem_resp_read_ready;
  logic [0:0]                   mem_resp_read_valid;
  hpdcache_mem_resp_r_t         mem_resp_r;

  logic [0:0]                   mem_req_write_ready;
  logic [0:0]                   mem_req_write_valid;
  hpdcache_mem_req_t            mem_req_write;

  logic [0:0]                   mem_req_write_data_ready;
  logic [0:0]                   mem_req_write_data_valid;
  hpdcache_mem_req_w_t          mem_req_wdata;

  logic [0:0]                   mem_resp_write_ready;
  logic [0:0]                   mem_resp_write_valid;
  hpdcache_mem_resp_w_t         mem_resp_w;

  hpdcache_wrapper hpdcache_inst (
   .clk_i(clk_i),
   .rst_ni(~reset_i),

   .wbuf_flush_i(wbuf_flush),
   .wbuf_empty_o(wbuf_empty),

   .core_req_valid_i(core_req_valid),
   .core_req_ready_o(core_req_ready),
   .core_req_i(core_req),
   .core_req_abort_i(core_req_abort),
   .core_req_tag_i(core_tag),
   .core_req_pma_i(core_pma),
   .core_rsp_valid_o(core_rsp_valid),
   .core_rsp_o(core_rsp),

   .mem_req_read_ready_i(mem_req_read_ready),
   .mem_req_read_valid_o(mem_req_read_valid),
   .mem_req_read_o(mem_req_read),

   .mem_resp_read_ready_o(mem_resp_read_ready),
   .mem_resp_read_valid_i(mem_resp_read_valid),
   .mem_resp_read_i(mem_resp_r),

   .mem_req_write_ready_i(mem_req_write_ready),
   .mem_req_write_valid_o(mem_req_write_valid),
   .mem_req_write_o(mem_req_write),

   .mem_req_write_data_ready_i(mem_req_write_data_ready),
   .mem_req_write_data_valid_o(mem_req_write_data_ready),
   .mem_req_write_data_o(mem_req_wdata),

   .mem_resp_write_ready_o(mem_resp_write_ready),
   .mem_resp_write_valid_i(mem_resp_write_valid),
   .mem_resp_write_i(mem_resp_w)
  );

  always_comb begin
    // if instr was ebreak
    if (uart_rd_data == 32'h00100073) begin
      wbuf_flush = 1'b1;
    end else begin
      wbuf_flush = 1'b0;
    end
  end
endmodule
