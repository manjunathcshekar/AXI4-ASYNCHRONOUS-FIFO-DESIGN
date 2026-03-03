@echo off
cd /d "%~dp0\.."
echo Compiling...
vsim -c -do scripts/compile.do
if %ERRORLEVEL% NEQ 0 (echo Compile failed. & exit /b 1)
echo Running all UVM tests (each writes .log + .ucdb into uvm_test_logs/)...
vsim -c -coverage -l uvm_test_logs\basic_rw_test.log work.tb +UVM_TESTNAME=basic_rw_test -do "run -all; coverage save -onexit uvm_test_logs/basic_rw_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\fifo_full_test.log work.tb +UVM_TESTNAME=fifo_full_test -do "run -all; coverage save -onexit uvm_test_logs/fifo_full_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\fifo_empty_test.log work.tb +UVM_TESTNAME=fifo_empty_test -do "run -all; coverage save -onexit uvm_test_logs/fifo_empty_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\reset_test.log work.tb +UVM_TESTNAME=reset_test -do "run -all; coverage save -onexit uvm_test_logs/reset_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\rand_test.log work.tb +UVM_TESTNAME=rand_test -do "run -all; coverage save -onexit uvm_test_logs/rand_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\full_write_full_read_test.log work.tb +UVM_TESTNAME=full_write_full_read_test -do "run -all; coverage save -onexit uvm_test_logs/full_write_full_read_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\continuous_rw_test.log work.tb +UVM_TESTNAME=continuous_rw_test -do "run -all; coverage save -onexit uvm_test_logs/continuous_rw_test.ucdb; quit -f"
echo All UVM tests finished. Logs in uvm_test_logs\*.log and coverage databases in uvm_test_logs\*.ucdb
echo Run: python scripts/generate_html_report.py  OR  scripts\generate_report.bat  (logs)
echo Run: scripts\generate_coverage_report.bat  (coverage HTML)
