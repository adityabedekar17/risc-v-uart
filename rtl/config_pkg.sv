`timescale 1ns/1ps
package config_pkg;

// define structs and enums needed for design
/*parameter int HPDCACHE_REQ_NUM = 1; // 1 requester
parameter int HPDCACHE_WAYS_NUM = 4; // 4 way set-associative
parameter int HPDCACHE_SETS_NUM = 64; // 64 sets
parameter int HPDCACHE_WORD_WIDTH = 32; // 32 bits
parameter int HPDCACHE_LINE_WIDTH = 4; // 128 bit cache line
parameter int HPDCACHE_WBUF_DEPTH = 8; // 8 deep write buffer*/

// HPDcache configuration 
parameter hpdcache_pkg::hpdcache_cfg_t HPDcacheCfg = '{
  // Basic configuration
  NREQUESTERS: HPDCACHE_REQ_NUM,
  NWAYS: HPDCACHE_WAYS_NUM,
  NSETS: HPDCACHE_SETS_NUM,
  WORD_WIDTH: HPDCACHE_WORD_WIDTH,
  // Cache line configuration  
  NLINE_WORDS: HPDCACHE_LINE_WIDTH,
  // Write buffer configuration
  WBUF_DEPTH: HPDCACHE_WBUF_DEPTH,
  // Other parameters set to default
  default: '0
};

endpackage
