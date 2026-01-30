# AXI4-Lite Slave Interface Design and Verification

This repository contains the complete design, implementation, and verification of an **AXI4-Lite Slave Interface** developed using **Verilog HDL** and verified using **QuestaSim**.  
The module follows the **ARM AMBA AXI4-Lite specification**, supporting safe and reliable read/write transactions commonly used in **SoC**, **FPGA**, and **custom IP** designs.

---

## 🚀 Project Overview

The project implements a fully functional AXI4-Lite Slave Interface supporting all five standard channels:

- **Write Address (AW)**
- **Write Data (W)**
- **Write Response (B)**
- **Read Address (AR)**
- **Read Data (R)**

A structured **Finite State Machine (FSM)** ensures proper sequencing and hazard-free operation across the states:

- `IDLE`
- `WRITE_ADDRESS`
- `WRITE_DATA`
- `WRITE_RESPONSE`
- `READ_ADDRESS`
- `READ_DATA`

All communication follows the **VALID/READY handshake protocol**, ensuring synchronized and reliable operation between AXI master and slave.

---

## 🧪 Verification Environment

Functional verification was performed using **QuestaSim**, with a custom master testbench that:

- Generates AXI-compliant read/write operations  
- Observes VALID/READY handshake accuracy  
- Verifies response timing and protocol correctness  
- Performs full-coverage testing for FIFO + AXI operations  

Waveforms were recorded and analyzed for timing and functional validation.

---

## 📦 Repository Contents

| File/Folder | Description |
|------------|-------------|
| `axi4_lite_fifo_async.v` | AXI4-Lite Slave Interface Verilog code |
| `axi4_lite_fifo_async_full_coverage_tb.v` | Full coverage testbench |
| `PPT/` | Presentation slides |
| `Report/` | Project final report |
| `Front_Page/` | Cover page design |
| `TruthTable.xlsx` | Truth tables used in validation |
| `waveforms/` *(optional)* | Dumped simulation waveforms |

---

## ▶️ How to Run the Design on QuestaSim

Use the following commands inside the **QuestaSim Transcript window**:

```tcl
vlib work
vmap work work
vlog -sv axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv
vsim -gui work.tb -voptargs=+acc -wlf fifo_waveform.wlf
add wave -position insertpoint sim:/tb/dut/*
run 1000ns
```
Commands for each test

Test 1: Basic Read-Write Test
```tcl
vlib work
vmap work work
vlog -sv axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv
vsim -gui work.tb -voptargs=+acc -wlf fifo_waveform.wlf +UVM_TESTNAME=basic_rw_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```
Test 2: FIFO Full Test
```tcl
vlib work
vmap work work
vlog -sv axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv
vsim -gui work.tb -voptargs=+acc -wlf fifo_waveform.wlf +UVM_TESTNAME=fifo_full_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```
Test 3: FIFO Empty Test
```tcl
vlib work
vmap work work
vlog -sv axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv
vsim -gui work.tb -voptargs=+acc -wlf fifo_waveform.wlf +UVM_TESTNAME=fifo_empty_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```
Note: `fifo_empty_test` is a **status/negative** test — it attempts a read while the FIFO is empty and expects the read to be **blocked** (no deadlock).
Test 4: Reset Test
```tcl
vlib work
vmap work work
vlog -sv axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv
vsim -gui work.tb -voptargs=+acc -wlf fifo_waveform.wlf +UVM_TESTNAME=reset_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```
Test 5: Original Random Test
```tcl
vlib work
vmap work work
vlog -sv axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv
vsim -gui work.tb -voptargs=+acc -wlf fifo_waveform.wlf +UVM_TESTNAME=rand_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

---

## 📊 Generating HTML Test Reports

After running the UVM tests, generate formatted HTML reports from the test logs. **No manual log copying or renaming is required** — simulation writes `.log` files into `uvm_test_logs/`, and the Python script reads them and fills the existing HTML report template.

---

### Flow of commands (what to run, in order)

| Step | Command | What it does |
|------|---------|---------------|
| **1** | `run_all_uvm_tests.bat` | Compiles once, runs all 5 UVM tests, writes one `.log` per test into `uvm_test_logs/`. |
| **2** | `python generate_html_report.py` | Reads all `.log` and `.txt` in `uvm_test_logs/`, generates HTML in `html_reports/` (index + per-test pages). |

**Where to run:** Open Command Prompt or PowerShell, go to the project folder (where `generate_html_report.py` and `run_all_uvm_tests.bat` are), then run the two commands above. Ensure `vsim` (QuestaSim) and `python` are on your PATH.

**Result:** `uvm_test_logs/` will contain all test logs; `html_reports/index.html` will show the summary and link to each test’s formatted log. The HTML template is already in place — the Python script only fills it with the logs that exist in `uvm_test_logs/`.

---

### Why not `vsim -c -do run_all_uvm_tests.do`?

If you run **`vsim -c -do run_all_uvm_tests.do`**, only **one** log file is produced (`basic_rw_test.log`). In that mode, vsim runs all five tests in a single session, and the transcript is only written to the first `-l` log file. So:

- **To get all 5 logs:** use **`run_all_uvm_tests.bat`** (it runs 5 separate vsim processes, each writing its own `.log`).
- **To run a single test** and get its log, you can use vsim directly (see “Run a single test with log” below).

---

### 1. Run simulation (produces `.log` in `uvm_test_logs/`)

**Recommended — all 5 tests, one `.log` per test:**

```batch
run_all_uvm_tests.bat
```

This compiles once (`compile.do`), then runs five separate vsim invocations so each test writes its own file:

- `uvm_test_logs/basic_rw_test.log`
- `uvm_test_logs/fifo_full_test.log`
- `uvm_test_logs/fifo_empty_test.log`
- `uvm_test_logs/reset_test.log`
- `uvm_test_logs/rand_test.log`

### 2. Generate HTML reports (consumes `.log` / `.txt` from `uvm_test_logs/`)

```batch
python generate_html_report.py
```

Or with explicit paths:

```batch
python generate_html_report.py uvm_test_logs html_reports
```

The script discovers all `.log` and `.txt` files in `uvm_test_logs/` and produces the HTML report in `html_reports/`. Whatever logs are present (one or all five) are shown in the existing template.

### Run a single test with log

To run only one test and store its log in `uvm_test_logs/`:

```tcl
vsim -c -l uvm_test_logs/basic_rw_test.log work.tb +UVM_TESTNAME=basic_rw_test -do "run -all; quit -f"
```

(Change the log filename and `+UVM_TESTNAME=...` for other tests: `fifo_full_test`, `fifo_empty_test`, `reset_test`, `rand_test`.)

### Other: single run with one transcript

- `vsim -c -do questa_run_with_logs.do` — produces `compile.log` and `sim.log` in the project root (not per-test logs in `uvm_test_logs/`).
- For per-test logs in `uvm_test_logs/`, use **`run_all_uvm_tests.bat`** as in Step 1 above.

---

## 📘 Applications

This AXI4-Lite module can be used for:

- Memory-mapped peripheral integration  
- FIFO-mapped controllers  
- Custom IP blocks  
- FPGA-based SoC subsystems  
- Future expansion into **AXI4-Full** or **AXI-Stream** designs  

---

## 📆 Weekly Progress Tracking

### **Team Meeting – 29/11/2025 (Saturday)**

#### **Points Discussed**
- Add interrupt controller  
- Verify burst transfer capability  
- Make FIFO configurable  

---

### **Objectives (To Be Completed Soon)**
- Study and develop a **UVM-based verification environment**  
- Justify **low latency** and **high throughput** through analysis and simulation  

---

### **Future Enhancements**
- Extend the design to support **multiple AXI masters**  

---

### **Next Meeting**
📅 **09/12/2025 (Tuesday)**  

---
