# UVM ALU testbench run flow. Requires a UVM-capable simulator and UVM 1.2+.
# Pick the simulator you have: make questa | make vcs | make xcelium
TEST ?= alu_base_test
SRC   = rtl/alu.sv tb/alu_if.sv tb/alu_pkg.sv tb/tb_top.sv

.PHONY: questa vcs xcelium clean

questa:
	qrun -uvm -sv $(SRC) -top tb_top +UVM_TESTNAME=$(TEST)

vcs:
	vcs -full64 -sverilog -ntb_opts uvm-1.2 $(SRC) -o simv
	./simv +UVM_TESTNAME=$(TEST)

xcelium:
	xrun -uvm -sv $(SRC) +UVM_TESTNAME=$(TEST)

clean:
	rm -rf simv* csrc *.log work qrun.out xcelium.d INCA_libs .simvision
