/*
 *  Copyright 2023 CEA*
 *  *Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Licensed under the Solderpad Hardware License v 2.1 (the “License”); you
 *  may not use this file except in compliance with the License, or, at your
 *  option, the Apache License version 2.0. You may obtain a copy of the
 *  License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */
/*
 *  Authors       : Cesar Fuguet
 *  Creation Date : April, 2024
 *  Description   : HPDcache Wrapper for Code Linting Check
 *  History       :
 */
`include "hpdcache_typedef.svh"

module hpdcache_wrapper
  import config_pkg::*;
  import hpdcache_pkg::*;
(
  input  logic                        clk_i,
  input  logic                        rst_ni,

  input  logic                        wbuf_flush_i,
  output logic                        wbuf_empty_o,

  input  logic                        core_req_valid_i         [HPDCACHE_NREQUESTERS],
  output logic                        core_req_ready_o         [HPDCACHE_NREQUESTERS],
  input  hpdcache_req_t               core_req_i               [HPDCACHE_NREQUESTERS],
  input  logic                        core_req_abort_i         [HPDCACHE_NREQUESTERS],
  input  hpdcache_tag_t               core_req_tag_i           [HPDCACHE_NREQUESTERS],
  input  hpdcache_pkg::hpdcache_pma_t core_req_pma_i           [HPDCACHE_NREQUESTERS],
  output logic                        core_rsp_valid_o         [HPDCACHE_NREQUESTERS],
  output hpdcache_rsp_t               core_rsp_o               [HPDCACHE_NREQUESTERS],

  input  logic                        mem_req_read_ready_i,
  output logic                        mem_req_read_valid_o,
  output hpdcache_mem_req_t           mem_req_read_o,

  output logic                        mem_resp_read_ready_o,
  input  logic                        mem_resp_read_valid_i,
  input  hpdcache_mem_resp_r_t        mem_resp_read_i,

  input  logic                        mem_req_write_ready_i,
  output logic                        mem_req_write_valid_o,
  output hpdcache_mem_req_t           mem_req_write_o,

  input  logic                        mem_req_write_data_ready_i,
  output logic                        mem_req_write_data_valid_o,
  output hpdcache_mem_req_w_t         mem_req_write_data_o,

  output logic                        mem_resp_write_ready_o,
  input  logic                        mem_resp_write_valid_i,
  input  hpdcache_mem_resp_w_t        mem_resp_write_i
);

  hpdcache #(
      .HPDcacheCfg          (HPDcacheCfg),
      .wbuf_timecnt_t       (hpdcache_wbuf_timecnt_t),
      .hpdcache_tag_t       (hpdcache_tag_t),
      .hpdcache_data_word_t (hpdcache_data_word_t),
      .hpdcache_data_be_t   (hpdcache_data_be_t),
      .hpdcache_req_offset_t(hpdcache_req_offset_t),
      .hpdcache_req_data_t  (hpdcache_req_data_t),
      .hpdcache_req_be_t    (hpdcache_req_be_t),
      .hpdcache_req_sid_t   (hpdcache_req_sid_t),
      .hpdcache_req_tid_t   (hpdcache_req_tid_t),
      .hpdcache_req_t       (hpdcache_req_t),
      .hpdcache_rsp_t       (hpdcache_rsp_t),
      .hpdcache_mem_addr_t  (hpdcache_mem_addr_t),
      .hpdcache_mem_id_t    (hpdcache_mem_id_t),
      .hpdcache_mem_data_t  (hpdcache_mem_data_t),
      .hpdcache_mem_be_t    (hpdcache_mem_be_t),
      .hpdcache_mem_req_t   (hpdcache_mem_req_t),
      .hpdcache_mem_req_w_t (hpdcache_mem_req_w_t),
      .hpdcache_mem_resp_r_t(hpdcache_mem_resp_r_t),
      .hpdcache_mem_resp_w_t(hpdcache_mem_resp_w_t)
  ) i_hpdcache (
      .clk_i,
      .rst_ni,

      .wbuf_flush_i,

      .core_req_valid_i,
      .core_req_ready_o,
      .core_req_i,
      .core_req_abort_i,
      .core_req_tag_i,
      .core_req_pma_i,

      .core_rsp_valid_o,
      .core_rsp_o,

      .mem_req_read_ready_i,
      .mem_req_read_valid_o,
      .mem_req_read_o,

      .mem_resp_read_ready_o,
      .mem_resp_read_valid_i,
      .mem_resp_read_i,

      .mem_req_write_ready_i,
      .mem_req_write_valid_o,
      .mem_req_write_o,

      .mem_req_write_data_ready_i,
      .mem_req_write_data_valid_o,
      .mem_req_write_data_o,

      .mem_resp_write_ready_o,
      .mem_resp_write_valid_i,
      .mem_resp_write_i,

      .evt_cache_write_miss_o(  /* unused */),
      .evt_cache_read_miss_o (  /* unused */),
      .evt_uncached_req_o    (  /* unused */),
      .evt_cmo_req_o         (  /* unused */),
      .evt_write_req_o       (  /* unused */),
      .evt_read_req_o        (  /* unused */),
      .evt_prefetch_req_o    (  /* unused */),
      .evt_req_on_hold_o     (  /* unused */),
      .evt_rtab_rollback_o   (  /* unused */),
      .evt_stall_refill_o    (  /* unused */),
      .evt_stall_o           (  /* unused */),

      .wbuf_empty_o,

      .cfg_enable_i                       (1'b1),
      .cfg_wbuf_threshold_i               (3'd2),
      .cfg_wbuf_reset_timecnt_on_write_i  (1'b1),
      .cfg_wbuf_sequential_waw_i          (1'b0),
      .cfg_wbuf_inhibit_write_coalescing_i(1'b0),
      .cfg_prefetch_updt_plru_i           (1'b1),
      .cfg_error_on_cacheable_amo_i       (1'b0),
      .cfg_rtab_single_entry_i            (1'b0),
      .cfg_default_wb_i                   (1'b0)
  );

endmodule
