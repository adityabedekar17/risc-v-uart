`timescale 1ns/1ps

`include "hpdcache_typedef.svh"
package config_pkg;

import hpdcache_pkg::*;

  localparam int unsigned HPDCACHE_NREQUESTERS = 1;

  localparam hpdcache_pkg::hpdcache_user_cfg_t HPDcacheUserCfg = '{
      nRequesters: HPDCACHE_NREQUESTERS,
      // physical address for 128kB of memory (set in section.lds)
      paWidth: 14,
      // word width 32-bits defined by isa
      wordWidth: 32,
      // 64 sets * 8 ways * 8 words * 32 bits/word = 131072 bits of cache
      // which is exactly the amount of bram available on the ice40up5k
      sets: 64,
      ways: 8,
      clWords: 8,
      // 1 word per request
      reqWords: 1,
      // TODO figure out tid
      reqTransIdWidth: 6,
      reqSrcIdWidth: 3,
      // PLRU eviction strategy
      victimSel: hpdcache_pkg::HPDCACHE_VICTIM_PLRU,
      // TODO figure out difference between this and the sets above
      dataWaysPerRamWord: 2,
      dataSetsPerRam: 64,
      // enable byte enable masking instead of bit masking
      dataRamByteEnable: 1'b1,
      // How many simultaneous accesses are allowed from the cache
      // since there are 4 separate bram modules each containing 16 bits,
      // I will try 2 simultaneout accesses
      accessWords: 2,
      mshrSets: 32,
      mshrWays: 2,
      mshrWaysPerRamWord: 2,
      mshrSetsPerRam: 32,
      mshrRamByteEnable: 1'b1,
      mshrUseRegbank: 1,
      refillCoreRspFeedthrough: 1'b1,
      refillFifoDepth: 2,
      wbufDirEntries: 16,
      wbufDataEntries: 8,
      wbufWords: 4,
      wbufTimecntWidth: 3,
      rtabEntries: 4,
      flushEntries: 4,
      flushFifoDepth: 2,
      // uart expects 32 bits address
      memAddrWidth: 32,
      // TODO figure out mem id
      memIdWidth: 6,
      // uart expects 32 bits of data
      memDataWidth: 32,
      // don't write through, but write back
      wtEn: 1'b0,
      wbEn: 1'b1
  };

  localparam hpdcache_pkg::hpdcache_cfg_t HPDcacheCfg = hpdcache_pkg::hpdcacheBuildConfig(
      HPDcacheUserCfg
  );

  localparam type hpdcache_mem_addr_t = logic [HPDcacheCfg.u.memAddrWidth-1:0];
  localparam type hpdcache_mem_id_t = logic [HPDcacheCfg.u.memIdWidth-1:0];
  localparam type hpdcache_mem_data_t = logic [HPDcacheCfg.u.memDataWidth-1:0];
  localparam type hpdcache_mem_be_t = logic [HPDcacheCfg.u.memDataWidth/8-1:0];
  localparam type hpdcache_mem_req_t =
      `HPDCACHE_DECL_MEM_REQ_T(hpdcache_mem_addr_t, hpdcache_mem_id_t);
  localparam type hpdcache_mem_resp_r_t =
      `HPDCACHE_DECL_MEM_RESP_R_T(hpdcache_mem_id_t, hpdcache_mem_data_t);
  localparam type hpdcache_mem_req_w_t =
      `HPDCACHE_DECL_MEM_REQ_W_T(hpdcache_mem_data_t, hpdcache_mem_be_t);
  localparam type hpdcache_mem_resp_w_t =
      `HPDCACHE_DECL_MEM_RESP_W_T(hpdcache_mem_id_t);

  localparam type hpdcache_tag_t = logic [HPDcacheCfg.tagWidth-1:0];
  localparam type hpdcache_data_word_t = logic [HPDcacheCfg.u.wordWidth-1:0];
  localparam type hpdcache_data_be_t = logic [HPDcacheCfg.u.wordWidth/8-1:0];
  localparam type hpdcache_req_offset_t = logic [HPDcacheCfg.reqOffsetWidth-1:0];
  localparam type hpdcache_req_data_t = hpdcache_data_word_t [HPDcacheCfg.u.reqWords-1:0];
  localparam type hpdcache_req_be_t = hpdcache_data_be_t [HPDcacheCfg.u.reqWords-1:0];
  localparam type hpdcache_req_sid_t = logic [HPDcacheCfg.u.reqSrcIdWidth-1:0];
  localparam type hpdcache_req_tid_t = logic [HPDcacheCfg.u.reqTransIdWidth-1:0];
  localparam type hpdcache_req_t =
      `HPDCACHE_DECL_REQ_T(hpdcache_req_offset_t,
                           hpdcache_req_data_t,
                           hpdcache_req_be_t,
                           hpdcache_req_sid_t,
                           hpdcache_req_tid_t,
                           hpdcache_tag_t);
  localparam type hpdcache_rsp_t =
      `HPDCACHE_DECL_RSP_T(hpdcache_req_data_t,
                           hpdcache_req_sid_t,
                           hpdcache_req_tid_t);

  localparam type hpdcache_wbuf_timecnt_t = logic [HPDcacheCfg.u.wbufTimecntWidth-1:0];
endpackage
