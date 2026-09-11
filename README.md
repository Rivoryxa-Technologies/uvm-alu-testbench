# uvm-alu-testbench

A complete, well-structured UVM testbench for a pipelined 32-bit ALU. It is a
compact reference for how we build class-based verification environments:
sequence-driven stimulus, a self-checking scoreboard with a reference model,
functional coverage, and a reusable agent.

> **Verified:** the DUT and interface lint clean under Verilator. The UVM class environment needs a UVM-capable simulator (Questa, VCS, or Xcelium) to elaborate and run.

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
- **Monitor** reconstructs each transaction, accounting for the one-cycle
  pipeline latency, and broadcasts it on an analysis port.
- **Scoreboard** predicts the result with a reference model and compares.
- **Coverage** subscriber closes an opcode coverpoint.
- **Agent, env, and test** wire it together and run a randomized sequence.

## Running it

UVM needs a UVM-capable simulator (UVM 1.2 or later). Pick the one you have:

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
scale up for real blocks and SoC-level verification. Want this extended with a
register model, more sequences, or a constrained-random test plan? Reach out.

---
Maintained by [Rivoryxa Technologies](https://www.linkedin.com/company/rivoryxa-technologies/).
