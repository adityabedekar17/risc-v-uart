module uart_sender
  #(parameter ClkFreq = 12000000
  ,parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [0:0] rx_i
  ,output [0:0] tx_o);
    
  localparam [15:0] Prescale = 16'(ClkFreq / (BaudRate * 8));

  logic [7:0] s_axis_tdata;
  logic [0:0] s_axis_tvalid, m_axis_tready;

  wire [7:0] m_axis_tdata;
  wire [0:0] s_axis_tready, m_axis_tvalid;

  /* verilator lint_off PINMISSING */
  uart uart_inst (
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
  /* verilator lint_on PINMISSING */

  logic [31:0] mem [0:255];
  initial begin
    // eventually move onto loading from hex, then to elf
		// $readmemh(instr.hex, mem);
    mem[0] = 32'h 3fc00093; //       li      x1,1020
    mem[1] = 32'h 0000a023; //       sw      x0,0(x1)
    mem[2] = 32'h 0000a103; // loop: lw      x2,0(x1)
    mem[3] = 32'h 00110113; //       addi    x2,x2,1
    mem[4] = 32'h 0020a023; //       sw      x2,0(x1)
    mem[5] = 32'h ff5ff06f; //       j       <loop>
  end

  initial begin
    s_axis_tdata = '0;
    s_axis_tvalid = 1'b0;
    m_axis_tready = 1'b1;
  end

  logic [31:0] addr;
  task automatic recv_word();
    for (int i = 0; i < 4; i ++) begin
      while (~m_axis_tvalid) @(posedge clk_i);
      case (i)
        0: addr[7:0] = m_axis_tdata;
        1: addr[15:8] = m_axis_tdata;
        2: addr[23:16] = m_axis_tdata;
        3: addr[31:24] = m_axis_tdata;
      endcase
      @(posedge clk_i);
    end
    @(posedge clk_i);
    $display("Received addr 0x%h", addr);
  endtask

  // currently only testing for 8-bit address space, limited by mem
  logic [7:0] word_addr;
  task automatic send_word();
    word_addr = addr[9:2];
    $display("Instr at 0x%h: %h", word_addr, mem[word_addr]);
    for (int i = 0; i < 4; i ++) begin
      while (~s_axis_tready) @(posedge clk_i);
      s_axis_tvalid = 1'b1;
      case (i)
        0: s_axis_tdata = mem[word_addr][7:0];
        1: s_axis_tdata = mem[word_addr][15:8];
        2: s_axis_tdata = mem[word_addr][23:16];
        3: s_axis_tdata = mem[word_addr][31:24];
      endcase
      @(posedge clk_i);
      s_axis_tvalid = 1'b0;
    end
    @(posedge clk_i);
  endtask
endmodule
