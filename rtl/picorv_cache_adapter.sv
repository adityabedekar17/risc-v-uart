`include "hpdcache_pkg.svh"
`include "hpdcache_typedef.svh"

module picorv_cache_adapter 
  import hpdcache_pkg::*;
  #(
    parameter type hpdcache_req_t = logic, //request type
    parameter type hpdcache_rsp_t = logic //response type
  )
  (
    input  logic clk_i,
    input  logic rst_ni,

    // PicoRV32 memory interface
    input  logic        mem_valid_i,
    output logic        mem_ready_o,
    input  logic [31:0] mem_addr_i,
    input  logic [31:0] mem_wdata_i,
    input  logic [3:0]  mem_wstrb_i,
    output logic [31:0] mem_rdata_o,

    // HPDcache interface
    output hpdcache_req_t core_req_o,
    output logic         core_req_valid_o,
    input  logic         core_req_ready_i,
    output logic         core_req_abort_o,
    output logic [31:0]  core_req_tag_o,
    output hpdcache_pma_t core_req_pma_o,
    
    input  hpdcache_rsp_t core_rsp_i,
    input  logic          core_rsp_valid_i
  );

  // Convert PicoRV32 memory request to HPDcache request
  always_comb begin
    core_req_o.req_addr = mem_addr_i;
    core_req_o.req_size = HPDCACHE_REQ_SIZE_WORD;
    core_req_o.req_width = HPDCACHE_REQ_WIDTH_WORD;
    core_req_o.req_type = mem_wstrb_i ? HPDCACHE_REQ_STORE : HPDCACHE_REQ_LOAD;
    core_req_o.req_data = mem_wdata_i;
    core_req_o.req_be = mem_wstrb_i;
    core_req_o.req_sid = '0;  // Only one requester
    core_req_o.req_tid = '0;  // No threading
    core_req_o.req_need_rsp = 1'b1;

    core_req_valid_o = mem_valid_i;
    core_req_abort_o = 1'b0;
    core_req_tag_o = '0;
    core_req_pma_o = '{
      default: '0,
      cacheable: 1'b1,
      atomic: 1'b0
    };

    // Signal readiness when request accepted or response received
    mem_ready_o = core_req_ready_i | core_rsp_valid_i;
    mem_rdata_o = core_rsp_i.rsp_data;
  end

endmodule
