# Run all UVM tests and write .log files to uvm_test_logs/
# No manual copying or renaming required; Python HTML generator reads these directly.

vlib work
vmap work work

# Compile once
vlog -sv +acc axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv

# Ensure log directory exists (Tcl)
if {![file isdirectory uvm_test_logs]} {
  file mkdir uvm_test_logs
}

# Run each test in one session; -l directs transcript to uvm_test_logs/<test>.log
# (Do not use -do "run -all; quit -f" per test — quit exits the whole process and only one test would run.)
vsim -l uvm_test_logs/basic_rw_test.log work.tb +UVM_TESTNAME=basic_rw_test
run -all

vsim -l uvm_test_logs/fifo_full_test.log work.tb +UVM_TESTNAME=fifo_full_test
run -all

vsim -l uvm_test_logs/fifo_empty_test.log work.tb +UVM_TESTNAME=fifo_empty_test
run -all

vsim -l uvm_test_logs/reset_test.log work.tb +UVM_TESTNAME=reset_test
run -all

vsim -l uvm_test_logs/rand_test.log work.tb +UVM_TESTNAME=rand_test
run -all

echo "All UVM tests finished. Logs in uvm_test_logs/*.log"
echo "Run: python generate_html_report.py"
quit -f
