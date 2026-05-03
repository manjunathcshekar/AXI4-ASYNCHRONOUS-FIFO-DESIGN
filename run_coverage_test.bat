@echo off
cd /d "%~dp0"
if exist work rmdir /s /q work
if exist uvm_test_logs\questa.db del /q uvm_test_logs\questa.db
if exist uvm_test_logs\(null).data del /q "uvm_test_logs\(null).data"
if not exist uvm_test_logs mkdir uvm_test_logs

vlib work
vmap work work
vlog -sv -cover bcefst +acc +incdir+uvm rtl/axi4_lite_fifo_async.v uvm/interface.sv uvm/axi4_uvm_pkg.sv tb/testbench.sv
if errorlevel 1 (
    echo COMPILATION FAILED
    exit /b 1
)

vsim -batch -coverage -coverstore uvm_test_logs work.tb +UVM_TESTNAME=coverage_test -do scripts/run_coverage_test.do -l uvm_test_logs\coverage_test.log
if errorlevel 1 (
    echo SIMULATION FAILED
    exit /b 1
)

echo.
echo Merging coverstore into UCDB...
vcover merge uvm_test_logs\coverage_test.ucdb uvm_test_logs
if errorlevel 1 (
    echo MERGE FAILED
    exit /b 1
)

echo.
echo Generating report...
vcover report -details -output uvm_test_logs\coverage_test_report2.txt uvm_test_logs\coverage_test.ucdb

echo.
echo Done! Coverage report: uvm_test_logs\coverage_test_report2.txt
echo Open with: type uvm_test_logs\coverage_test_report2.txt
