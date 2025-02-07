`timescale 1ns/1ps
module ram_1r1w_sync
  #(parameter Width = 32
  ,parameter Words = 256)
  (input [0:0] clk_i
  ,input [3:0] wr_en_i
  ,input [$clog2(Words) - 1 : 0] addr_i
  ,input [Width - 1:0] wr_data_i
  ,output [Width - 1:0] rd_data_o);

  logic [Width - 1:0] mem [0:Words - 1];

  always_ff @(posedge clk_i) begin
    if (wr_en_i[0]) begin
      mem[addr_i][7:0] <= wr_data_i[7:0];
    end
    if (wr_en_i[1]) begin
      mem[addr_i][15:8] <= wr_data_i[15:8];
    end
    if (wr_en_i[2]) begin
      mem[addr_i][23:16] <= wr_data_i[23:16];
    end
    if (wr_en_i[3]) begin
      mem[addr_i][31:24] <= wr_data_i[31:24];
    end
  end

  logic [Width - 1:0] rd_data_r;
  always_ff @(posedge clk_i) begin
    if (wr_en_i == 4'b0000) begin
      rd_data_r <= mem[addr_i];
    end else begin
      rd_data_r <= '0;
    end
  end

  assign rd_data_o = rd_data_r;
endmodule
