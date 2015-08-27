//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Create the testbench.
//------------------------------------------------------------------------------

`ifndef ADS1281_FILTER_TEST
`define ADS1281_FILTER_TEST

`include "ads1281_filter_env.sv"

class ads1281_filter_test extends uvm_test;

  ads1281_filter_env tb;
  uvm_table_printer printer;

  `uvm_component_utils(ads1281_filter_test)

  function new(string name = "ads1281_filter_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    printer = new();
    printer.knobs.depth = 3;

    // Create test environment
    tb = ads1281_filter_env::type_id::create("ads1281_filter_env", this);

    // Set report verbosity level
    this.set_report_verbosity_level_hier(UVM_LOW);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    // Print test topology
    `uvm_info("TOPO", $psprintf("Test topology:\n%s", this.sprint(printer)), UVM_NONE)
  endfunction

endclass

`endif
