//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Collect data from the ADS1281 filter.
//------------------------------------------------------------------------------

`ifndef ADS1281_FILTER_MONITOR
`define ADS1281_FILTER_MONITOR

`include "ads1281_filter_if.sv"

class ads1281_filter_monitor extends uvm_monitor;

  virtual ads1281_filter_if.monitor vif;
  uvm_analysis_port#(logic [23:0]) analysis_port;

  protected logic [23:0] data;

  `uvm_component_utils(ads1281_filter_monitor)

  // Coverage
  covergroup cov;
    option.per_instance = 1;

    // Filter output data
    data: coverpoint data;
  endgroup

  function new(string name = "ads1281_filter_monitor", uvm_component parent = null);
    super.new(name, parent);

    cov = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual ads1281_filter_if.monitor)::get(this, "", "vif", vif))
      `uvm_fatal("NOIF", {"Interface must be set for ", get_full_name(), ".vif"});

    analysis_port = new("analysis_port", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      collect();
    join
  endtask

  virtual protected task collect();
    longint nr = 1;

    @(posedge vif.rst_n_i);

    forever begin
      // Wait for new data
      @(posedge vif.cb.en_o);
      // Save data
      data = vif.cb.data_o;
      // Save data to coverage database
      cov.sample();
      `uvm_info("RECV", $sformatf("Received (#%0d) %0d", nr, data), UVM_MEDIUM);
      nr = nr + 1;
      // Send data item to all subscribers
      analysis_port.write(data);
    end
  endtask

endclass

`endif
