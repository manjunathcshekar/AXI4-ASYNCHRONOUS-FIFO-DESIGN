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
vlog -sv interrupt_controller.sv axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv
vsim -gui work.tb -voptargs=+acc -wlf fifo_waveform.wlf
add wave -position insertpoint sim:/tb/dut/*
run 1000ns
```

### Batch run with persistent logs (QuestaSim)
- `vsim -c -do questa_run_with_logs.do`
  - Produces `compile.log` (vlog messages) and `sim.log` (full transcript with UVM INFO/WARN/ERROR/FATAL and final summary).
This will:

- Compile the DUT and testbench  
- Launch the simulation GUI  
- Add DUT signals to the waveform viewer  
- Run the simulation for **1000 ns**

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
