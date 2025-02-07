/* verilator lint_off PINMISSING */

/* Based on memory control from the cpu, sends and receives bytes from the
 * uart controller program.
 * Currently only able to send a read request.
 * When loading word:
 *   Send four bytes of address over tx
 *   Wait for response
 *   Four bytes will be sent back
 *   Once the four bytes are received, set the ready signal high for one cycle
 */
`timescale 1ns/1ps
module uart_ram
  #(parameter ClkFreq = 12000000
  ,parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  
  ,input [0:0] rx_i
  ,output [0:0] tx_o

  ,input [0:0] rd_valid_i
  ,input [31:0] rd_addr_i
  ,output [31:0] rd_data_o
  ,output [0:0] rd_valid_o);

  localparam [15:0] Prescale = 16'(ClkFreq / (BaudRate * 8));

  typedef enum {
    Idle, SendAddr
  } uart_state_e;

  uart_state_e uart_state_d, uart_state_q;

  logic [0:0] rd_valid_l, addr_reg_en;
  always_comb begin
    rd_valid_l = 1'b0;
    addr_reg_en = 1'b0;
    case (uart_state_q) 
      Idle: begin
        if (rd_valid_i) begin
          uart_state_d = SendAddr;
          addr_reg_en = 1'b1;
          // TODO send the first byte... little endian?
        end
      end
      SendAddr: begin
        // TODO repeat 4 cycles
        uart_state_d = Idle;
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

  logic [31:0] addr_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      addr_q <= '0;
    end else if (addr_reg_en) begin
      addr_q <= rd_addr_i;
    end
  end

  logic [31:0] data_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      data_q <= '0;
    end 
    // TODO load received data into register
  end

  logic [3:0] byte_count_q;
  always_ff @(posedge clk_i) begin
    // TODO reset when going to next state
    if (reset_i) begin
      byte_count_q <= '0;
    end 
    // TODO count up condition
  end

  // TODO assign addr_q to axis data according to state
  wire [7:0] s_axis_tdata, m_axis_tdata;
  wire [0:0] s_axis_tvalid, s_axis_tready, m_axis_tvalid, m_axis_tready;
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

  assign rd_valid_o = rd_valid_l;
  assign rd_data_o = data_q;
endmodule;
