#!/usr/bin/tclsh

#------------------------------------------------------------------------------
# o7sim - Mentor Graphics ModelSim Simulation Script
# MIT License, Copyright (c) 2013 Johannes Walter
# <http://github.com/wltr/eda-o7sim>
#
# Version:
  set version 0.5
#------------------------------------------------------------------------------

# Source directory
set src_dir "../src"
set log_dir "o7sim_log"

# Source files in compilation order
set src {
  "../../../packages/lfsr/src/rtl/lfsr_pkg.vhd"
  "../../../generic/lfsr_strobe_generator/src/rtl/lfsr_strobe_generator.vhd"
  "../../../generic/edge_detector/src/rtl/edge_detector.vhd"
  "../../../generic/bit_clock_recovery/src/rtl/bit_clock_recovery.vhd"
  "rtl/uart_tx.vhd"
  "rtl/uart_rx.vhd"
  "tb/testbench_top.sv"
}

# Source file extensions
set vhdl_ext "*.vhd"
set verilog_ext "*.v"
set systemverilog_ext "*.sv"

# Simulation parameters
set work_lib "work"
set design "testbench_top"
set run_time "-all"
set time_unit "100ps"

# Standard delay format timing parameters
set enable_sdf_timing 0
set sdf_timing_filename "component.sdf"
set sdf_timing_instance "/testbench/duv"

# Coverage parameters
set enable_coverage 0
set save_coverage 0

# Assertion thread viewing parameters
set enable_atv 0
# {Object Recursive}
set atv_log_patterns {
  {"/*" 1}
}

# Custom UVM library parameters
set enable_custom_uvm 0
set custom_uvm_home "/path/to/uvm-1.1"
set custom_uvm_dpi "/path/to/uvm-1.1/lib/uvm_dpi64"

# Command parameters
set vhdl_param "-fsmverbose btw"
set verilog_param "-fsmverbose btw"
set systemverilog_param "-fsmverbose btw"
set vsim_param "-onfinish final"

# Program parameters
set show_gui 0
set show_wave 0
set quit_at_end 0

# Waveform parameters
# {Object Recursive}
set wave_patterns {
  {"/testbench_top/rx_duv/*" 1}
  {"/testbench_top/tx_duv/*" 1}
}
set wave_ignores {
  "/testbench/clk"
  "/testbench/rst_n"
}
set wave_radix "hex"
set wave_time_unit "ns"
set wave_expand 1

set wave_zoom_range 0
set wave_zoom_start_time "0"
set wave_zoom_end_time "100"

# Additional simulation libraries
# {Name Path}
set sim_libs {}
#   {"xilinxcorelib" "/opt/xilinxcorelib"}
#}

# Additional Verilog include paths
set verilog_inc_paths {}
#   "/path/to/include"
#}

# Additional SystemVerilog include paths
set systemverilog_inc_paths {}
#   "/path/to/include"
#}

# Script parameters
set save_compile_times 0

#------------------------------------------------------------------------------
# DO NOT EDIT BELOW THIS LINE
#------------------------------------------------------------------------------

set start_timestamp [clock format [clock seconds] -format {%d. %B %Y %H:%M:%S}]
puts "\n-------------------------------------------------------------------"
puts [format "Started o7sim v%s Simulation Script, %s" $version $start_timestamp]
puts "-------------------------------------------------------------------"

# Logging filenames
if {[file exists $log_dir] == 0} {
  file mkdir $log_dir
}
set log_timestamp [clock format [clock seconds] -format {%Y%m%d%H%M%S}]
set log_dir [format "%s/%s" $log_dir $log_timestamp]
file mkdir $log_dir
set vsim_log_filename [format "%s/o7sim_%s_vsim.log" $log_dir $log_timestamp]
set vlog_log_filename [format "%s/o7sim_%s_vlog.log" $log_dir $log_timestamp]
set vcom_log_filename [format "%s/o7sim_%s_vcom.log" $log_dir $log_timestamp]
set wlf_log_db_filename [format "%s/o7sim_%s_log.wlf" $log_dir $log_timestamp]
set coverage_db_filename [format "%s/o7sim_%s_coverage.ucdb" $log_dir $log_timestamp]
set compile_time_filename "o7sim_compile_times.log"

# Clean-up
if {$save_compile_times == 0 && [file exists $work_lib] == 1} {
  puts "Clean-up"
  eval vdel -all
}

# Map work library
puts [format "Mapping work library: %s" $work_lib]
eval vlib $work_lib
eval vmap  $work_lib $work_lib

# Map additional simulation libraries
foreach sim_lib $sim_libs {
  set sim_lib_name [lindex $sim_lib 0]
  set sim_lib_path [lindex $sim_lib 1]
  puts [format "Mapping simulation library: %s" $sim_lib_name]
  eval vmap $sim_lib_name $sim_lib_path
}

# Compile UVM library
if {$enable_custom_uvm == 1} {
  puts "Compiling UVM library"
  eval vlog +incdir+$custom_uvm_home/src -work $work_lib $custom_uvm_home/src/uvm.sv
  append vsim_param [format " -sv_lib %s" $custom_uvm_dpi]
  lappend systemverilog_inc_paths [format "%s/src" $custom_uvm_home]
}

# Set coverage parameters
if {$enable_coverage == 1} {
  puts "Coverage enabled"
  append vhdl_param " +cover"
  append verilog_param " +cover"
  append systemverilog_param " +cover"
  append vsim_param " -coverage"
}

# Set standard delay format timing parameters
if {$enable_sdf_timing == 1} {
  puts "Adding SDF timing information"
  append vsim_param [format " -sdfmax %s=%s/%s" $sdf_timing_filename $src_dir $sdf_timing_instance]
}

# Set assertion thread viewing parameters
if {$enable_atv == 1} {
  puts "Assertion thread viewing enabled"
  append vsim_param " -assertdebug"
}

# Additional Verilog include paths
set verilog_inc_param ""
foreach verilog_inc_path $verilog_inc_paths {
  append verilog_inc_param [format " +incdir+%s" $verilog_inc_path]
}

# Additional SystemVerilog include paths
set systemverilog_inc_param ""
foreach systemverilog_inc_path $systemverilog_inc_paths {
  append systemverilog_inc_param [format " +incdir+%s" $systemverilog_inc_path]
}

# Read compile times
if {[info exists last_compile_time]} { unset last_compile_time }
if {[info exists new_compile_time]} { unset new_compile_time }
if {[file isfile $compile_time_filename] == 1} {
  set fp [open $compile_time_filename r]
  while {[gets $fp line] >= 0 } {
    scan $line "%s %u" file_name compile_time
    set last_compile_time($file_name) $compile_time
  }
  close $fp
}

# Compile sources
foreach src_file $src {
  set file_name [format "%s/%s" $src_dir $src_file]
  # Check if source has changed
  if {$save_compile_times == 1 && [info exists last_compile_time($file_name)] == 1 && [file mtime $file_name] <= $last_compile_time($file_name)} {
    puts [format "Source has not changed: %s" $src_file]
    set new_compile_time($file_name) $last_compile_time($file_name)
  } else {
    if {[string match $vhdl_ext $src_file] == 1} {
      # Compile VHDL source
      puts [format "Compiling VHDL source: %s" $src_file]
      eval vcom -l $vcom_log_filename -novopt $vhdl_param -work $work_lib $file_name
    } elseif {[string match $verilog_ext $src_file] == 1} {
      # Compile Verilog source
      puts [format "Compiling Verilog source: %s" $src_file]
      eval vlog -l $vlog_log_filename -novopt $verilog_param $verilog_inc_param +incdir+$src_dir -work $work_lib $file_name
    } elseif {[string match $systemverilog_ext $src_file] == 1} {
      # Compile SystemVerilog source
      puts [format "Compiling SystemVerilog source: %s" $src_file]
      eval vlog -l $vlog_log_filename -novopt $systemverilog_param $systemverilog_inc_param +incdir+$src_dir -work $work_lib $file_name
    }
    set new_compile_time($file_name) [clock seconds]
  }
}

# Write compile times
if {$save_compile_times == 1} {
  set fp [open $compile_time_filename w]
  foreach entry [array names new_compile_time] {
    puts $fp [format "%s %u" $entry $new_compile_time($entry)]
  }
  close $fp
}

# Simulate
puts "Starting simulation"

if {$show_gui == 0} {
  eval onbreak resume
}

set vsim_lib_param ""
foreach sim_lib $sim_libs {
  append vsim_lib_param [format " -L %s" [lindex $sim_lib 0]]
}

set runtime [time [format "vsim -novopt -t %s -wlf %s -l %s %s %s %s" $time_unit $wlf_log_db_filename $vsim_log_filename $vsim_lib_param $vsim_param $design]]
regexp {\d+} $runtime ct_microsecs
set ct_secs [expr {$ct_microsecs / 1000000.0}]
puts [format "Elaboration time: %.4f sec" $ct_secs]

# Enable assertion thread view logging
if {$enable_atv == 1} {
  foreach atv_log_pattern $atv_log_patterns {
    set atv_log_param ""
    if {[lindex $atv_log_pattern 1] == 1} {
      set atv_log_param "-recursive"
    }
    eval atv log -enable $atv_log_param [lindex $atv_log_pattern 0]
  }
}

# Generate wave form
if {$show_gui == 1 && $show_wave == 1} {
  set wave_expand_param ""
  if {$wave_expand == 1} {
    append wave_expand_param "-expand"
  }
  set sig_list {}
  foreach wave_pattern $wave_patterns {
    set find_param ""
    if {[lindex $wave_pattern 1] == 1} {
      set find_param "-recursive"
    }
    set int_list [eval find signals -internal $find_param [lindex $wave_pattern 0]]
    set in_list [eval find signals -in $find_param [lindex $wave_pattern 0]]
    set out_list [eval find signals -out $find_param [lindex $wave_pattern 0]]
    set inout_list [eval find signals -inout $find_param [lindex $wave_pattern 0]]
    set blk_list [eval find blocks -nodu $find_param [lindex $wave_pattern 0]]
    foreach int_list_item $int_list {
      lappend sig_list [list $int_list_item 0]
    }
    foreach in_list_item $in_list {
      lappend sig_list [list $in_list_item 1]
    }
    foreach out_list_item $out_list {
      lappend sig_list [list $out_list_item 2]
    }
    foreach inout_list_item $inout_list {
      lappend sig_list [list $inout_list_item 3]
    }
    foreach blk_list_item $blk_list {
      if {[string match "*\(*\)*" $blk_list_item] == 0} {
        lappend sig_list [list $blk_list_item 4]
      }
    }
  }
  set sig_list [lsort -unique -dictionary -index 0 $sig_list]
  foreach sig $sig_list {
    set name [string trim [lindex $sig 0]]
    set type [lindex $sig 1]
    set ignore 0
    foreach ignore_pattern $wave_ignores {
      if {[string match [string trim $ignore_pattern] $name] == 1} {
        set ignore 1
      }
    }
    if {$ignore == 0} {
      set path [split $name "/"]
      set wave_param ""
      for {set x 1} {$x < [expr [llength $path] - 1]} {incr x} {
        append wave_param [format "%s -group %s " $wave_expand_param [lindex $path $x]]
      }
      if {$type == 0} {
        append wave_param [format "%s -group Internal" $wave_expand_param]
      } elseif {$type == 1} {
        append wave_param [format "%s -group Ports %s -group In" $wave_expand_param $wave_expand_param]
      } elseif {$type == 2} {
        append wave_param [format "%s -group Ports %s -group Out" $wave_expand_param $wave_expand_param]
      } elseif {$type == 3} {
        append wave_param [format "%s -group Ports %s -group InOut" $wave_expand_param $wave_expand_param]
      } elseif {$type == 4} {
        append wave_param [format "%s -group Assertions" $wave_expand_param]
      }
      set label [lindex $path [expr [llength $path] - 1]]
      append wave_param [format " -label %s" $label]
      if {[catch {eval add wave -radix $wave_radix $wave_param $name} errmsg]} {
        puts [format "Wave error: %s" $errmsg]
      }
    }
  }
  eval configure wave -timelineunits $wave_time_unit
} elseif {$show_gui == 0 && $show_wave == 1} {
  foreach wave_pattern $wave_patterns {
    set find_param ""
    if {[lindex $wave_pattern 1] == 1} {
      set find_param "-recursive"
    }
    eval log $find_param [lindex $wave_pattern 0]
  }
}

# Run
set runtime [time [format "run %s" $run_time]]
regexp {\d+} $runtime ct_microsecs
set ct_secs [expr {$ct_microsecs / 1000000.0}]
puts [format "Simulation time: %s %s" $now $time_unit]
puts [format "Run time: %.4f sec" $ct_secs]

# Save coverage database
if {$enable_coverage == 1 && $save_coverage == 1} {
  eval coverage save $coverage_db_filename
}

# Zoom
if {$show_gui == 1 && $show_wave == 1} {
  if {$wave_zoom_range == 0} {
    eval wave zoom full
  } else {
    eval wave zoom range $wave_zoom_start_time $wave_zoom_end_time
    eval wave cursor time -time $wave_zoom_start_time
  }
}

# Quit
if {$quit_at_end == 1} {
  eval quit -f
}
