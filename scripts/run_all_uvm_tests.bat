@echo off
cd /d "%~dp0\.."
setlocal enabledelayedexpansion

echo ============================================================
echo  AXI4-Lite Async FIFO -- Full UVM Verification Flow
echo ============================================================
echo.

if not exist uvm_test_logs mkdir uvm_test_logs

:: ── Timestamp helper ─────────────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS_START=%%T
echo [%TS_START%] Flow started
echo.

:: Initialise the metadata file (overwrite any previous run)
echo FLOW_START=%TS_START%> uvm_test_logs\run_timestamps.txt

:: ── Step 1: Compile ──────────────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 1/6 -- Compiling RTL + UVM testbench (with -cover bcefst)...
echo COMPILE_START=%TS%>> uvm_test_logs\run_timestamps.txt
vsim -c -do scripts/compile.do
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed. Aborting.
    exit /b 1
)
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo COMPILE_END=%TS%>> uvm_test_logs\run_timestamps.txt
echo [%TS%] Compilation done.
echo.

:: ── Step 2: Run all 15 UVM tests ─────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 2/6 -- Running all 15 UVM tests...
echo         Each test saves: uvm_test_logs\^<test^>.log + uvm_test_logs\^<test^>.ucdb
echo.
echo TESTS_START=%TS%>> uvm_test_logs\run_timestamps.txt

set TEST_COUNT=0
for %%X in (
    basic_rw_test
    fifo_full_test
    fifo_empty_test
    reset_test
    rand_test
    full_write_full_read_test
    continuous_rw_test
    cdc_stress_test
    burst_pattern_test
    alternating_pattern_test
    boundary_condition_test
    interrupt_signals_test
    stress_load_test
    protocol_edge_case_test
    coverage_test
) do (
    set /a TEST_COUNT+=1
    for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
    echo   [!TS!] Running test !TEST_COUNT!/15: %%X
    (
        echo run -all
        echo coverage save uvm_test_logs/%%X.ucdb
        echo quit -f
    ) > scripts\_tmp_run.do
    vsim -c -coverage -l uvm_test_logs\%%X.log work.tb +UVM_TESTNAME=%%X -do scripts\_tmp_run.do
    if errorlevel 1 (
        echo   [WARNING] %%X returned non-zero exit code -- check uvm_test_logs\%%X.log
    ) else (
        echo   [OK] %%X -- log: uvm_test_logs\%%X.log  ucdb: uvm_test_logs\%%X.ucdb
    )
)
del scripts\_tmp_run.do 2>nul

for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo TESTS_END=%TS%>> uvm_test_logs\run_timestamps.txt
echo.
echo [%TS%] All 15 tests finished.
echo.

:: ── Step 3: Merge all UCDBs ───────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 3/6 -- Merging all 15 UCDBs into uvm_test_logs\coverage_test.ucdb...
echo UCDB_MERGE_START=%TS%>> uvm_test_logs\run_timestamps.txt

vcover merge uvm_test_logs\coverage_test.ucdb ^
    uvm_test_logs\basic_rw_test.ucdb ^
    uvm_test_logs\fifo_full_test.ucdb ^
    uvm_test_logs\fifo_empty_test.ucdb ^
    uvm_test_logs\reset_test.ucdb ^
    uvm_test_logs\rand_test.ucdb ^
    uvm_test_logs\full_write_full_read_test.ucdb ^
    uvm_test_logs\continuous_rw_test.ucdb ^
    uvm_test_logs\cdc_stress_test.ucdb ^
    uvm_test_logs\burst_pattern_test.ucdb ^
    uvm_test_logs\alternating_pattern_test.ucdb ^
    uvm_test_logs\boundary_condition_test.ucdb ^
    uvm_test_logs\interrupt_signals_test.ucdb ^
    uvm_test_logs\stress_load_test.ucdb ^
    uvm_test_logs\protocol_edge_case_test.ucdb ^
    uvm_test_logs\coverage_test.ucdb

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] UCDB merge failed. Aborting.
    exit /b 1
)
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo UCDB_MERGE_END=%TS%>> uvm_test_logs\run_timestamps.txt
echo [%TS%] Merge done -- coverage_test.ucdb is the combined database.
echo.

:: ── Step 4: vcover report ─────────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 4/6 -- Generating vcover text report...
echo         Input : uvm_test_logs\coverage_test.ucdb
echo         Output: uvm_test_logs\coverage_test_report2.txt
echo VCOVER_REPORT_START=%TS%>> uvm_test_logs\run_timestamps.txt

vcover report -details -output uvm_test_logs\coverage_test_report2.txt uvm_test_logs\coverage_test.ucdb
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] vcover report failed. Aborting.
    exit /b 1
)
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo VCOVER_REPORT_END=%TS%>> uvm_test_logs\run_timestamps.txt
echo [%TS%] vcover report done -- coverage_test_report2.txt is fresh.
echo.

:: ── Step 5: HTML test reports ─────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 5/6 -- Generating HTML test reports...
echo HTML_REPORT_START=%TS%>> uvm_test_logs\run_timestamps.txt
python scripts/generate_html_report.py
if %ERRORLEVEL% NEQ 0 (echo [ERROR] generate_html_report.py failed. & exit /b 1)
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo HTML_REPORT_END=%TS%>> uvm_test_logs\run_timestamps.txt
echo [%TS%] HTML test reports done.
echo.

:: ── Step 6: Functional coverage HTML ─────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 6/6 -- Generating functional coverage HTML report...
echo         Reads : uvm_test_logs\coverage_test_report2.txt
echo         Writes: html_reports\functional_coverage.html
echo COV_HTML_START=%TS%>> uvm_test_logs\run_timestamps.txt
python scripts/generate_coverage_report.py
if %ERRORLEVEL% NEQ 0 (echo [ERROR] generate_coverage_report.py failed. & exit /b 1)
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo COV_HTML_END=%TS%>> uvm_test_logs\run_timestamps.txt
echo [%TS%] Functional coverage HTML done.
echo.

:: ── Summary ───────────────────────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS_END=%%T
echo FLOW_END=%TS_END%>> uvm_test_logs\run_timestamps.txt

echo ============================================================
echo  COMPLETE -- All steps finished successfully
echo  Started : %TS_START%
echo  Finished: %TS_END%
echo ============================================================
echo.
echo  Output files:
echo    html_reports\index.html               -- Test dashboard (15 tests)
echo    html_reports\functional_coverage.html -- Functional coverage (from UCDB)
echo    uvm_test_logs\coverage_test.ucdb      -- Merged UCDB (all 15 tests)
echo    uvm_test_logs\coverage_test_report2.txt -- vcover text report
echo    uvm_test_logs\run_timestamps.txt      -- Timing log for this run
echo.
