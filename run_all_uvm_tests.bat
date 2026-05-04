@echo off
:: ============================================================
:: AXI4-Lite Async FIFO -- One-command full verification flow
::
:: Runs all 15 UVM tests, merges UCDBs, generates vcover report,
:: and produces both HTML reports. Run this from the project root.
::
:: Output:
::   html_reports\index.html               -- test dashboard
::   html_reports\functional_coverage.html -- functional coverage
::   uvm_test_logs\coverage_test.ucdb      -- merged UCDB
::   uvm_test_logs\coverage_test_report2.txt
:: ============================================================
cd /d "%~dp0"
call scripts\run_all_uvm_tests.bat
