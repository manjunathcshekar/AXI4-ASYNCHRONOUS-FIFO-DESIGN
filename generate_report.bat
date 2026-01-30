@echo off
echo Generating HTML Reports from UVM Test Logs...
python generate_html_report.py uvm_test_logs html_reports
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Reports generated successfully!
    echo Opening report in browser...
    start html_reports\index.html
) else (
    echo ❌ Error generating reports
    pause
)