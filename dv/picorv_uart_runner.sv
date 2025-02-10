module picorv_uart_runner;
  logic [0:0] clk_i;
  logic [0:0] reset_i;
  logic [0:0] rx_i;
  logic [0:0] tx_o;
  logic  mem_valid;
	logic  mem_instr;
	logic  mem_ready;
	logic  [31:0] mem_addr;
	logic  [31:0] mem_wdata;
	logic  [3:0] mem_wstrb;
	logic  [31:0] mem_rdata;
   parameter RamWords = 256;
  logic [$clog2(RamWords) - 1:0] ram_addr;
  logic [31:0] ram_rd_data_o;
  logic [3:0] ram_wen;
  logic [0:0] ram_en, addr_in_ram;
  logic [0:0] ram_ready_q;
  logic trap;


  initial begin
    clk_i = 0;
    forever begin
      #4.167ns;
      clk_i = !clk_i;
    end
  end
  /* verilator lint_off PINMISSING */
  picorv32 #(
	) uut (
		.clk         (clk_i        ),
		.resetn      (~reset_i     ),
    .trap(trap),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  )
	);
  /* verilator lint_on PINMISSING */
  
  assign addr_in_ram = ((mem_addr < (4 * RamWords)));
  assign ram_en = (mem_valid && ~mem_ready && addr_in_ram);
  assign ram_wen = ram_en ? mem_wstrb : 4'b0;

  // picorv gives address in bytes. Take 2 bits to the left
  // since this module is for words
  assign ram_addr = mem_addr[$clog2(RamWords) + 1:2];

  always_ff @(posedge clk_i) begin
    ram_ready_q <= ram_en;
  end

  assign mem_rdata = addr_in_ram ? ram_rd_data_o : 32'b0;
  assign mem_ready = ram_ready_q;

  ram_1r1w_sync #(.Width(32),.Words(RamWords))
  tb_ram_inst (.clk_i(clk_i),
  .wr_en_i(ram_wen), 
  .addr_i(ram_addr), 
  .wr_data_i(mem_wdata),
  .rd_data_o(ram_rd_data_o));

  always @(posedge clk_i) begin
		if (mem_valid && mem_ready) begin
			if (mem_instr)
				$display("ifetch 0x%08x: 0x%08x", mem_addr, mem_rdata);
			else if (mem_wstrb)
				$display("write  0x%08x: 0x%08x (wstrb=%b)", mem_addr, mem_wdata, mem_wstrb);
			else
				$display("read   0x%08x: 0x%08x", mem_addr, mem_rdata);
		end
	end

 task automatic init;
 tb_ram_inst.mem[0] =   32'h 3fc00093; //       li      x1,1020
 tb_ram_inst.mem[1] =   32'h 0000a023; //       sw      x0,0(x1)
 tb_ram_inst.mem[2] =   32'h 0000a103; // loop: lw      x2,0(x1)
 tb_ram_inst.mem[3] =   32'h 00110113; //       addi    x2,x2,1
 tb_ram_inst.mem[4] =   32'h 0020a023; //       sw      x2,0(x1)
 tb_ram_inst.mem[5] =   32'h ff5ff06f; //       j       <loop>
 
 endtask

 task automatic wait_clk(input int cycles);
    repeat (cycles) @(posedge clk_i);
 endtask

//mem[0]
  task automatic reset;
    reset_i = 1;
    repeat (100) @(posedge clk_i);
    reset_i = 0;
  endtask
endmodule
