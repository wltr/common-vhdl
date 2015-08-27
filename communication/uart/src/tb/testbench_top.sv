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
  logic serial_data;
  logic [7:0] rx_data;
  logic rx_en;
  logic rx_error;
  logic [7:0] tx_data;
  logic tx_en;
  logic tx_busy;
  logic tx_done;

  initial begin
    tx_data = 0;
    tx_en = 0;
    #200;
    @(posedge clk);
    tx_data = 'hAA;
    tx_en = 1;
    @(posedge clk);
    //tx_data = 0;
    tx_en = 0;
    @(negedge tx_busy);
    #200;
    @(posedge clk);
    tx_data = 'hCC;
    tx_en = 1;
    @(posedge clk);
    //tx_data = 0;
    tx_en = 0;
    @(posedge tx_done);
    #200;
    @(posedge clk);
    tx_data = 'h55;
    tx_en = 1;
    @(posedge clk);
    //tx_data = 0;
    tx_en = 0;
    @(negedge tx_busy);
    #200;
    @(posedge clk);
    tx_data = 'h33;
    tx_en = 1;
    @(posedge clk);
    //tx_data = 0;
    tx_en = 0;
    @(posedge tx_done);
    #20000;
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

  uart_rx #(
    .data_width_g(8),
    .parity_g(2),
    .stop_bits_g(1),
    .num_ticks_g(16))
  rx_duv (
    .clk_i(clk),
    .rst_asy_n_i(rst_n),
    .rst_syn_i(1'b0),
    .rx_i(serial_data),
    .data_o(rx_data),
    .data_en_o(rx_en),
    .error_o(rx_error));

  uart_tx #(
    .data_width_g(8),
    .parity_g(2),
    .stop_bits_g(1),
    .num_ticks_g(16))
  tx_duv (
    .clk_i(clk),
    .rst_asy_n_i(rst_n),
    .rst_syn_i(1'b0),
    .data_i(tx_data),
    .data_en_i(tx_en),
    .busy_o(tx_busy),
    .done_o(tx_done),
    .tx_o(serial_data));

endmodule
