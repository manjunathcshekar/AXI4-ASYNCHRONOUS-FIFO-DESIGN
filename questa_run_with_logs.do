vlib work
vmap work work

# Compile design + UVM TB with dedicated compile log
vlog -sv +acc -l compile.log interrupt_controller.sv axi4_lite_fifo_async.v interface.sv axi4_uvm_pkg.sv testbench.sv

# Run simulation in batch; capture full transcript (UVM + simulator)
vsim -c -l sim.log work.tb -do "run -all; quit -f"

# After running, compile.log and sim.log contain compilation + runtime output.



