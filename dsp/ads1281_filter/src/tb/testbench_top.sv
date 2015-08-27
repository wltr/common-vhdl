//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Generate clock and reset, create UVM verification environment and connect
// everything to design under verification.
//------------------------------------------------------------------------------

`timescale 1ns / 100ps

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "ads1281_filter_if.sv"
`include "ads1281_filter_test.sv"

module testbench_top;

  //----------------------------------------------------------------------------
  // Clock and Reset Generation
  //----------------------------------------------------------------------------

  // DUV clock period
  parameter clock_period_c = 25.0;
  // DUV reset duration
  parameter reset_duration_c = 42;

  logic clk = 1;
  logic rst_n = 0;

  always #(clock_period_c / 2) clk <= ~clk;
  initial #reset_duration_c rst_n <= 1;

  //----------------------------------------------------------------------------
  // Instances
  //----------------------------------------------------------------------------

  // Number of ADS1281 filter channels
  parameter ads1281_filter_num_channels_c = 1;

  // DUV interface
  ads1281_filter_if duv_if [ads1281_filter_num_channels_c] (clk, rst_n);

  logic [ads1281_filter_num_channels_c - 1:0] duv_m0;
  logic [ads1281_filter_num_channels_c - 1:0] duv_m1;
  logic [23:0] duv_data [ads1281_filter_num_channels_c - 1:0];
  logic [ads1281_filter_num_channels_c - 1:0] duv_en;

  logic strb_ms = 0;

  genvar i;
  generate
    for(i = 0; i < ads1281_filter_num_channels_c; i++) begin
      assign duv_m0[i] = duv_if[i].m0_i;
      assign duv_m1[i] = duv_if[i].m1_i;

      assign duv_if[i].data_o = duv_data[i];
      assign duv_if[i].en_o = duv_en[i];
    end
  endgenerate

  // DUV
  ads1281_filter duv(
    .clk_i(clk),
    .rst_asy_n_i(rst_n),
    .rst_syn_i(1'b0),
    .strb_ms_i(strb_ms),
    .adc_m0_i(duv_m0),
    .adc_m1_i(duv_m1),
    .result_o(duv_data),
    .result_en_o(duv_en));

  // Testbench
  ads1281_filter_test tb;

  //----------------------------------------------------------------------------
  // Verification
  //----------------------------------------------------------------------------

  initial begin
    #4242;
    forever begin
      @(posedge clk);
      strb_ms = 1;
      @(posedge clk);
      strb_ms = 0;
      #(1000000 - 25);
    end
  end

  genvar j;
  generate
    for(j = 0; j < ads1281_filter_num_channels_c; j++) begin
      initial begin
        string index;
        $sformat(index, "%0d", j);
        // Save DUV interfaces to config database
        uvm_config_db#(virtual ads1281_filter_if)::set(null, "", {"duv_vif[", index, "]"}, duv_if[j]);
      end
    end
  endgenerate

  initial begin
    // Save number of DUV interfaces to config database
    uvm_config_db#(int)::set(null, "", "ads1281_filter_num_channels", ads1281_filter_num_channels_c);

    // Create testbench
    tb = ads1281_filter_test::type_id::create("ads1281_filter_test", null);

    // Run test
    run_test();
  end

endmodule
