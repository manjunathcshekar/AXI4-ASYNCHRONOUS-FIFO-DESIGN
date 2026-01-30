@echo off
cd /d "%~dp0\.."
echo Compiling...
vsim -c -do scripts/compile.do
if %ERRORLEVEL% NEQ 0 (echo Compile failed. & exit /b 1)
echo Running all 5 UVM tests (each writes its own .log to uvm_test_logs/)...
vsim -c -l uvm_test_logs\basic_rw_test.log work.tb +UVM_TESTNAME=basic_rw_test -do "run -all; quit -f"
vsim -c -l uvm_test_logs\fifo_full_test.log work.tb +UVM_TESTNAME=fifo_full_test -do "run -all; quit -f"
vsim -c -l uvm_test_logs\fifo_empty_test.log work.tb +UVM_TESTNAME=fifo_empty_test -do "run -all; quit -f"
vsim -c -l uvm_test_logs\reset_test.log work.tb +UVM_TESTNAME=reset_test -do "run -all; quit -f"
vsim -c -l uvm_test_logs\rand_test.log work.tb +UVM_TESTNAME=rand_test -do "run -all; quit -f"
echo All UVM tests finished. Logs in uvm_test_logs\*.log
echo Run: python scripts/generate_html_report.py  OR  scripts\generate_report.bat
