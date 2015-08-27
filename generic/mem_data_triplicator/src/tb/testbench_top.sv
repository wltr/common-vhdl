//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Testbench top level module for serial transceiver.
//------------------------------------------------------------------------------

`timescale 1ns / 100ps

module testbench_top;

  //----------------------------------------------------------------------------
  // Clock and Reset Generation
  //----------------------------------------------------------------------------

  // DUV clock period
  parameter clock_period_c = 25.0;
  parameter reset_duration_c = 42;

  logic clk = 1;
  logic rst_n = 0;

  always #(clock_period_c / 2) clk <= ~clk;
  initial #reset_duration_c rst_n <= 1;

  //----------------------------------------------------------------------------
  // Stimulus
  //----------------------------------------------------------------------------

  // DUV
  logic rd_en;
  logic wr_en;
  logic done;

  logic [19:0] mem_addr;
  logic mem_rd_en;
  logic mem_wr_en;
  logic [15:0] mem_data_in;
  logic [15:0] mem_data_out;
  logic mem_data_en;
  logic mem_busy;
  logic mem_done;

  initial begin
    rd_en = 0;
    wr_en = 0;
    #200;

    @(posedge clk);
    wr_en = 1;
    @(posedge clk);
    wr_en = 0;

    @(posedge done);
    #200;

    @(posedge clk);
    rd_en = 1;
    @(posedge clk);
    rd_en = 0;

    @(posedge done);
    #200;

    $finish;
  end

  //----------------------------------------------------------------------------
  // Design under Verification
  //----------------------------------------------------------------------------

  mem_data_triplicator #(
    .addr_width_g(20),
    .data_width_g(16),
    .addr_offset_g(3))
  duv (
    .clk_i(clk),
    .rst_asy_n_i(rst_n),
    .rst_syn_i(1'b0),
    .addr_i(19'b00000000000000000000),
    .rd_en_i(rd_en),
    .wr_en_i(wr_en),
    .data_i(16'hAA33),
    .data_o(),
    .data_en_o(),
    .busy_o(),
    .done_o(done),
    .voted_o(),
    .mem_addr_o(mem_addr),
    .mem_rd_en_o(mem_rd_en),
    .mem_wr_en_o(mem_wr_en),
    .mem_data_o(mem_data_in),
    .mem_data_i(mem_data_out),
    .mem_data_en_i(mem_data_en),
    .mem_busy_i(mem_busy),
    .mem_done_i(mem_done));

  sram_interface #(
    .addr_width_g(20),
    .data_width_g(16),
    .num_delay_g(3))
  sram (
    .clk_i(clk),
    .rst_asy_n_i(rst_n),
    .rst_syn_i(1'b0),
    .addr_i(mem_addr),
    .rd_en_i(mem_rd_en),
    .wr_en_i(mem_wr_en),
    .data_i(mem_data_in),
    .data_o(mem_data_out),
    .data_en_o(mem_data_en),
    .busy_o(mem_busy),
    .done_o(mem_done),
    .sram_addr_o(),
    .sram_data_i(16'hCC55),
    .sram_data_o(),
    .sram_cs1_n_o(),
    .sram_cs2_o(),
    .sram_we_n_o(),
    .sram_oe_n_o(),
    .sram_le_n_o(),
    .sram_ue_n_o(),
    .sram_byte_n_o());

endmodule
