//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Drive data to the ADS1281 filter.
//------------------------------------------------------------------------------

`ifndef ADS1281_FILTER_DRIVER
`define ADS1281_FILTER_DRIVER

`include "ads1281_filter_if.sv"
`include "ads1281_filter_item.sv"

// Simulate ADC clock glitches with random wait time between two input samples
// Nominal value: 1 us
class ads1281_filter_driver_wait;
  rand int ns;
  constraint valid {
    ns >= 999;
    ns <= 1001;
  }
endclass

class ads1281_filter_driver extends uvm_driver #(ads1281_filter_item);

  ads1281_filter_driver_wait wait_time;
  ads1281_filter_item item;
  virtual ads1281_filter_if.driver vif;

  `uvm_component_utils(ads1281_filter_driver)

  function new(string name = "ads1281_filter_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    wait_time = new();

    if(!uvm_config_db#(virtual ads1281_filter_if.driver)::get(this, "", "vif", vif))
      `uvm_fatal("NOIF", {"Interface must be set for ", get_full_name(), ".vif"});
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      drive();
    join
  endtask

  virtual protected task drive();
    longint nr = 1;

    vif.m0_i <= 0;
    vif.m1_i <= 0;

    @(posedge vif.rst_n_i);

    forever begin
      // Acquire new item from sequencer
      seq_item_port.get_next_item(item);

      // Write new values to bus
      vif.m0_i <= item.m0;
      vif.m1_i <= item.m1;
      `uvm_info("SENT", $sformatf("Sent (#%0d) M0=%b, M1=%b", nr, item.m0, item.m1), UVM_HIGH);
      nr = nr + 1;

      // Signal sequencer that data was written
      seq_item_port.item_done();

      // Wait a specific amount of time before sending next values
      void'(wait_time.randomize());
      #wait_time.ns;
    end
  endtask

endclass

`endif
