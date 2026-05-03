@echo off
cd /d "%~dp0\.."
echo Compiling...
vsim -c -do scripts/compile.do
if %ERRORLEVEL% NEQ 0 (echo Compile failed. & exit /b 1)

echo Running all UVM tests...

for %%T in (basic_rw_test fifo_full_test fifo_empty_test reset_test rand_test full_write_full_read_test continuous_rw_test cdc_stress_test burst_pattern_test alternating_pattern_test boundary_condition_test interrupt_signals_test stress_load_test protocol_edge_case_test coverage_test) do (
    echo Running %%T...
    echo run -all > scripts\_tmp_run.do
    echo coverage save uvm_test_logs/%%T.ucdb >> scripts\_tmp_run.do
    echo quit -f >> scripts\_tmp_run.do
    vsim -c -coverage -l uvm_test_logs\%%T.log work.tb +UVM_TESTNAME=%%T -do scripts\_tmp_run.do
)

del scripts\_tmp_run.do 2>nul

echo.
echo All UVM tests finished. Logs in uvm_test_logs\*.log, UCDBs in uvm_test_logs\*.ucdb
echo.
echo Generating HTML reports from logs...
python scripts/generate_html_report.py
echo.
echo Generating functional coverage report...
python scripts/generate_coverage_report.py
echo.
echo Done! Open html_reports/index.html or html_reports/functional_coverage.html to view results
