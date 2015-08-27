//------------------------------------------------------------------------------
// LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
//
// Description:
// Compose test sequences.
//------------------------------------------------------------------------------

`ifndef ADS1281_FILTER_SEQUENCE
`define ADS1281_FILTER_SEQUENCE

`include "ads1281_filter_item.sv"

class ads1281_filter_sequence extends uvm_sequence #(ads1281_filter_item);

  `uvm_object_utils(ads1281_filter_sequence)

  function new(string name = "ads1281_filter_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Force both bit stream inputs to 1
    force_one();
    // Force both bit stream inputs to 0
    force_zero();
    // Alternate between 0 and 1 on both bit stream inputs
    alternate();
    // Read bit stream inputs from CSV file
    csv_input();
  endtask

  task force_zero();
    repeat(10000) begin
      // Create a new sequence item and start new item sequence
      `uvm_create(req);
      start_item(req);

      // Save input data in new item
      req.m0 = 0;
      req.m1 = 0;

      // Finish item sequence
      finish_item(req);
    end
  endtask

  task force_one();
    repeat(10000) begin
      // Create a new sequence item and start new item sequence
      `uvm_create(req);
      start_item(req);

      // Save input data in new item
      req.m0 = 1;
      req.m1 = 1;

      // Finish item sequence
      finish_item(req);
    end
  endtask

  task alternate();
    logic m0_in = 0;
    logic m1_in = 1;

    repeat(10000) begin
      // Create a new sequence item and start new item sequence
      `uvm_create(req);
      start_item(req);

      // Save input data in new item
      req.m0 = m0_in;
      req.m1 = m1_in;

      // Finish item sequence
      finish_item(req);

      // Toggle bits
      m0_in = ~m0_in;
      m1_in = ~m1_in;
    end
  endtask

  task csv_input();
    int input_file_id = 0;

    // Open file
    input_file_id = $fopen("../res/testbench_input.csv", "r");
    if(input_file_id == 0) begin
      `uvm_fatal("FERR", "Cannot open file.");
    end

    // Read values
    while(!$feof(input_file_id)) begin
      logic m0_in = 0;
      logic m1_in = 0;

      // Read data from file
      $fscanf(input_file_id, "%b,%b", m0_in, m1_in);

      // Create a new sequence item and start new item sequence
      `uvm_create(req);
      start_item(req);

      // Save input data in new item
      req.m0 = m0_in;
      req.m1 = m1_in;

      // Finish item sequence
      finish_item(req);
    end

    // Close file
    $fclose(input_file_id);
  endtask

endclass

`endif
