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

:: ── Pipeline JSON helper (writes current state so pipeline.html can read it) ─
:: Usage: call :write_pipeline_json
:: Reads step vars set before calling.
goto :skip_fn

:write_pipeline_json
powershell -NoProfile -Command ^
  "$s=@{flowStart='%FLOW_START%';currentStep=%CURRENT_STEP%;steps=@(%STEP_JSON%)}; $s|ConvertTo-Json -Depth 5|Set-Content 'uvm_test_logs\pipeline_status.json' -Encoding UTF8"
goto :eof

:skip_fn

set FLOW_START=%TS_START%
set CURRENT_STEP=0
set STEP_JSON=

:: ── Step 1: Compile ──────────────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 1/6 -- Compiling RTL + UVM testbench (with -cover bcefst)...
echo COMPILE_START=%TS%>> uvm_test_logs\run_timestamps.txt
set CURRENT_STEP=1
set STEP_JSON=@{id=1;name='Compile RTL + UVM';status='running';start='%TS%';end=''}
call :write_pipeline_json

vsim -c -do scripts/compile.do
if %ERRORLEVEL% NEQ 0 (
    for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
    set STEP_JSON=@{id=1;name='Compile RTL + UVM';status='failed';start='%TS%';end='%TS%'}
    call :write_pipeline_json
    echo [ERROR] Compilation failed. Aborting.
    exit /b 1
)
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS_1_END=%%T
echo COMPILE_END=%TS_1_END%>> uvm_test_logs\run_timestamps.txt
set STEP_JSON=@{id=1;name='Compile RTL + UVM';status='done';start='%TS%';end='%TS_1_END%'}
call :write_pipeline_json
echo [%TS_1_END%] Compilation done.
echo.

:: ── Step 2: Run all 15 UVM tests ─────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 2/6 -- Running all 15 UVM tests...
echo         Each test saves: uvm_test_logs\^<test^>.log + uvm_test_logs\^<test^>.ucdb
echo.
echo TESTS_START=%TS%>> uvm_test_logs\run_timestamps.txt
set CURRENT_STEP=2
set STEP_JSON=@{id=1;name='Compile RTL + UVM';status='done';start='';end='%TS_1_END%'},@{id=2;name='Run 15 UVM Tests';status='running';start='%TS%';end=''}
call :write_pipeline_json

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
    :: Update JSON with test progress
    powershell -NoProfile -Command ^
      "$s=@{flowStart='%FLOW_START%';currentStep=2;testProgress=!TEST_COUNT!;testName='%%X';steps=@(@{id=1;name='Compile RTL + UVM';status='done';start='';end='%TS_1_END%'},@{id=2;name='Run 15 UVM Tests';status='running';start='';end='';progress=!TEST_COUNT!;total=15;currentTest='%%X'})}; $s|ConvertTo-Json -Depth 5|Set-Content 'uvm_test_logs\pipeline_status.json' -Encoding UTF8"
    (
        echo run -all
        echo coverage save uvm_test_logs/%%X.ucdb
        echo quit -f
    ) > scripts\_tmp_run.do
    vsim -c -coverage -l uvm_test_logs\%%X.log work.tb +UVM_TESTNAME=%%X -do scripts\_tmp_run.do
    if errorlevel 1 (
        echo   [WARNING] %%X returned non-zero exit code -- check uvm_test_logs\%%X.log
    ) else (
        echo   [OK] %%X
    )
)
del scripts\_tmp_run.do 2>nul

for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS_2_END=%%T
echo TESTS_END=%TS_2_END%>> uvm_test_logs\run_timestamps.txt
echo.
echo [%TS_2_END%] All 15 tests finished.
echo.

:: ── Step 3: Merge all UCDBs ───────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 3/6 -- Merging all 15 UCDBs into uvm_test_logs\coverage_test.ucdb...
echo UCDB_MERGE_START=%TS%>> uvm_test_logs\run_timestamps.txt
powershell -NoProfile -Command ^
  "$s=@{flowStart='%FLOW_START%';currentStep=3;steps=@(@{id=1;name='Compile RTL + UVM';status='done';start='';end='%TS_1_END%'},@{id=2;name='Run 15 UVM Tests';status='done';start='';end='%TS_2_END%';progress=15;total=15},@{id=3;name='Merge UCDBs';status='running';start='%TS%';end=''})}; $s|ConvertTo-Json -Depth 5|Set-Content 'uvm_test_logs\pipeline_status.json' -Encoding UTF8"

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
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS_3_END=%%T
echo UCDB_MERGE_END=%TS_3_END%>> uvm_test_logs\run_timestamps.txt
echo [%TS_3_END%] Merge done.
echo.

:: ── Step 4: vcover report ─────────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 4/6 -- Generating vcover text report...
echo VCOVER_REPORT_START=%TS%>> uvm_test_logs\run_timestamps.txt
powershell -NoProfile -Command ^
  "$s=@{flowStart='%FLOW_START%';currentStep=4;steps=@(@{id=1;name='Compile RTL + UVM';status='done';end='%TS_1_END%'},@{id=2;name='Run 15 UVM Tests';status='done';end='%TS_2_END%';progress=15;total=15},@{id=3;name='Merge UCDBs';status='done';end='%TS_3_END%'},@{id=4;name='vcover Report';status='running';start='%TS%';end=''})}; $s|ConvertTo-Json -Depth 5|Set-Content 'uvm_test_logs\pipeline_status.json' -Encoding UTF8"

vcover report -details -output uvm_test_logs\coverage_test_report2.txt uvm_test_logs\coverage_test.ucdb
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] vcover report failed. Aborting.
    exit /b 1
)
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS_4_END=%%T
echo VCOVER_REPORT_END=%TS_4_END%>> uvm_test_logs\run_timestamps.txt
echo [%TS_4_END%] vcover report done.
echo.

:: ── Step 5: HTML test reports ─────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 5/6 -- Generating HTML test reports...
echo HTML_REPORT_START=%TS%>> uvm_test_logs\run_timestamps.txt
powershell -NoProfile -Command ^
  "$s=@{flowStart='%FLOW_START%';currentStep=5;steps=@(@{id=1;name='Compile RTL + UVM';status='done';end='%TS_1_END%'},@{id=2;name='Run 15 UVM Tests';status='done';end='%TS_2_END%';progress=15;total=15},@{id=3;name='Merge UCDBs';status='done';end='%TS_3_END%'},@{id=4;name='vcover Report';status='done';end='%TS_4_END%'},@{id=5;name='HTML Test Reports';status='running';start='%TS%';end=''})}; $s|ConvertTo-Json -Depth 5|Set-Content 'uvm_test_logs\pipeline_status.json' -Encoding UTF8"

python scripts/generate_html_report.py
if %ERRORLEVEL% NEQ 0 (echo [ERROR] generate_html_report.py failed. & exit /b 1)
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS_5_END=%%T
echo HTML_REPORT_END=%TS_5_END%>> uvm_test_logs\run_timestamps.txt
echo [%TS_5_END%] HTML test reports done.
echo.

:: ── Step 6: Functional coverage HTML ─────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS=%%T
echo [%TS%] STEP 6/6 -- Generating functional coverage HTML report...
echo COV_HTML_START=%TS%>> uvm_test_logs\run_timestamps.txt
powershell -NoProfile -Command ^
  "$s=@{flowStart='%FLOW_START%';currentStep=6;steps=@(@{id=1;name='Compile RTL + UVM';status='done';end='%TS_1_END%'},@{id=2;name='Run 15 UVM Tests';status='done';end='%TS_2_END%';progress=15;total=15},@{id=3;name='Merge UCDBs';status='done';end='%TS_3_END%'},@{id=4;name='vcover Report';status='done';end='%TS_4_END%'},@{id=5;name='HTML Test Reports';status='done';end='%TS_5_END%'},@{id=6;name='Coverage HTML';status='running';start='%TS%';end=''})}; $s|ConvertTo-Json -Depth 5|Set-Content 'uvm_test_logs\pipeline_status.json' -Encoding UTF8"

python scripts/generate_coverage_report.py
if %ERRORLEVEL% NEQ 0 (echo [ERROR] generate_coverage_report.py failed. & exit /b 1)
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS_6_END=%%T
echo COV_HTML_END=%TS_6_END%>> uvm_test_logs\run_timestamps.txt
echo [%TS_6_END%] Functional coverage HTML done.
echo.

:: ── Final JSON: all done ──────────────────────────────────────────────────────
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd HH:mm:ss\""') do set TS_END=%%T
echo FLOW_END=%TS_END%>> uvm_test_logs\run_timestamps.txt
powershell -NoProfile -Command ^
  "$s=@{flowStart='%FLOW_START%';flowEnd='%TS_END%';currentStep=7;steps=@(@{id=1;name='Compile RTL + UVM';status='done';end='%TS_1_END%'},@{id=2;name='Run 15 UVM Tests';status='done';end='%TS_2_END%';progress=15;total=15},@{id=3;name='Merge UCDBs';status='done';end='%TS_3_END%'},@{id=4;name='vcover Report';status='done';end='%TS_4_END%'},@{id=5;name='HTML Test Reports';status='done';end='%TS_5_END%'},@{id=6;name='Coverage HTML';status='done';end='%TS_6_END%'})}; $s|ConvertTo-Json -Depth 5|Set-Content 'uvm_test_logs\pipeline_status.json' -Encoding UTF8"

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
echo    uvm_test_logs\pipeline_status.json    -- Pipeline state (read by pipeline.html)
echo.
