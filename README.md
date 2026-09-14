# uvm-alu-testbench

A complete, well structured UVM testbench for a pipelined 32-bit ALU. It is a
compact reference for how we build class based verification environments:
sequence driven stimulus, a self checking scoreboard with a reference model,
functional coverage, and a reusable agent.

> **Verified:** the DUT and interface lint clean under Verilator. The UVM class environment needs a UVM capable simulator (Questa, VCS, or Xcelium) to elaborate and run.

## What is in it

```
rtl/alu.sv      registered ALU DUT (add, sub, and, or, xor, sll, srl, slt)
tb/alu_if.sv    interface with driver and monitor clocking blocks
tb/alu_pkg.sv   UVM env: item, sequence, driver, monitor, agent,
                scoreboard, coverage, env, test
tb/tb_top.sv    clock, reset, DUT, interface, run_test
Makefile        run targets for Questa, VCS, and Xcelium
```

## UVM structure

- **Sequence item** carries `a`, `b`, `op`, and the captured `result`.
- **Driver** applies operands over a clocking block, one transaction per beat.
- **Monitor** reconstructs each transaction, accounting for the one cycle
  pipeline latency, and broadcasts it on an analysis port.
- **Scoreboard** predicts the result with a reference model and compares.
- **Coverage** subscriber closes an opcode coverpoint.
- **Agent, env, and test** wire it together and run a randomized sequence.

## Running it

UVM needs a UVM capable simulator (UVM 1.2 or later). Pick the one you have:

```bash
make questa     # or: make vcs / make xcelium
```

Override the test or transaction count on the command line:

```bash
make vcs TEST=alu_base_test
```

## Notes

The DUT here is intentionally simple so the testbench structure stays readable.
The same skeleton (agent, scoreboard, coverage, layered sequences) is what we
scale up for real IP blocks.

## What Rivoryxa delivers with this

This is our public reference structure for a UVM environment. For clients we build block level UVM testbenches with a reference model, constrained random sequences, functional coverage, and a self checking scoreboard. The simulator and supported features must be agreed and validated for the client environment. This repository has not demonstrated a UVM run on Verilator; its implemented run targets are Questa, VCS and Xcelium.

See the [Rivoryxa profile](https://github.com/Rivoryxa-Technologies) for our full service list, or reach us on [LinkedIn](https://www.linkedin.com/company/rivoryxa-technologies/).

## Rechecked scope, 15 September 2026

`verilator --lint-only -sv --timing rtl/alu.sv tb/alu_if.sv` exits zero on
Verilator 5.050, macOS arm64. It excludes `tb/alu_pkg.sv` and `tb/tb_top.sv`, so
it does not elaborate or run the UVM classes, scoreboard or coverage. Questa,
VCS and Xcelium were unavailable in this audit. A complete UVM regression remains
unverified; no passing simulation claim follows from this lint check.
