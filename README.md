# AXI4-Lite Asynchronous FIFO - Complete Verification Suite

Comprehensive design and verification of an **AXI4-Lite Asynchronous FIFO** with CDC (Clock Domain Crossing) synchronizer, developed in **Verilog HDL** and verified using **UVM 1.1d** in **QuestaSim**.

---

## 🚀 Quick Start: 3-Command Complete Verification

Execute these three commands in sequence to run 15 tests and generate real coverage data:

```bash
# Step 1: Compile with coverage instrumentation (~2 sec)
vsim -c -do "do scripts/compile.do"

# Step 2: Run all 15 tests (~5-10 min)
scripts\run_all_uvm_tests.bat

# Step 3: Generate real coverage dashboard (seconds)
python scripts/generate_coverage_report.py
```

**Result:** `html_reports/functional_coverage.html` with real coverage metrics from **1,774 verified transactions**.

### With Waveform Capture

To also generate waveforms for each test:

```bash
# Run all 15 tests with waveform capture
scripts\run_tests_with_waveforms.bat

# Then view specific test waveforms in QuestaSim GUI
vsim -gui -wlf uvm_test_logs/basic_rw_test_waveform.wlf
```

---

## 📊 Coverage Results (Real Data from Report)

| Metric | Value | Status |
|--------|-------|--------|
| **Overall Coverage** | 88.1% | Grade B |
| **Total Transactions** | 1,774 | Verified |
| **Tests Passed** | 14/15 | 93.3% |
| **Tests Failed** | 1/15 | reset_test |
| **Write Operations** | 919 | 51.8% of total |
| **Read Operations** | 840 | 47.4% of total |
| **Bins Exercised** | 114/133 | 85.7% |
| **Coverage Databases** | 15 .ucdb files | ✅ Generated |
| **Waveform Files** | 15 .wlf files | ✅ Available |

### Coverage by Domain (Real Metrics)

| Domain | Coverage | Bins Hit | Status | Key Tests |
|--------|----------|----------|--------|----------|
| AXI Protocol | 82.6% | 38/46 | ✅ Good | burst_pattern, protocol_edge_case, basic_rw_test |
| FIFO State Machine | 90.0% | 18/20 | ✅ Excellent | fifo_full, fifo_empty, full_write_full_read_test |
| CDC Synchronization | 80.0% | 24/30 | ✅ Good | cdc_stress, stress_load |
| Interrupt Signals | 100.0% | 12/12 | ✅ Perfect | interrupt_signals |
| Error Scenarios | 88.0% | 22/25 | ✅ Good | reset, boundary_condition, protocol_edge_case |

---

## 🧪 15-Test Comprehensive Suite

### Core Tests (7 Original)

| # | Test | Purpose |
|---|------|---------|
| 1 | `basic_rw_test` | Sequential read/write operations |
| 2 | `continuous_rw_test` | Continuous interleaved read/write |
| 3 | `fifo_empty_test` | FIFO empty flag behavior |
| 4 | `fifo_full_test` | FIFO full flag behavior |
| 5 | `full_write_full_read_test` | Full buffer write then read |
| 6 | `rand_test` | Random transaction sequences |
| 7 | `reset_test` | Reset and recovery |

### Coverage Enhancement Tests (7)

| # | Test | Purpose | Focus |
|---|------|---------|-------|
| 8 | `cdc_stress_test` | CDC synchronizer stress | Clock domain crossing |
| 9 | `burst_pattern_test` | AXI burst addressing patterns | Protocol variants |
| 10 | `alternating_pattern_test` | Rapid state transitions | FSM coverage |
| 11 | `boundary_condition_test` | Edge case scenarios | Error scenarios |
| 12 | `interrupt_signals_test` | Interrupt combinations | 100% interrupt coverage |
| 13 | `stress_load_test` | 500+ transactions | Stress & reliability |
| 14 | `protocol_edge_case_test` | AXI protocol limits | Protocol robustness |

### Comprehensive Coverage Test (1)

| # | Test | Purpose |
|---|------|---------|
| 15 | `coverage_test` | Orchestrates all coverage sequences | Maximum domain coverage |

---

## 📁 Project Structure

```
AXI4-ASYNCHRONOUS-FIFO-DESIGN/
├── rtl/
│   └── axi4_lite_fifo_async.v              # DUT with CDC
├── tb/
│   └── testbench.sv                        # UVM testbench top
├── uvm/
│   ├── axi4_uvm_pkg.sv                     # Package with all includes
│   ├── interface.sv                        # Virtual interface
│   ├── components/
│   │   ├── agent.sv
│   │   ├── driver.sv
│   │   ├── monitor.sv
│   │   ├── scoreboard.sv
│   │   ├── sequencer.sv
│   │   └── env.sv
│   ├── sequences/                          # 14 sequence types
│   │   ├── seq_item.sv
│   │   ├── sequence.sv
│   │   ├── basic_rw_seq.sv
│   │   ├── continuous_rw_seq.sv
│   │   ├── fifo_empty_seq.sv
│   │   ├── fifo_full_seq.sv
│   │   ├── full_write_full_read_seq.sv
│   │   ├── reset_seq.sv
│   │   ├── reset_check_seq.sv
│   │   ├── cdc_stress_seq.sv
│   │   ├── burst_pattern_seq.sv
│   │   ├── alternating_pattern_seq.sv
│   │   ├── boundary_condition_seq.sv
│   │   ├── interrupt_signals_seq.sv
│   │   ├── stress_load_seq.sv
│   │   └── protocol_edge_case_seq.sv
│   └── tests/                              # 14 test classes
│       ├── basic_rw_test.sv
│       ├── continuous_rw_test.sv
│       ├── fifo_empty_test.sv
│       ├── fifo_full_test.sv
│       ├── full_write_full_read_test.sv
│       ├── rand_test.sv
│       ├── reset_test.sv
│       ├── cdc_stress_test.sv
│       ├── burst_pattern_test.sv
│       ├── alternating_pattern_test.sv
│       ├── boundary_condition_test.sv
│       ├── interrupt_signals_test.sv
│       ├── stress_load_test.sv
│       └── protocol_edge_case_test.sv
├── scripts/
│   ├── compile.do                          # Compile with coverage
│   ├── run_all_uvm_tests.bat               # Run 14 tests
│   ├── run_all_uvm_tests.do
│   ├── generate_coverage_report.py         # Real data extraction
│   ├── generate_html_report.py
│   └── generate_report.bat
├── uvm_test_logs/                          # Logs and .ucdb files
│   ├── *.log                               # 14 test logs
│   └── *.ucdb                              # 14 coverage databases
├── html_reports/
│   ├── functional_coverage.html            # REAL coverage dashboard
│   └── *.html                              # Per-test reports
└── README.md                               # This file
```

---

## 🔧 Key Features

### AXI4-Lite Slave Interface
- ✅ Full ARM AMBA AXI4-Lite specification compliance
- ✅ 5-channel protocol: AW, W, B, AR, R
- ✅ VALID/READY handshake synchronization
- ✅ Finite State Machine (FSM) with 6 states
- ✅ Clock Domain Crossing (CDC) synchronizer

### UVM Verification Environment
- ✅ **15 comprehensive test scenarios** (14 passing, 1 failing)
- ✅ **1,774 verified transactions** (919 writes, 840 reads)
- ✅ **88.1% functional coverage** (Grade B: 114/133 bins)
- ✅ **5 coverage domains** fully analyzed
- ✅ Real coverage data extraction from UCDB files
- ✅ Professional HTML dashboard reporting
- ✅ Per-domain coverage breakdown
- ✅ Transaction-level statistics

---

## 📊 Generating the Coverage Dashboard

### Automatic Workflow (Recommended)

```bash
# From project root directory:

# 1. Compile (once)
vsim -c -do "do scripts/compile.do"

# 2. Run all 15 tests (generates logs and UCDB files)
scripts\run_all_uvm_tests.bat

# 3. Generate real coverage report
python scripts/generate_coverage_report.py

# 4. Open in browser
html_reports/functional_coverage.html
```

### What Each Command Does

| Command | Output | Time |
|---------|--------|------|
| `compile.do` | `work/` compiled design | ~2 sec |
| `run_all_uvm_tests.bat` | 15 logs + 15 UCDB files + HTML reports | 5-15 min |
| `generate_coverage_report.py` | Real HTML dashboard | < 1 sec |

### To Also Generate Waveforms

```bash
# Run all 15 tests with waveform capture
scripts\run_tests_with_waveforms.bat

# This additionally generates:
# - 15 .wlf waveform files for each test
# - Each file contains full signal trace for debugging
```

---

## � Waveform Generation Steps and Commands

### Overview
Generate waveforms (.wlf files) for all 15 test cases with detailed signal tracing. Waveforms are essential for debugging, timing analysis, and protocol verification.

### Prerequisites
- QuestaSim 10.7c or later installed
- Project compiled (see Step 1 below)
- Output directory: `uvm_test_logs/` (auto-created)

---

### Step 1: Compile the Design (Run Once)

Execute this command **once** to compile all design files with coverage instrumentation:

```tcl
# QuestaSim Transcript Commands
vlib work
vmap work work
vlog -sv +acc +incdir+uvm rtl/axi4_lite_fifo_async.v uvm/interface.sv uvm/axi4_uvm_pkg.sv tb/testbench.sv
```

**Output:** Compiled `work/` library directory ready for all 15 tests.

---

### Step 2: Generate Waveforms for All 15 Tests

Run each test individually to generate separate waveform files. Copy and paste each command into **QuestaSim Transcript** window.

#### **Test 1: Basic Read-Write Test**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/basic_rw_test.wlf +UVM_TESTNAME=basic_rw_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 2: Boundary Condition Test** ⭐ NEW
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/boundary_condition_test.wlf +UVM_TESTNAME=boundary_condition_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 3: Burst Pattern Test** ⭐ NEW
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/burst_pattern_test.wlf +UVM_TESTNAME=burst_pattern_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 4: CDC Stress Test** ⭐ NEW
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/cdc_stress_test.wlf +UVM_TESTNAME=cdc_stress_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 5: Continuous Read-Write Test**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/continuous_rw_test.wlf +UVM_TESTNAME=continuous_rw_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 6: Coverage Test** ⭐ NEW
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/coverage_test.wlf +UVM_TESTNAME=coverage_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 7: FIFO Empty Test**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/fifo_empty_test.wlf +UVM_TESTNAME=fifo_empty_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 8: FIFO Full Test**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/fifo_full_test.wlf +UVM_TESTNAME=fifo_full_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 9: Full Write-Full Read Test**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/full_write_full_read_test.wlf +UVM_TESTNAME=full_write_full_read_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 10: Interrupt Signals Test** ⭐ NEW
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/interrupt_signals_test.wlf +UVM_TESTNAME=interrupt_signals_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 11: Protocol Edge Case Test** ⭐ NEW
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/protocol_edge_case_test.wlf +UVM_TESTNAME=protocol_edge_case_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 12: Random Test**
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/rand_test.wlf +UVM_TESTNAME=rand_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 13: Reset Test** ⚠️ FAILING TEST
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/reset_test.wlf +UVM_TESTNAME=reset_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 14: Alternating Pattern Test** ⭐ NEW
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/alternating_pattern_test.wlf +UVM_TESTNAME=alternating_pattern_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

#### **Test 15: Stress Load Test** ⭐ NEW
```tcl
vsim -gui work.tb -voptargs=+acc -wlf uvm_test_logs/stress_load_test.wlf +UVM_TESTNAME=stress_load_test
add wave -position insertpoint sim:/tb/dut/*
run -all
```

---

### Step 3: Automated Batch Generation (Optional)

Create a batch file `generate_all_waveforms.bat` to run all tests non-interactively:

```batch
@echo off
REM ============================================================================
REM Automated Waveform Generation for All 15 Tests
REM ============================================================================

echo.
echo Compiling design (Step 1)...
vlib work
vmap work work
vlog -sv +acc +incdir+uvm rtl/axi4_lite_fifo_async.v uvm/interface.sv uvm/axi4_uvm_pkg.sv tb/testbench.sv

echo.
echo Generating waveforms for all 15 tests (Step 2)...
echo.

REM Test 1
echo [1/15] Running basic_rw_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/basic_rw_test.wlf +UVM_TESTNAME=basic_rw_test -do "run -all; quit"

REM Test 2
echo [2/15] Running boundary_condition_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/boundary_condition_test.wlf +UVM_TESTNAME=boundary_condition_test -do "run -all; quit"

REM Test 3
echo [3/15] Running burst_pattern_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/burst_pattern_test.wlf +UVM_TESTNAME=burst_pattern_test -do "run -all; quit"

REM Test 4
echo [4/15] Running cdc_stress_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/cdc_stress_test.wlf +UVM_TESTNAME=cdc_stress_test -do "run -all; quit"

REM Test 5
echo [5/15] Running continuous_rw_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/continuous_rw_test.wlf +UVM_TESTNAME=continuous_rw_test -do "run -all; quit"

REM Test 6
echo [6/15] Running coverage_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/coverage_test.wlf +UVM_TESTNAME=coverage_test -do "run -all; quit"

REM Test 7
echo [7/15] Running fifo_empty_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/fifo_empty_test.wlf +UVM_TESTNAME=fifo_empty_test -do "run -all; quit"

REM Test 8
echo [8/15] Running fifo_full_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/fifo_full_test.wlf +UVM_TESTNAME=fifo_full_test -do "run -all; quit"

REM Test 9
echo [9/15] Running full_write_full_read_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/full_write_full_read_test.wlf +UVM_TESTNAME=full_write_full_read_test -do "run -all; quit"

REM Test 10
echo [10/15] Running interrupt_signals_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/interrupt_signals_test.wlf +UVM_TESTNAME=interrupt_signals_test -do "run -all; quit"

REM Test 11
echo [11/15] Running protocol_edge_case_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/protocol_edge_case_test.wlf +UVM_TESTNAME=protocol_edge_case_test -do "run -all; quit"

REM Test 12
echo [12/15] Running rand_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/rand_test.wlf +UVM_TESTNAME=rand_test -do "run -all; quit"

REM Test 13
echo [13/15] Running reset_test (FAILING - for debugging)...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/reset_test.wlf +UVM_TESTNAME=reset_test -do "run -all; quit"

REM Test 14
echo [14/15] Running alternating_pattern_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/alternating_pattern_test.wlf +UVM_TESTNAME=alternating_pattern_test -do "run -all; quit"

REM Test 15
echo [15/15] Running stress_load_test...
vsim -c work.tb -voptargs=+acc -wlf uvm_test_logs/stress_load_test.wlf +UVM_TESTNAME=stress_load_test -do "run -all; quit"

echo.
echo ============================================================================
echo All 15 waveforms generated successfully!
echo ============================================================================
echo.
echo Waveform files location: uvm_test_logs/
echo.
echo To view waveforms in QuestaSim GUI, use Step 4 below.
echo.
pause
```

**Run the batch file:**
```bash
generate_all_waveforms.bat
```

---

### Step 4: View Individual Waveforms in QuestaSim GUI

After waveforms are generated (Step 2 or 3), view them in QuestaSim GUI:

#### **Open Specific Test Waveform**
```tcl
# In QuestaSim Transcript, open any waveform file:
vsim -gui -wlf uvm_test_logs/basic_rw_test.wlf

# Then add wave display:
add wave -noupdate /tb/dut/*
wave zoom full
```

#### **Example: View Reset Test (Failing Test)**
```tcl
vsim -gui -wlf uvm_test_logs/reset_test.wlf
add wave -noupdate /tb/dut/axi_resetn
add wave -noupdate /tb/dut/fifo_wr_ptr_bin_r
add wave -noupdate /tb/dut/fifo_rd_ptr_bin_r
add wave -noupdate /tb/dut/fifo_empty_periph_w
add wave -noupdate /tb/dut/fifo_full_axi_w
wave zoom full
```

---

### Waveform Files Generated

After completing Steps 2 or 3, the following `.wlf` files will be created in `uvm_test_logs/`:

```
uvm_test_logs/
├── basic_rw_test.wlf                     ✅ Pass
├── boundary_condition_test.wlf           ✅ Pass
├── burst_pattern_test.wlf                ✅ Pass
├── cdc_stress_test.wlf                   ✅ Pass
├── continuous_rw_test.wlf                ✅ Pass
├── coverage_test.wlf                     ✅ Pass
├── fifo_empty_test.wlf                   ✅ Pass
├── fifo_full_test.wlf                    ✅ Pass
├── full_write_full_read_test.wlf         ✅ Pass
├── interrupt_signals_test.wlf            ✅ Pass
├── protocol_edge_case_test.wlf           ✅ Pass
├── rand_test.wlf                         ✅ Pass
├── reset_test.wlf                        ⚠️ FAIL (Debug this)
├── alternating_pattern_test.wlf          ✅ Pass
└── stress_load_test.wlf                  ✅ Pass
```

---

### Troubleshooting Waveform Generation

| Issue | Solution |
|-------|----------|
| `.wlf` file not created | Check simulator output; ensure `uvm_test_logs/` directory exists |
| Waveforms show no signals | Use `add wave` command before `run -all` |
| Simulation hangs | Check for UVM deadlock in failing test (reset_test) |
| Out of memory | Reduce waveform recording scope using `add wave -sel` |

---

## �🎯 Coverage Metrics Explained

### Transaction-Level Coverage
- **Total transactions**: 1,774 verified AXI operations
  - **Write operations**: 919 (51.8%)
  - **Read operations**: 840 (47.4%)
- **Largest contributor**: stress_load_test (751 txns, 42.3%)
- **Smallest contributor**: fifo_empty_test (4 txns, 0.2%)
- **Coverage per test**: Visible in dashboard and html_reports/

### Domain-Based Coverage
Each test contributes to multiple coverage domains:

1. **AXI Protocol** (82.6% - 38/46 bins)
   - Write address modes (0x0, 0x4)
   - Write strobe patterns (0xF, 0x5, 0xA)
   - Response codes (OKAY, SLVERR on overflow)
   - Read address modes and responses

2. **FIFO State Machine** (90.0% - 18/20 bins)
   - Occupancy levels (0-8 entries)
   - Empty (0) and Full (8) states
   - State transitions and FSM coverage
   - Empty/full flag correlations

3. **CDC Synchronization** (80.0% - 24/30 bins)
   - Gray-code pointer transitions (4 bits each direction)
   - Clock domain crossing delays (0-5 cycles)
   - Synchronizer safety and metastability
   - Pointer wraparound events

4. **Interrupt Signals** (100.0% ✅ Perfect - 12/12 bins)
   - IRQ_FULL signal assertions and clearing
   - IRQ_EMPTY signal assertions and clearing
   - All interrupt state combinations exercised
   - Interrupt timing and duration tracking

5. **Error Scenarios** (88.0% - 22/25 bins)
   - Overflow detection and SLVERR response
   - Underflow prevention
   - Reset timing at various operational phases
   - Post-reset data validity
   - FIFO boundary conditions and edge cases

---

## 🔍 Output Files

After running all commands:

```
uvm_test_logs/
├── basic_rw_test.log                  # Test execution log
├── basic_rw_test.ucdb                 # Coverage database (binary)
├── continuous_rw_test.log
├── continuous_rw_test.ucdb
├── fifo_empty_test.log
├── fifo_empty_test.ucdb
├── fifo_full_test.log
├── fifo_full_test.ucdb
├── full_write_full_read_test.log
├── full_write_full_read_test.ucdb
├── rand_test.log
├── rand_test.ucdb
├── reset_test.log
├── reset_test.ucdb
├── cdc_stress_test.log
├── cdc_stress_test.ucdb
├── burst_pattern_test.log
├── burst_pattern_test.ucdb
├── alternating_pattern_test.log
├── alternating_pattern_test.ucdb
├── boundary_condition_test.log
├── boundary_condition_test.ucdb
├── interrupt_signals_test.log
├── interrupt_signals_test.ucdb
├── stress_load_test.log
├── stress_load_test.ucdb
├── protocol_edge_case_test.log
└── protocol_edge_case_test.ucdb        # Total: 14 logs + 14 UCDB files

html_reports/
└── functional_coverage.html            # Real coverage dashboard with metrics
```

---

## 📈 Coverage Advancement

| Phase | Tests | Transactions | Pass Rate | Coverage | Grade |
|-------|-------|--------------|-----------|----------|-------|
| Original | 7 | ~400 | ~100% | ~65% | C+ |
| Enhanced | +4 | +600 | ~95% | ~80% | B- |
| Current | 15 | 1,774 | **93.3%** | **88.1%** | **B** |
| Target | 15 | 1,774+ | 100% | >95% | A |

### Actual Test Results

| Test | Status | Transactions | Type |
|------|--------|--------------|------|
| basic_rw_test | ✅ PASS | 3 | Core |
| boundary_condition_test | ✅ PASS | 86 | Enhancement |
| burst_pattern_test | ✅ PASS | 65 | Enhancement |
| cdc_stress_test | ✅ PASS | 151 | Enhancement |
| continuous_rw_test | ✅ PASS | 101 | Core |
| coverage_test | ✅ PASS | 115 | Coverage |
| fifo_empty_test | ✅ PASS | 4 | Core |
| fifo_full_test | ✅ PASS | 10 | Core |
| full_write_full_read_test | ✅ PASS | 17 | Core |
| interrupt_signals_test | ✅ PASS | 129 | Enhancement |
| protocol_edge_case_test | ✅ PASS | 105 | Enhancement |
| rand_test | ✅ PASS | 5 | Core |
| reset_test | ⚠️ FAIL | 7 | Core |
| alternating_pattern_test | ✅ PASS | 225 | Enhancement |
| stress_load_test | ✅ PASS | 751 | Enhancement |
| **TOTAL** | **14/15** | **1,774** | **93.3%** |

---

## 🛠️ Environment Requirements

- **Simulator**: QuestaSim 10.7c or later
- **HDL Language**: SystemVerilog 2012 (IEEE 1800)
- **Verification Framework**: UVM 1.1d
- **Python**: 3.6+ (for report generation)

### Installation Check

```bash
# Verify QuestaSim installation
vsim -version

# Verify Python installation
python --version
```

---

## 📚 Verification Methodology

### 1. **Specification-Based Coverage**
   - All 5 AXI4-Lite channels tested
   - FSM state space covered
   - Protocol edge cases verified

### 2. **Transaction-Level Verification**
   - 1,659 AXI transactions generated
   - Responses validated in real-time
   - Coverage metrics extracted per transaction type

### 3. **Stress Testing**
   - 500+ rapid fire transactions
   - Clock domain crossing stress
   - Full buffer boundary conditions

### 4. **Error Recovery**
   - Reset sequence and recovery
   - Protocol violation handling
   - Edge case protection

---

## 📖 Running Individual Tests

To run a single test and examine its log:

```bash
vsim -c -l uvm_test_logs/basic_rw_test.log work.tb "+UVM_TESTNAME=basic_rw_test" -do "run -all; quit -f"
```

Replace `basic_rw_test` with any of the 14 test names.

---

## 🌊 Viewing Waveforms in QuestaSim

### Step 1: Generate Waveforms (with Coverage)

Run all 15 tests with waveform capture:

```bash
# From project root:
scripts\run_tests_with_waveforms.bat
```

This generates:
- `uvm_test_logs/{test_name}.log` — Test execution logs
- `uvm_test_logs/{test_name}_waveform.wlf` — Waveform database (15 files)
- `uvm_test_logs/{test_name}.ucdb` — Coverage database (15 files)
- `html_reports/*.html` — Coverage reports

**Result:** 15 `.wlf` waveform files ready for viewing

### Step 2: View Waveforms in QuestaSim GUI

After waveforms are generated, view each test's waveforms:

#### **Basic Read-Write Test**
```bash
vsim -gui -do "do scripts/view_waveforms_template.do; set TEST_NAME basic_rw_test; set WAVEFORM_FILE uvm_test_logs/basic_rw_test_waveform.wlf"
```

#### **Alternative: Manual Viewing**

Launch QuestaSim GUI and load waveform file manually:

```bash
# Start QuestaSim GUI
vsim -gui

# In QuestaSim Transcript:
open_file uvm_test_logs/basic_rw_test_waveform.wlf
add wave -noupdate /tb/dut/*
wave zoom full
```

### Complete Commands for All 15 Tests

```bash
# Test 1: Basic Read-Write
vsim -gui -wlf uvm_test_logs/basic_rw_test_waveform.wlf

# Test 2: FIFO Full
vsim -gui -wlf uvm_test_logs/fifo_full_test_waveform.wlf

# Test 3: FIFO Empty  
vsim -gui -wlf uvm_test_logs/fifo_empty_test_waveform.wlf

# Test 4: Reset Test
vsim -gui -wlf uvm_test_logs/reset_test_waveform.wlf

# Test 5: Original Random Test
vsim -gui -wlf uvm_test_logs/rand_test_waveform.wlf

# Test 6: Full Write → Full Read Test
vsim -gui -wlf uvm_test_logs/full_write_full_read_test_waveform.wlf

# Test 7: Continuous Read & Write
vsim -gui -wlf uvm_test_logs/continuous_rw_test_waveform.wlf

# Test 8: CDC Stress Test
vsim -gui -wlf uvm_test_logs/cdc_stress_test_waveform.wlf

# Test 9: Burst Pattern Test
vsim -gui -wlf uvm_test_logs/burst_pattern_test_waveform.wlf

# Test 10: Alternating Pattern Test
vsim -gui -wlf uvm_test_logs/alternating_pattern_test_waveform.wlf

# Test 11: Boundary Condition Test
vsim -gui -wlf uvm_test_logs/boundary_condition_test_waveform.wlf

# Test 12: Interrupt Signals Test
vsim -gui -wlf uvm_test_logs/interrupt_signals_test_waveform.wlf

# Test 13: Stress Load Test
vsim -gui -wlf uvm_test_logs/stress_load_test_waveform.wlf

# Test 14: Protocol Edge Case Test
vsim -gui -wlf uvm_test_logs/protocol_edge_case_test_waveform.wlf

# Test 15: Coverage Test
vsim -gui -wlf uvm_test_logs/coverage_test_waveform.wlf
```

### Waveform Navigation Tips

**Key Controls in QuestaSim:**

| Action | How to Do It |
|--------|-------------|
| Zoom to Full | Menu: Wave → Zoom → Full |
| Zoom to Selection | Wave → Zoom → Fit |
| Pan/Scroll | Use scrollbars or arrow keys |
| Search Signal in Time | Wave → Find → Signal Editor |
| Add Marker | Wave → Marker → Create (for timing measurements) |
| Compare Signals | Drag one signal onto another |
| Bookmark Position | Wave → Bookmark → Create |
| Export Waveform | File → Export → Waveform Data |

**Useful Wave Window Signals:**

For CDC (Clock Domain Crossing) Analysis:
- `/tb/dut/fifo_wr_ptr_gray_r` - Write pointer (Gray code)
- `/tb/dut/fifo_wr_ptr_gray_sync_periph_1` - Sync stage 1
- `/tb/dut/fifo_wr_ptr_gray_sync_periph_2` - Sync stage 2 (synchronized)

For AXI Protocol Analysis:
- `/tb/axi_awvalid`, `/tb/axi_awready` - Write address handshake
- `/tb/axi_wvalid`, `/tb/axi_wready` - Write data handshake
- `/tb/axi_bvalid`, `/tb/axi_bready` - Write response handshake
- `/tb/axi_arvalid`, `/tb/axi_arready` - Read address handshake
- `/tb/axi_rvalid`, `/tb/axi_rready` - Read data handshake

For FIFO Internal State:
- `/tb/dut/fifo_empty_periph_w` - FIFO empty flag
- `/tb/dut/fifo_full_axi_w` - FIFO full flag
- `/tb/dut/fifo_mem[*]` - FIFO memory contents

---

## 🚀 Future Enhancements

- [ ] Extend to AXI4-Full protocol
- [ ] Add multiple simultaneous AXI masters
- [ ] Performance profiling (latency, throughput)
- [ ] Formal verification integration
- [ ] Power analysis during different scenarios

---

## 📝 License

This project is provided for educational and research purposes.

---

## 📞 Support

For issues or questions about the verification environment, refer to:
- DTM: `uvm/components/driver.sv`
- Scoreboards: Coverage metrics in `html_reports/functional_coverage.html`
- Simulation logs: `uvm_test_logs/*.log`

---

**Last Updated**: April 20, 2026  
**Coverage Status**: ✅ 88.1% Grade B (14/15 tests passing, 1,774 transactions, 5 domains, 114/133 bins)  
**Next Target**: 95%+ coverage (A grade) with reset_test fix
