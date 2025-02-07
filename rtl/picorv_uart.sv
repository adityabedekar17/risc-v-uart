/* verilator lint_off PINMISSING */

`timescale 1ns/1ps
module picorv_uart #(
  parameter ClkFreq = 12000000,
  parameter BaudRate = 115200)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [0:0] rx_i
  ,output [0:0] tx_o);

  parameter RamWords = 256;

  wire [31:0] mem_addr, mem_wdata, mem_rdata;
  wire [3:0] mem_wstrb;
  wire [0:0] mem_valid, mem_instr, mem_ready;
  picorv32 #(
  ) picorv_inst (
    .clk(clk_i),
    .resetn(~reset_i),
    .mem_valid(mem_valid),
    .mem_instr(mem_instr),
    .mem_ready(mem_ready),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_rdata(mem_rdata)
  );

  // TODO figure out splitting memory regions for instructions and other
  // in the compiler and picorv. Need to define uart memory regions?

  wire [31:0] uart_rd_data;
  wire [0:0] uart_en, uart_rd_ready;

  assign uart_en = (mem_instr && mem_valid && (mem_wstrb == 4'b0000));
  
  uart_ram #(
    .ClkFreq(ClkFreq),
    .BaudRate(BaudRate)
  ) ur_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .rx_i(rx_i),
    .tx_o(tx_o),
    .rd_valid_i(uart_en),
    .rd_addr_i(mem_addr),
    .rd_data_o(uart_rd_data),
    .rd_valid_o(uart_rd_ready)
  );

  wire [$clog2(RamWords) - 1:0] ram_addr;
  wire [31:0] ram_rd_data_o;
  wire [3:0] ram_wen;
  wire [0:0] ram_en, addr_in_ram;

  logic [0:0] ram_ready_q;

  assign addr_in_ram = (~mem_instr & (mem_addr < (4 * RamWords)));
  assign ram_en = (mem_valid && ~mem_ready && addr_in_ram);
  assign ram_wen = ram_en ? mem_wstrb : 4'b0;

  // picorv gives address in bytes. Take 2 bits to the left
  // since this module is for words
  assign ram_addr = mem_addr[$clog2(RamWords) + 1:2];

  always_ff @(posedge clk_i) begin
    ram_ready_q <= ram_en;
  end

  ram_1r1w_sync #(
    .Width(32),
    .Words(RamWords)
  ) ram_inst (
    .clk_i(clk_i),
    .wr_en_i(ram_wen),
    .addr_i(ram_addr),
    .wr_data_i(mem_wdata),
    .rd_data_o(ram_rd_data_o)
  );

  assign mem_rdata = addr_in_ram ? ram_rd_data_o : uart_rd_data;
  assign mem_ready = (ram_ready_q || uart_rd_ready);
endmodule
