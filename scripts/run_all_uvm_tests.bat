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
echo Running NEW coverage-enhancing tests...
vsim -c -coverage -l uvm_test_logs\cdc_stress_test.log work.tb +UVM_TESTNAME=cdc_stress_test -do "run -all; coverage save -onexit uvm_test_logs/cdc_stress_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\burst_pattern_test.log work.tb +UVM_TESTNAME=burst_pattern_test -do "run -all; coverage save -onexit uvm_test_logs/burst_pattern_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\alternating_pattern_test.log work.tb +UVM_TESTNAME=alternating_pattern_test -do "run -all; coverage save -onexit uvm_test_logs/alternating_pattern_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\boundary_condition_test.log work.tb +UVM_TESTNAME=boundary_condition_test -do "run -all; coverage save -onexit uvm_test_logs/boundary_condition_test.ucdb; quit -f"
echo Running FINAL coverage-boosting tests...
vsim -c -coverage -l uvm_test_logs\interrupt_signals_test.log work.tb +UVM_TESTNAME=interrupt_signals_test -do "run -all; coverage save -onexit uvm_test_logs/interrupt_signals_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\stress_load_test.log work.tb +UVM_TESTNAME=stress_load_test -do "run -all; coverage save -onexit uvm_test_logs/stress_load_test.ucdb; quit -f"
vsim -c -coverage -l uvm_test_logs\protocol_edge_case_test.log work.tb +UVM_TESTNAME=protocol_edge_case_test -do "run -all; coverage save -onexit uvm_test_logs/protocol_edge_case_test.ucdb; quit -f"
echo All UVM tests finished (14 total). Logs in uvm_test_logs\*.log and coverage databases in uvm_test_logs\*.ucdb
echo Run: python scripts/generate_html_report.py  OR  scripts\generate_report.bat  (logs)
echo Run: python scripts/generate_coverage_report.py  (coverage HTML)
