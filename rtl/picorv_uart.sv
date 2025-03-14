/* verilator lint_off PINMISSING */

`timescale 1ns/1ps
`include "hpdcache_typedef.svh"

`define PHYS_MEM_LIMIT 32'h20000

module picorv_uart 
import config_pkg::*;
import hpdcache_pkg::*;
#(
  parameter ClkFreq = 12000000,
  parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [0:0] rx_i
  ,output [0:0] tx_o);

  wire [31:0] mem_addr, mem_wdata;
  wire [3:0] mem_wstrb;
  wire [0:0] mem_valid;

  logic [31:0] mem_rdata;
  logic [0:0] mem_ready;

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

  uart_ram #(
    .ClkFreq(ClkFreq),
    .BaudRate(BaudRate)
  ) ur_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .rx_i(rx_i),
    .tx_o(tx_o),

    .mem_req_read_valid_i(mem_req_read_valid),
    .mem_req_read_i(mem_req_read),
    .mem_req_read_ready_o(mem_req_read_ready),

    .mem_resp_r_ready_i(mem_resp_read_ready),
    .mem_resp_r_valid_o(mem_resp_read_valid),
    .mem_resp_r_o(mem_resp_r),

    .mem_req_write_valid_i(mem_req_write_valid),
    .mem_req_write_i(mem_req_write),
    .mem_req_write_ready_o(mem_req_write_ready),

    .mem_req_write_data_valid_i(mem_req_write_data_valid),
    .mem_req_write_data_i(mem_req_wdata),
    .mem_req_write_data_ready_o(mem_req_write_data_ready),

    .mem_resp_w_valid_i(mem_resp_write_valid),
    .mem_resp_w_ready_o(mem_resp_write_ready),
    .mem_resp_w_o(mem_resp_w)
  );

  wire  [0:0]                   wbuf_flush;
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
    core_req_valid[0] = mem_valid;

    core_req[0].addr_offset = mem_addr[HPDcacheCfg.reqOffsetWidth - 1:0];
    core_req[0].wdata = mem_wdata;
    core_req[0].op = (|mem_wstrb) ?
      HPDCACHE_REQ_STORE : HPDCACHE_REQ_LOAD;
    core_req[0].be = mem_wstrb;
    // request is 32-bits => 4 bytes => 2^2
    core_req[0].size = 3'b10;
    core_req[0].sid = 1'b1;
    core_req[0].tid = 1'b1;
    // assume this never aborts
    core_req[0].need_rsp = 1'b1;
    // only uses phys mem, not virtual
    core_req[0].phys_indexed = 1'b1;
    core_req[0].addr_tag = mem_addr[31:31 - HPDcacheCfg.tagWidth + 1];
    // if addr is mmio
    core_req[0].pma.uncacheable =
      (mem_addr > `PHYS_MEM_LIMIT);
    core_req[0].pma.io = core_req[0].pma.uncacheable;
    core_req[0].pma.wr_policy_hint = HPDCACHE_WR_POLICY_WB;

    core_tag[0] = mem_addr[31:31 - HPDcacheCfg.tagWidth + 1];

    core_req_abort[0] = 1'b0;

    // not using virtual, so don't care
    core_pma[0] = '0;

    mem_ready = core_rsp_valid[0];
    mem_rdata = core_rsp[0].rdata;

    // Don't care about these
    /*
    core_rsp[0].sid;
    core_rsp[0].tid;
    core_rsp[0].error;
    core_rsp[0].aborted;
    */
  end

  wire [1:0] __unused__ = {core_req_ready[0], wbuf_empty};
  assign wbuf_flush = 1'b1;
endmodule
