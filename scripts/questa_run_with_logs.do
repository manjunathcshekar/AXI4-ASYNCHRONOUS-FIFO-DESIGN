# Run from project root (AXI4-ASYNCHRONOUS-FIFO-DESIGN)
vlib work
vmap work work

# Compile design + UVM TB with dedicated compile log
vlog -sv +acc +incdir+uvm -l compile.log rtl/axi4_lite_fifo_async.v uvm/interface.sv uvm/axi4_uvm_pkg.sv tb/testbench.sv

# Run simulation in batch; capture full transcript (UVM + simulator)
vsim -c -l sim.log work.tb -do "run -all; quit -f"

# After running, compile.log and sim.log contain compilation + runtime output.



