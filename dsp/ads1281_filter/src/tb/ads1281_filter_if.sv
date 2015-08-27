//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Provide interfaces to connect the design under verification to the testbench.
//------------------------------------------------------------------------------

`ifndef ADS1281_FILTER_IF
`define ADS1281_FILTER_IF

interface ads1281_filter_if (input logic clk_i, input logic rst_n_i);

  //----------------------------------------------------------------------------
  // Signals
  //----------------------------------------------------------------------------

  logic m0_i;
  logic m1_i;
  logic [23:0] data_o;
  logic en_o;

  //----------------------------------------------------------------------------
  // Clocking Blocks
  //----------------------------------------------------------------------------

  clocking cb @(posedge clk_i);
    input data_o;
    input en_o;
  endclocking

  //----------------------------------------------------------------------------
  // Module Ports
  //----------------------------------------------------------------------------

  // Driver interface
  modport driver(
    input rst_n_i,
    output m0_i,
    output m1_i);

  // Monitor interface
  modport monitor(
    input rst_n_i,
    clocking cb);

endinterface

`endif
