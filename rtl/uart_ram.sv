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
`timescale 1ns/1ps
module uart_ram
  #(parameter ClkFreq = 12000000
  ,parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  
  ,input [0:0] rx_i
  ,output [0:0] tx_o

  ,input [0:0] mem_valid_i
  ,input [3:0] mem_wstrb_i
  ,input [31:0] addr_i
  ,input [31:0] wr_data_i
  ,output [31:0] rd_data_o
  ,output [0:0] ready_o);

  localparam [15:0] Prescale = 16'(ClkFreq / (BaudRate * 8));

  typedef enum {
    Idle, SendAddr, SendData, WaitData, RecvData, WaitAck
  } uart_state_e;

  uart_state_e uart_state_d, uart_state_q;

  logic [7:0] s_axis_tdata;
  logic [0:0] s_axis_tvalid, m_axis_tready, data_reg_en, byte_cnt_up, data_ready;
  always_comb begin
    uart_state_d = uart_state_q;
    s_axis_tdata = 8'h00;

    s_axis_tvalid = 1'b0;
    m_axis_tready = 1'b1;
    data_reg_en = 1'b0;
    byte_cnt_up = 1'b0;
    data_ready = 1'b0;

    unique case (uart_state_q) 
      Idle: begin
        if (s_axis_tready & mem_valid_i) begin
          uart_state_d = SendAddr;

          // Send the command byte for rd or wr
          s_axis_tvalid = 1'b1;
          s_axis_tdata = (mem_wstrb_i == 4'b0000) ? 8'h77 : {4'h2, mem_wstrb_i};
        end
      end
      // SendAddr: send the memory address one byte at a time. On the cycle
      // the fourth byte is sent, move to the next state.
      SendAddr: begin
        case (byte_cnt_q)
          2'h0: s_axis_tdata = addr_i[7:0];
          2'h1: s_axis_tdata = addr_i[15:8];
          2'h2: s_axis_tdata = addr_i[23:16];
          2'h3: s_axis_tdata = addr_i[31:24];
          default: s_axis_tdata = '0;
        endcase
        s_axis_tvalid = 1'b1;

        if (s_axis_tready) begin
          byte_cnt_up = 1'b1;
          if (byte_cnt_q == 2'h3) begin
            if (mem_wstrb_i == 4'b0000) begin
              uart_state_d = WaitData;
            end else begin
              uart_state_d = SendData;
            end
          end
        end
      end
      SendData: begin
        case (byte_cnt_q)
          2'h0: s_axis_tdata = wr_data_i[7:0];
          2'h1: s_axis_tdata = wr_data_i[15:8];
          2'h2: s_axis_tdata = wr_data_i[23:16];
          2'h3: s_axis_tdata = wr_data_i[31:24];
          default: s_axis_tdata = '0;
        endcase
        s_axis_tvalid = 1'b1;

        if (s_axis_tready) begin
          byte_cnt_up = 1'b1;
          if (byte_cnt_q == 2'h3) begin
            uart_state_d = WaitAck;
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
          if (byte_cnt_q == 2'h3) begin
            uart_state_d = Idle;
            data_ready = 1'b1;
          end
        end
      end
      WaitAck: begin
        if (m_axis_tvalid) begin
          uart_state_d = Idle;
          data_ready = 1'b1;
        end
      end
      default: begin
        uart_state_d = Idle;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      uart_state_q <= Idle;
    end else begin
      uart_state_q <= uart_state_d;
    end
  end

  logic [23:0] data_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      data_q <= '0;
    end else if (data_reg_en & (byte_cnt_q == 2'h0)) begin
      data_q[7:0] <= m_axis_tdata;
    end else if (data_reg_en & (byte_cnt_q == 2'h1)) begin
      data_q[15:8] <= m_axis_tdata;
    end else if (data_reg_en & (byte_cnt_q == 2'h2)) begin
      data_q[23:16] <= m_axis_tdata;
    end
  end

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

  assign ready_o = data_ready;
  assign rd_data_o = {m_axis_tdata, data_q};
endmodule
