//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// A verification agent for the ADS1281 filter.
//------------------------------------------------------------------------------

`ifndef ADS1281_FILTER_AGENT
`define ADS1281_FILTER_AGENT

`include "ads1281_filter_sequence.sv"
`include "ads1281_filter_driver.sv"
`include "ads1281_filter_monitor.sv"
`include "ads1281_filter_scoreboard.sv"
`include "ads1281_filter_item.sv"

class ads1281_filter_agent extends uvm_agent;

  uvm_sequencer#(ads1281_filter_item) sqr;
  ads1281_filter_sequence seq;
  ads1281_filter_driver drv;
  ads1281_filter_monitor mon;
  ads1281_filter_scoreboard scb;

  `uvm_component_utils(ads1281_filter_agent)

  function new(string name = "ads1281_filter_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create verification components
    seq = ads1281_filter_sequence::type_id::create("ads1281_filter_sequence");
    mon = ads1281_filter_monitor::type_id::create("ads1281_filter_monitor", this);
    scb = ads1281_filter_scoreboard::type_id::create("ads1281_filter_scoreboard", this);
    sqr = uvm_sequencer#(ads1281_filter_item)::type_id::create("ads1281_filter_sequencer", this);
    drv = ads1281_filter_driver::type_id::create("ads1281_filter_driver", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    // Connect driver to sequencer
    drv.seq_item_port.connect(sqr.seq_item_export);
    // Connect monitor to scoreboard
    mon.analysis_port.connect(scb.analysis_export);
  endfunction

  virtual task main_phase(uvm_phase phase);
    // Start sequence
    phase.raise_objection(this);
    seq.start(sqr);
    phase.drop_objection(this);
  endtask

endclass

`endif
