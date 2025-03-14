/* verilator lint_off PINMISSING */

/* Based on memory control from the cpu, sends and receives bytes from the
 * uart controller program.
 * When loading word:
 *   Sent command byte: 0x77 (r = 0x77)
 *   Send four bytes of address over tx
 *   Wait for response
 *   Four bytes will be sent back
 *   Once the four bytes are received, set the ready signal high for one cycle
 * When storing word:
 *   Send command byte: {4'h2, wstrb} (w = 0x72, so the first digit is 2)
 *   Send four bytes for the address
 *   Send four bytes for the data
 *   Wait for response {200 = 0xc8}
 *   Once the ok repsonse is received, set the ready signal high for one cycle
 */

/* Based on hpdcache's cache-memory interface
 * Requests will contain an address, length, size, and an id.
 * There will be <length> transfers of 2^<size> bytes
 * The read command is 0x72 ('r' = 0x72), and the write command is 0x77 ('r' = 0x77)
 * The next byte send will be the number of transfers to be completed.
 * The next four bytes will be the address of the memory operation.
 * If the request was a read:
 *   Request <length> words from the uart controller
 *   For each word, output a valid signal and a response struct.
 *   On the last response set resp_r_last to high
 * 
 */
`timescale 1ns/1ps
`include "hpdcache_typedef.svh"

module uart_ram
  import config_pkg::*;
  import hpdcache_pkg::*;

  #(parameter ClkFreq = 12000000
  ,parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  
  ,input [0:0] rx_i
  ,output [0:0] tx_o

  ,input  [0:0]                 mem_req_read_valid_i
  ,input  hpdcache_mem_req_t    mem_req_read_i
  ,output [0:0]                 mem_req_read_ready_o

  ,input  [0:0]                 mem_resp_r_ready_i
  ,output [0:0]                 mem_resp_r_valid_o
  ,output hpdcache_mem_resp_r_t mem_resp_r_o

  ,input  [0:0]                 mem_req_write_valid_i
  ,input  hpdcache_mem_req_t    mem_req_write_i
  ,output [0:0]                 mem_req_write_ready_o

  ,input  [0:0]                 mem_req_write_data_valid_i
  ,input  hpdcache_mem_req_w_t  mem_req_write_data_i
  ,output [0:0]                 mem_req_write_data_ready_o

  ,input  [0:0]                 mem_resp_w_valid_i
  ,output [0:0]                 mem_resp_w_ready_o
  ,output hpdcache_mem_resp_w_t mem_resp_w_o
  );

  localparam [15:0] Prescale = 16'(ClkFreq / (BaudRate * 8));

  typedef enum {
    Idle, SendCommand, SendLen, SendAddr, WaitData, RecvData, WaitReady
  } uart_state_e;

  // operation of the request
  typedef enum {
    OP_READ, OP_WRITE
  } req_op_e;

  uart_state_e uart_state_d, uart_state_q;
  logic [7:0] s_axis_tdata;
  logic [0:0] s_axis_tvalid, m_axis_tready, req_reg_en, byte_cnt_up, data_reg_en, transfer_cnt_up;
  logic [0:0] mem_req_ready, mem_resp_r_valid;

  hpdcache_mem_addr_t req_addr_d, req_addr_q;
  hpdcache_mem_len_t req_len_d, req_len_q;
  // max size will be 4 bytes, therefore set size to 2 bits
  // assuming all transfers will have one byte, the 0 of the counter will
  // represent that first byte
  logic [1:0] req_size_d, req_size_q;
  hpdcache_mem_id_t req_id_d, req_id_q;
  req_op_e req_op_d, req_op_q;

  hpdcache_mem_resp_r_t mem_resp_r;

  always_comb begin
    uart_state_d = uart_state_q;

    // sending bytes
    s_axis_tdata = 8'h00;
    s_axis_tvalid = 1'b0;

    m_axis_tready = 1'b1;

    // ready valid signals
    mem_req_ready = 1'b0;
    mem_resp_r_valid = 1'b0;

    mem_resp_r = '0;

    // register the request
    req_addr_d = '0;
    req_len_d = '0;
    req_size_d = '0;
    req_id_d = '0;
    req_op_d = OP_READ;
    req_reg_en = 1'b1;

    // keep track of bytes sent (little endian)
    byte_cnt_up = 1'b0;

    // regisr the received data value
    data_reg_en =1'b0;

    // keep track of transfers
    transfer_cnt_up = 1'b0;


    unique case (uart_state_q)
    // Idle: wait for a valid request, then send the operation of that request
    // to the uart receiver, along with registering the input for use in later
    // states. Assumes s_axis_tready is high.
      Idle: begin
        mem_req_ready = 1'b1;
        if (mem_req_read_valid_i) begin
          uart_state_d = SendLen;

          // register the read request
          req_addr_d = mem_req_read_i.mem_req_addr;
          req_len_d = mem_req_read_i.mem_req_len;
          req_size_d = (1 << mem_req_read_i.mem_req_size) - 1'b1;
          req_id_d = mem_req_read_i.mem_req_id;
          req_reg_en = 1'b1;

          // send the read command
          s_axis_tdata = 8'h72;
          s_axis_tvalid = 1'b1;
        end else if (mem_req_write_valid_i) begin
          uart_state_d = SendLen;

          // register the write request
          req_addr_d = mem_req_write_i.mem_req_addr;
          req_len_d = mem_req_write_i.mem_req_len;
          req_size_d = (1 << mem_req_write_i.mem_req_size) - 1'b1;
          req_id_d = mem_req_write_i.mem_req_id;
          req_op_d = OP_WRITE;
          req_reg_en = 1'b1;

          // send the write command
          s_axis_tdata = 8'h77;
          s_axis_tvalid = 1'b1;
        end
      end
      // SendLen: send the amount of transfers that is needed.
      SendLen: begin
        if (s_axis_tready) begin
          uart_state_d = SendAddr;

          // send the length
          s_axis_tdata = req_len_q;
          s_axis_tvalid = 1'b1;
        end
      end
      // SendAddr: send the memory address one byte at a time. On the cycle
      // the fourth byte is sent, move to the next state.
      // Addr width is hardcoded here as 32
      SendAddr: begin
        case (byte_cnt_q)
          2'h0: s_axis_tdata = req_addr_q[7:0];
          2'h1: s_axis_tdata = req_addr_q[15:8];
          2'h2: s_axis_tdata = req_addr_q[23:16];
          2'h3: s_axis_tdata = req_addr_q[31:24];
          default: s_axis_tdata = '0;
        endcase
        s_axis_tvalid = 1'b1;

        if (s_axis_tready) begin
          byte_cnt_up = 1'b1;
          if (byte_cnt_q == 2'h3) begin
            // branch for rd wr
            if (req_op_q == OP_READ) begin
              uart_state_d = WaitData;
            end else begin
              // TODO fix for write
              uart_state_d = Idle;
            end
          end
        end
      end
      // WaitData: wait for the first byte of the data at the address is sent
      // form the controller (C program reading the elf)
      WaitData: begin
        if (m_axis_tvalid) begin
          uart_state_d = RecvData;
          data_reg_en = 1'b1;
          byte_cnt_up = 1'b1;
        end
      end
      // RecvData: receive bytes at a time and load it into the data register.
      // Once the fourth byte is received assert the ready signal and move
      // back to the Idle state.
      RecvData: begin
        if (m_axis_tvalid) begin
          data_reg_en = 1'b1;
          byte_cnt_up = 1'b1;
          if (byte_cnt_q == req_size_q) begin
            uart_state_d = WaitReady;
          end
        end
      end
      WaitReady: begin
        mem_resp_r_valid = 1'b1;

        mem_resp_r.mem_resp_r_error = HPDCACHE_MEM_RESP_OK;
        mem_resp_r.mem_resp_r_id = req_id_q;
        mem_resp_r.mem_resp_r_data = data_q;
        mem_resp_r.mem_resp_r_last = (transfer_cnt_q == req_len_q);

        if (mem_resp_r_ready_i) begin
          transfer_cnt_up = 1'b1;
          uart_state_d = (transfer_cnt_q == req_len_q) ?
            Idle : SendAddr;
          // move to the next word if necessary
          req_addr_d = req_addr_q + 32'd4;
        end
      end
    endcase
  end

  // register the state
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      uart_state_q <= Idle;
    end else begin
      uart_state_q <= uart_state_d;
    end
  end

  // register the request
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      req_addr_q <= '0;
      req_len_q  <= '0;
      req_size_q <= '0;
      req_id_q <= '0;
      req_op_q <= OP_READ;
    end else if (req_reg_en) begin
      req_addr_q <= req_addr_d;
      req_len_q <= req_len_d;
      req_size_q <= req_size_d;
      req_id_q <= req_id_d;
      req_op_q <= req_op_d;
    end
  end

  // hpdcache_data_t contains 4 bytes. The max number of bytes requested per
  // transfer should be 4.
  logic [1:0] byte_cnt_d, byte_cnt_q;
  always_comb begin
    if (byte_cnt_up) begin
      byte_cnt_d = byte_cnt_q + 1'b1;
    end else begin
      byte_cnt_d = byte_cnt_q;
    end
  end
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      byte_cnt_q <= '0;
    end else begin
      byte_cnt_q <= byte_cnt_d;
    end
  end

  logic [31:0] data_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      data_q <= '0;
    end else if (data_reg_en & (byte_cnt_q == 2'h0)) begin
      data_q[7:0] <= m_axis_tdata;
    end else if (data_reg_en & (byte_cnt_q == 2'h1)) begin
      data_q[15:8] <= m_axis_tdata;
    end else if (data_reg_en & (byte_cnt_q == 2'h2)) begin
      data_q[23:16] <= m_axis_tdata;
    end else if (data_reg_en & (byte_cnt_q == 2'h3)) begin
      data_q[31:24] <= m_axis_tdata;
    end
  end

  hpdcache_mem_len_t transfer_cnt_d, transfer_cnt_q;
  always_comb begin
    if (transfer_cnt_up) begin
      transfer_cnt_d = transfer_cnt_q + 1'b1;
    end else begin
      transfer_cnt_d = transfer_cnt_q;
    end
  end
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      transfer_cnt_q <= '0;
    end else begin
      transfer_cnt_q <= transfer_cnt_d;
    end
  end

  assign mem_req_read_ready_o = mem_req_ready;
  assign mem_req_write_ready_o = mem_req_ready;

  assign mem_resp_r_o = mem_resp_r;
  assign mem_resp_r_valid_o = mem_resp_r_valid;

  wire [7:0] m_axis_tdata;
  wire [0:0] s_axis_tready, m_axis_tvalid;
  uart #(
    .DATA_WIDTH(8)
  ) uart_inst (
    .clk(clk_i),
    .rst(reset_i),
    
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),

    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),

    .rxd(rx_i),
    .txd(tx_o),

    .prescale(Prescale)
  );

endmodule
