# Run all UVM tests and write .log files to uvm_test_logs/
# No manual copying or renaming required; Python HTML generator reads these directly.
# Run from project root (AXI4-ASYNCHRONOUS-FIFO-DESIGN)

vlib work
vmap work work

# Compile once
vlog -sv +acc +incdir+uvm rtl/axi4_lite_fifo_async.v uvm/interface.sv uvm/axi4_uvm_pkg.sv tb/testbench.sv

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

vsim -l uvm_test_logs/full_write_full_read_test.log work.tb +UVM_TESTNAME=full_write_full_read_test
run -all

vsim -l uvm_test_logs/continuous_rw_test.log work.tb +UVM_TESTNAME=continuous_rw_test
run -all

echo "Running NEW coverage-enhancing tests..."

vsim -l uvm_test_logs/cdc_stress_test.log work.tb +UVM_TESTNAME=cdc_stress_test
run -all

vsim -l uvm_test_logs/burst_pattern_test.log work.tb +UVM_TESTNAME=burst_pattern_test
run -all

vsim -l uvm_test_logs/alternating_pattern_test.log work.tb +UVM_TESTNAME=alternating_pattern_test
run -all

vsim -l uvm_test_logs/boundary_condition_test.log work.tb +UVM_TESTNAME=boundary_condition_test
run -all

echo "Running FINAL coverage-boosting tests..."

vsim -l uvm_test_logs/interrupt_signals_test.log work.tb +UVM_TESTNAME=interrupt_signals_test
run -all

vsim -l uvm_test_logs/stress_load_test.log work.tb +UVM_TESTNAME=stress_load_test
run -all

vsim -l uvm_test_logs/protocol_edge_case_test.log work.tb +UVM_TESTNAME=protocol_edge_case_test
run -all

echo "Running COMPREHENSIVE coverage test..."

vsim -l uvm_test_logs/coverage_test.log work.tb +UVM_TESTNAME=coverage_test
run -all

echo "All 15 UVM tests finished. Logs in uvm_test_logs/*.log"
echo "Run: python scripts/generate_html_report.py  OR  scripts\\generate_report.bat"
quit -f
