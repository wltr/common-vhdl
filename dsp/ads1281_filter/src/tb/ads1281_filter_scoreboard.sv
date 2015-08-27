//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Check monitor output.
//------------------------------------------------------------------------------

`ifndef ADS1281_FILTER_SCOREBOARD
`define ADS1281_FILTER_SCOREBOARD

class ads1281_filter_scoreboard extends uvm_scoreboard;

  protected logic [23:0] item;
  uvm_analysis_imp#(logic [23:0], ads1281_filter_scoreboard) analysis_export;
  int output_file_id = 0;
  time sim_time = 0;
  time max_diff = 0;
  bit first = 1;
  int num = 0;

  // Expected time between output samples
  time expected_ns = 1000000;

  `uvm_component_utils(ads1281_filter_scoreboard)

  function new(string name = "ads1281_filter_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);

    // Open file
    output_file_id = $fopen("../res/testbench_output.csv", "r");
    if(output_file_id == 0) begin
      `uvm_fatal("FERR", "Cannot open file.");
    end
  endfunction

  virtual function void write(logic [23:0] t);
    int diff = 0;

    item = t;

    // Check values
    if(!$feof(output_file_id)) begin
      longint file_data = 0;
      int data = 0;
      int item_data = int'({{8{item[23]}}, item});

      // Read data from file
      $fscanf(output_file_id, "%d", file_data);
      data = int'({{8{file_data[34]}}, file_data[34:11]});

      if(item_data != data) begin
        `uvm_error("NEQ", $sformatf("Collected %0d != %0d from file.", item_data, data));
      end
      else begin
        `uvm_info("EQ", $sformatf("Collected %0d == %0d from file.", item_data, data), UVM_LOW);
      end
    end

    // Check timing
    diff = $time - sim_time - expected_ns;
    if(first == 0 && diff != 0) begin
      `uvm_warning("DIFF", $sformatf("Time difference: %0d ns", diff));
    end
    sim_time = $time;
    if(diff < 0) begin
      diff = diff * (-1);
    end
    if(first == 0 && diff > max_diff) begin
      // Save new max. value
      max_diff = diff;
    end
    if(first == 1 && item != 0) begin
      first = 0;
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    // Close file
    $fclose(output_file_id);
    // Report max. time difference
    `uvm_info("MAX", $sformatf("Max. time difference: %0d ns", max_diff), UVM_LOW);
  endfunction

endclass

`endif
