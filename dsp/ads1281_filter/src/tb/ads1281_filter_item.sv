//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Data item.
//------------------------------------------------------------------------------

`ifndef ADS1281_FILTER_ITEM
`define ADS1281_FILTER_ITEM

class ads1281_filter_item extends uvm_sequence_item;

  rand logic m0;
  rand logic m1;

  `uvm_object_utils_begin(ads1281_filter_item)
    `uvm_field_int(m0, UVM_ALL_ON)
    `uvm_field_int(m1, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "ads1281_filter_item");
    super.new(name);
  endfunction

endclass

`endif
