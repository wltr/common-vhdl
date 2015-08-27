//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
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
  logic frame;
  logic bit_en;
  logic serial_data;
  logic [31:0] rx_data;
  logic rx_en;
  logic rx_error;
  logic [31:0] tx_data;
  logic tx_en;
  logic tx_busy;
  logic tx_done;

  initial begin
    tx_data = 0;
    tx_en = 0;
    #200;
    @(posedge clk);
    tx_data = 'hAACC5533;
    tx_en = 1;
    @(posedge clk);
    //tx_data = 0;
    tx_en = 0;
    @(negedge tx_busy);
    #200;
    @(posedge clk);
    tx_data = 'h3355CCAA;
    tx_en = 1;
    @(posedge clk);
    //tx_data = 0;
    tx_en = 0;
    @(posedge tx_done);
    #200;
    @(posedge clk);
    tx_data = 'hFFFFFFFF;
    tx_en = 1;
    @(posedge clk);
    //tx_data = 0;
    tx_en = 0;
    @(negedge tx_busy);
    #200;
    @(posedge clk);
    tx_data = 'h00000000;
    tx_en = 1;
    @(posedge clk);
    //tx_data = 0;
    tx_en = 0;
    @(posedge tx_done);
    #200;
    $finish;
  end

  //----------------------------------------------------------------------------
  // Monitoring
  //----------------------------------------------------------------------------

  always @(posedge clk) begin
    if(rx_en) begin
      $display("RX: %x", rx_data);
    end
  end

  //----------------------------------------------------------------------------
  // Design under Verification
  //----------------------------------------------------------------------------

  serial_3wire_rx rx_duv (
    .clk_i(clk),
    .rst_asy_n_i(rst_n),
    .rst_syn_i(1'b0),
    .rx_frame_i(frame),
    .rx_bit_en_i(bit_en),
    .rx_i(serial_data),
    .data_o(rx_data),
    .data_en_o(rx_en),
    .error_o(rx_error));

  serial_3wire_tx tx_duv (
    .clk_i(clk),
    .rst_asy_n_i(rst_n),
    .rst_syn_i(1'b0),
    .data_i(tx_data),
    .data_en_i(tx_en),
    .busy_o(tx_busy),
    .done_o(tx_done),
    .tx_frame_o(frame),
    .tx_bit_en_o(bit_en),
    .tx_o(serial_data));

endmodule
