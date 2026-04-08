@echo off
cd "c:\Users\win10\Downloads\functional_coverage\AXI4-ASYNCHRONOUS-FIFO-DESIGN"
vsim -batch work.tb +UVM_TESTNAME=coverage_test -do "run -all; quit" -l uvm_test_logs/coverage_test.log
