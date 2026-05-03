@echo off
cd /d "%~dp0"

REM Clean previous artifacts
if exist work rmdir /s /q work
del /q *.ucdb *.wlf transcript 2>nul

REM Compile with coverage instrumentation
vlib work
vmap work work
vlog -sv -cover bcefst +acc +incdir+uvm rtl/axi4_lite_fifo_async.v uvm/interface.sv uvm/axi4_uvm_pkg.sv tb/testbench.sv

if errorlevel 1 (
    echo COMPILATION FAILED
    exit /b 1
) else (
    echo COMPILATION SUCCESSFUL
    exit /b 0
)
