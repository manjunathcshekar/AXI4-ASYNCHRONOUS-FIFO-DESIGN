# Compile DUT and UVM testbench once. Exits so a batch can run multiple vsim processes.
vlib work
vmap work work
vlog -sv +acc axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv
if {![file isdirectory uvm_test_logs]} {
  file mkdir uvm_test_logs
}
quit -f
