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

  task automatic recv_byte(output logic [7:0] command);
    while (~m_axis_tvalid) @(posedge clk_i);
    command = m_axis_tdata;
    @(posedge clk_i);
  endtask

  task automatic send_byte(input logic [7:0] response);
    while (~s_axis_tready) @(posedge clk_i);
    s_axis_tvalid = 1'b1;
    s_axis_tdata = response;
    @(posedge clk_i);
    s_axis_tvalid = 1'b0;
  endtask

  task automatic recv_word(output logic [31:0] word);
    for (int i = 0; i < 4; i ++) begin
      while (~m_axis_tvalid) @(posedge clk_i);
      case (i)
        0: word[7:0] = m_axis_tdata;
        1: word[15:8] = m_axis_tdata;
        2: word[23:16] = m_axis_tdata;
        3: word[31:24] = m_axis_tdata;
      endcase
      @(posedge clk_i);
    end
    @(posedge clk_i);
  endtask

  task automatic send_word(input logic [31:0] word);
    for (int i = 0; i < 4; i ++) begin
      while (~s_axis_tready) @(posedge clk_i);
      s_axis_tvalid = 1'b1;
      case (i)
        0: s_axis_tdata = word[7:0];
        1: s_axis_tdata = word[15:8];
        2: s_axis_tdata = word[23:16];
        3: s_axis_tdata = word[31:24];
      endcase
      @(posedge clk_i);
      s_axis_tvalid = 1'b0;
    end
    @(posedge clk_i);
  endtask

  logic [31:0] addr, data;
  logic [7:0] command;
  task automatic process_request();
    recv_byte(command);
    if (command == 8'h77) begin
      recv_word(addr);
      data = mem[8'(addr >> 2)];
      send_word(data);
      $display("[rd 0x%08h] 0x%08h", addr, data);
    end else if (command[7:4] == 4'h2) begin
      recv_word(addr);
      recv_word(data);
      mem[8'(addr >> 2)] = data;
      send_byte(8'hc8);
      $display("[wr 0x%08h] 0x%08h (wstrb=%b)", addr, data, command[3:0]);
    end else begin
      $display("Unexpected command received");
      $finish();
    end
  endtask
endmodule
