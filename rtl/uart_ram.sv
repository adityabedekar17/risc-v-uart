/* verilator lint_off PINMISSING */
module uart_ram
  #(parameter ClkFreq = 12000000
  ,parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  
  ,input [0:0] rx_i
  ,output [0:0] tx_o

  ,input [0:0] mem_valid
  ,input [0:0] mem_instr
  ,output [0:0] mem_ready
  ,input [31:0] mem_addr
  ,input [31:0] mem_wdata
  ,input [3:0] mem_wstrb);

  localparam [15:0] Prescale = 16'(ClkFreq / (BaudRate * 8));

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
endmodule;
