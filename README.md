# AXI4-Lite Asynchronous FIFO — UVM Verification Suite

## Project Overview

This project implements and verifies an **AXI4-Lite Asynchronous FIFO** — a hardware buffer that safely transfers data between two independent clock domains using Clock Domain Crossing (CDC) synchronization.

### What is this?

In real SoC designs, different parts of the chip run at different clock speeds. A FIFO (First-In First-Out buffer) sitting between two clock domains needs special care — if you naively read and write pointers across clock boundaries, you get metastability and data corruption. This design solves that using **Gray-coded pointers** and **2-flop synchronizers**, which is the industry-standard CDC technique.

The AXI4-Lite interface on the write side means any AXI master (like an ARM Cortex-M processor) can push data into the FIFO using standard bus transactions. The peripheral read side uses a simple enable/valid handshake for the consumer.

### Design Specifications

| Parameter | Value |
|-----------|-------|
| Interface | AXI4-Lite slave (write side) |
| FIFO depth | 8 entries |
| Data width | 32 bits |
| Address width | 4 bits |
| Write clock | `clk_axi` (AXI domain) |
| Read clock | `clk_periph` (peripheral domain) |
| CDC method | Gray-coded pointers + 2-flop synchronizers |
| Overflow response | AXI SLVERR (write when full) |
| Underflow response | AXI SLVERR (peek when empty) |

### Address Map

| Address | Direction | Function |
|---------|-----------|----------|
| `0x0` | Write | Push 32-bit data into FIFO |
| `0x0` | Read | Status register — bit 0 = empty flag |
| `0x4` | Read | Non-destructive peek at head of FIFO |

### Verification Approach

The verification environment is built with **UVM (Universal Verification Methodology)**, the industry-standard framework for SystemVerilog testbenches. The environment includes:

- A **driver** that translates sequence items into AXI bus transactions
- A **monitor** that observes the bus and captures transactions
- A **scoreboard** that checks read data against expected values
- A **coverage collector** with 5 covergroups tracking 44 bins
- **15 test cases** covering normal operation, boundary conditions, CDC stress, error injection, and protocol edge cases
- **Functional coverage at 100%** — every defined bin hit, verified from real QuestaSim UCDB data

### Technology Stack

| Tool / Standard | Version |
|----------------|---------|
| RTL language | Verilog (IEEE 1364) |
| Testbench language | SystemVerilog (IEEE 1800) |
| Verification framework | UVM 1.1d |
| Simulator | QuestaSim 10.7c |
| Coverage format | UCDB (Unified Coverage Database) |
| Report generation | Python 3.6+ |

---

A complete design and verification project for an **AXI4-Lite Asynchronous FIFO** with Clock Domain Crossing (CDC) synchronization. The RTL is written in Verilog and verified using a **UVM 1.1d** environment in **QuestaSim**.

---

## Quick Start

One command runs everything — compiles, runs all 15 tests, merges coverage, and generates both HTML reports:

```bat
run_all_uvm_tests.bat
```

When it finishes, open these in your browser:

| File | Contents |
|------|----------|
| `html_reports/index.html` | Test dashboard — all 15 tests, pass/fail, transaction counts |
| `html_reports/functional_coverage.html` | Functional coverage — 100%, all bins, real UCDB data |
| `html_reports/pipeline.html` | Live pipeline view — open this *before* running the bat |

---

## Live Pipeline View

Open `html_reports/pipeline.html` directly in your browser, then run `run_all_uvm_tests.bat` in a terminal. The page auto-refreshes every 2 seconds and shows each step completing in real time.

It works by loading `uvm_test_logs/pipeline_status.js` as a `<script>` tag — no server needed, no browser flags, works straight from `file://`.

---

## Coverage Results

| Metric | Value |
|--------|-------|
| Overall functional coverage | **100%** |
| Covergroup types | 5 |
| Total bins covered | 44 / 44 |
| Tests passing | 15 / 15 |
| UVM errors | 0 |

### Covergroups

| Covergroup | Bins | Coverage |
|------------|------|----------|
| `cg_txn_type` — transaction kinds | 3/3 | 100% |
| `cg_axi_write` — write addr, strobe, FIFO-full, cross | 14/14 | 100% |
| `cg_axi_read` — read addr, FIFO-empty, cross | 8/8 | 100% |
| `cg_periph_read` — peripheral read FIFO flags | 4/4 | 100% |
| `cg_fifo_state` — all states × all transaction types | 15/15 | 100% |

---

## Project Structure

```
AXI4-ASYNCHRONOUS-FIFO-DESIGN/
│
├── run_all_uvm_tests.bat          ← THE ONE COMMAND TO RUN EVERYTHING
│
├── rtl/
│   └── axi4_lite_fifo_async.v    DUT: AXI4-Lite async FIFO with CDC
│
├── tb/
│   ├── testbench.sv               UVM top-level testbench
│   └── axi4_lite_fifo_async_full_coverage_tb.v  (standalone Verilog TB)
│
├── uvm/
│   ├── axi4_uvm_pkg.sv            Top-level package — includes everything
│   ├── interface.sv               Virtual interface
│   ├── components/
│   │   ├── agent.sv
│   │   ├── driver.sv
│   │   ├── env.sv
│   │   ├── monitor.sv
│   │   ├── scoreboard.sv
│   │   └── sequencer.sv
│   ├── sequences/                 20 sequence files
│   │   ├── seq_item.sv            Transaction class
│   │   ├── sequence.sv            Base sequence
│   │   ├── basic_rw_seq.sv
│   │   ├── fifo_full_seq.sv
│   │   ├── fifo_empty_seq.sv
│   │   ├── reset_seq.sv
│   │   ├── reset_check_seq.sv
│   │   ├── full_write_full_read_seq.sv
│   │   ├── continuous_rw_seq.sv
│   │   ├── cdc_stress_seq.sv
│   │   ├── cdc_wraparound_seq.sv
│   │   ├── burst_pattern_seq.sv
│   │   ├── alternating_pattern_seq.sv
│   │   ├── boundary_condition_seq.sv
│   │   ├── interrupt_signals_seq.sv
│   │   ├── interrupt_stimulus_seq.sv
│   │   ├── stress_load_seq.sv
│   │   ├── protocol_edge_case_seq.sv
│   │   ├── protocol_variation_seq.sv
│   │   └── error_injection_seq.sv
│   └── tests/                     16 test classes
│       ├── basic_rw_test.sv
│       ├── fifo_full_test.sv
│       ├── fifo_empty_test.sv
│       ├── reset_test.sv
│       ├── rand_test.sv
│       ├── full_write_full_read_test.sv
│       ├── continuous_rw_test.sv
│       ├── cdc_stress_test.sv
│       ├── burst_pattern_test.sv
│       ├── alternating_pattern_test.sv
│       ├── boundary_condition_test.sv
│       ├── interrupt_signals_test.sv
│       ├── stress_load_test.sv
│       ├── protocol_edge_case_test.sv
│       ├── coverage_test.sv        Comprehensive 11-sequence coverage test
│       └── coverage_test_simple.sv
│
├── scripts/
│   ├── run_all_uvm_tests.bat      Full flow: compile → test → merge → report
│   ├── compile.do                 QuestaSim compile script (called by bat)
│   ├── run_coverage_test.do       vsim do-file for coverage test
│   ├── generate_html_report.py    Generates index.html + per-test pages
│   └── generate_coverage_report.py  Generates functional_coverage.html
│
├── html_reports/
│   ├── index.html                 Test dashboard (generated)
│   ├── functional_coverage.html   Coverage report (generated)
│   ├── pipeline.html              Live pipeline view (static, always present)
│   └── <test_name>.html           Per-test log viewer (generated, 15 files)
│
├── uvm_test_logs/                 Generated on each run — not committed
│   ├── *.log                      Per-test simulation logs
│   ├── *.ucdb                     Per-test coverage databases
│   ├── coverage_test.ucdb         Merged UCDB (all 15 tests combined)
│   ├── coverage_test_report2.txt  vcover text report (source for HTML)
│   ├── run_timestamps.txt         Step timing from last run
│   └── pipeline_status.json       Live pipeline state (read by pipeline.html)
│
├── Docs/                          Project documentation and presentations
├── axi4.mpf                       QuestaSim project file
├── modelsim.ini                   QuestaSim configuration
└── .gitignore
```

---

## The 15 UVM Tests

| # | Test | What it verifies |
|---|------|-----------------|
| 1 | `basic_rw_test` | Single write + peripheral read |
| 2 | `fifo_full_test` | Fill FIFO to capacity, overflow handling |
| 3 | `fifo_empty_test` | Drain FIFO to empty, underflow handling |
| 4 | `reset_test` | Reset mid-transaction, clean recovery |
| 5 | `rand_test` | Random write/read pairs |
| 6 | `full_write_full_read_test` | Fill completely then drain completely |
| 7 | `continuous_rw_test` | 50 balanced write/read pairs |
| 8 | `cdc_stress_test` | Rapid transactions to stress CDC synchronizers |
| 9 | `burst_pattern_test` | Alternating address burst patterns |
| 10 | `alternating_pattern_test` | Variable-timing write-read pairs |
| 11 | `boundary_condition_test` | Edge cases: single write, back-to-back ops |
| 12 | `interrupt_signals_test` | IRQ_FULL and IRQ_EMPTY signal generation |
| 13 | `stress_load_test` | 500+ high-speed transactions |
| 14 | `protocol_edge_case_test` | AXI protocol boundary values and timing |
| 15 | `coverage_test` | 11 sequences targeting 100% functional coverage |

---

## How the Flow Works

```
run_all_uvm_tests.bat
        │
        ├─ Step 1: vsim -c -do scripts/compile.do
        │          Compiles RTL + UVM TB with -cover bcefst
        │
        ├─ Step 2: vsim (×15)
        │          Runs each test, saves <test>.log + <test>.ucdb
        │
        ├─ Step 3: vcover merge
        │          Merges all 15 UCDBs → coverage_test.ucdb
        │
        ├─ Step 4: vcover report -details
        │          Reads merged UCDB → coverage_test_report2.txt
        │
        ├─ Step 5: python scripts/generate_html_report.py
        │          Reads *.log → html_reports/index.html + per-test pages
        │
        └─ Step 6: python scripts/generate_coverage_report.py
                   Reads coverage_test_report2.txt → functional_coverage.html
```

The UCDB is always fresh — QuestaSim writes it at the end of each simulation. `coverage_test_report2.txt` is always regenerated from the latest UCDB. The HTML reports always reflect the current run.

---

## Running a Single Test

To run one test and check its log:

```bat
vsim -c -coverage -l uvm_test_logs\basic_rw_test.log work.tb +UVM_TESTNAME=basic_rw_test -do "run -all; coverage save uvm_test_logs/basic_rw_test.ucdb; quit -f"
```

Replace `basic_rw_test` with any test name from the table above.

---

## Viewing Waveforms

Run a test with waveform capture in QuestaSim GUI:

```tcl
vsim -gui work.tb +UVM_TESTNAME=basic_rw_test -wlf uvm_test_logs/basic_rw_test.wlf
add wave sim:/tb/dut/*
run -all
```

Replace `basic_rw_test` with any test name. All 15 commands are listed below.

### All 15 Tests — Waveform Commands

First compile once (if not already done):

```tcl
vlib work
vmap work work
vlog -sv -cover bcefst +acc +incdir+uvm rtl/axi4_lite_fifo_async.v uvm/interface.sv uvm/axi4_uvm_pkg.sv tb/testbench.sv
```

Then run any test in the QuestaSim transcript:

**Test 1 — Basic Read-Write**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/basic_rw_test.wlf +UVM_TESTNAME=basic_rw_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 2 — FIFO Full**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/fifo_full_test.wlf +UVM_TESTNAME=fifo_full_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 3 — FIFO Empty**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/fifo_empty_test.wlf +UVM_TESTNAME=fifo_empty_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 4 — Reset**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/reset_test.wlf +UVM_TESTNAME=reset_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 5 — Random**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/rand_test.wlf +UVM_TESTNAME=rand_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 6 — Full Write / Full Read**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/full_write_full_read_test.wlf +UVM_TESTNAME=full_write_full_read_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 7 — Continuous Read-Write**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/continuous_rw_test.wlf +UVM_TESTNAME=continuous_rw_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 8 — CDC Stress**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/cdc_stress_test.wlf +UVM_TESTNAME=cdc_stress_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 9 — Burst Pattern**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/burst_pattern_test.wlf +UVM_TESTNAME=burst_pattern_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 10 — Alternating Pattern**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/alternating_pattern_test.wlf +UVM_TESTNAME=alternating_pattern_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 11 — Boundary Condition**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/boundary_condition_test.wlf +UVM_TESTNAME=boundary_condition_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 12 — Interrupt Signals**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/interrupt_signals_test.wlf +UVM_TESTNAME=interrupt_signals_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 13 — Stress Load**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/stress_load_test.wlf +UVM_TESTNAME=stress_load_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 14 — Protocol Edge Case**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/protocol_edge_case_test.wlf +UVM_TESTNAME=protocol_edge_case_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

**Test 15 — Coverage Test**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/coverage_test.wlf +UVM_TESTNAME=coverage_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

### To reopen a saved waveform later

```tcl
vsim -gui -wlf uvm_test_logs/basic_rw_test.wlf
add wave -noupdate sim:/tb/dut/*
wave zoom full
```

### Key signals to watch

| Signal | Domain | What it shows |
|--------|--------|---------------|
| `sim:/tb/dut/fifo_wr_ptr_gray_r` | AXI | Write pointer (Gray coded) |
| `sim:/tb/dut/fifo_wr_ptr_gray_sync_periph_2` | Periph | Write pointer synchronized into periph domain |
| `sim:/tb/dut/fifo_rd_ptr_gray_r` | Periph | Read pointer (Gray coded) |
| `sim:/tb/dut/fifo_rd_ptr_gray_sync_axi_2` | AXI | Read pointer synchronized into AXI domain |
| `sim:/tb/dut/fifo_empty_periph_w` | Periph | FIFO empty flag |
| `sim:/tb/dut/fifo_full_axi_w` | AXI | FIFO full flag |
| `sim:/tb/dut/fifo_mem[*]` | AXI | FIFO memory contents |

---

## DUT Overview

The RTL (`rtl/axi4_lite_fifo_async.v`) implements:

- **AXI4-Lite slave** — full 5-channel protocol (AW/W/B/AR/R)
- **Async FIFO** — depth 8, 32-bit data, Gray-coded pointers
- **CDC synchronizers** — 2-flop synchronizers in both directions
- **Address map**:
  - `0x0` write — push data into FIFO
  - `0x0` read — status register (LSB = empty flag)
  - `0x4` read — non-destructive peek at head of FIFO
- **SLVERR** on write when full, SLVERR on peek when empty
- **Interrupt outputs** — `irq_full_o`, `irq_empty_o` (tied off, ports kept for compatibility)

---

## Requirements

| Tool | Version |
|------|---------|
| QuestaSim | 10.7c or later |
| Python | 3.6 or later |
| UVM | 1.1d (bundled with QuestaSim) |

Check your installation:

```bat
vsim -version
python --version
```

---

## License

See `LICENSE.txt`.
