//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Create verification environment.
//------------------------------------------------------------------------------

`ifndef ADS1281_FILTER_ENV
`define ADS1281_FILTER_ENV

`include "ads1281_filter_if.sv"
`include "ads1281_filter_agent.sv"

class ads1281_filter_env extends uvm_env;

  int num_channels = 0;
  ads1281_filter_agent agt[$];

  `uvm_component_utils(ads1281_filter_env)

  function new(string name = "ads1281_filter_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get number of ADS1281 filter channels
    if(!uvm_config_db#(int)::get(this, "", "ads1281_filter_num_channels", num_channels))
      `uvm_fatal("NOCH", "Number of ADS1281 filter channels not specified.");


    for(int i = 0; i < num_channels; i++) begin
      string index;
      virtual ads1281_filter_if vif;

      $sformat(index, "%0d", i);

      // Create agent
      agt.push_back(ads1281_filter_agent::type_id::create({"ads1281_filter_agent[", index, "]"}, this));

      // Set virtual interfaces
      if(!uvm_config_db#(virtual ads1281_filter_if)::get(this, "", {"duv_vif[", index, "]"}, vif))
        `uvm_fatal("NOIF", {"No ADS1281 filter interface provided for channel ", index ,"."});

      uvm_config_db#(virtual ads1281_filter_if.driver)::set(this, {"ads1281_filter_agent[", index, "].ads1281_filter_driver"}, "vif", vif);
      uvm_config_db#(virtual ads1281_filter_if.monitor)::set(this, {"ads1281_filter_agent[", index, "].ads1281_filter_monitor"}, "vif", vif);
    end
  endfunction

endclass

`endif
