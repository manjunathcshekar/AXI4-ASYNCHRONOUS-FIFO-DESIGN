# Compile DUT and UVM testbench once. Exits so a batch can run multiple vsim processes.
# Run from project root (AXI4-ASYNCHRONOUS-FIFO-DESIGN)
vlib work
vmap work work
vlog -sv +acc +incdir+uvm rtl/axi4_lite_fifo_async.v uvm/interface.sv uvm/axi4_uvm_pkg.sv tb/testbench.sv
if {![file isdirectory uvm_test_logs]} {
  file mkdir uvm_test_logs
}
quit -f
