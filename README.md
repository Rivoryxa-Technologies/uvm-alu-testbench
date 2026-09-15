# uvm-alu-testbench

A complete, well structured UVM testbench for a pipelined 32-bit ALU. It is a
compact reference for how we build class based verification environments:
sequence driven stimulus, a self checking scoreboard with a reference model,
functional coverage, and a reusable agent.

> **Executed evidence:** the class environment at revision `6f885404` now has a [reproducible Verilator 5.050 and Accellera UVM 2020.3.1 runner](https://github.com/Rivoryxa-Technologies/uvm-execution-verification). Three seeds each produce 200 scoreboard matches and zero mismatches/errors. A separate fault-enabled run demonstrates scoreboard mismatch detection. The runner records its exact test-only DUT instrumentation and source hashes. The earlier DUT/interface lint result remains a separate check.
>
> This Verilator run ignores the class-member opcode covergroup and uses `UVM_NO_DPI`. It demonstrates executed classes and scoreboard checking, not functional coverage collection or validation of every UVM feature. Commercial simulator targets below have not been independently rerun as part of this evidence update.

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
- **Coverage** subscriber defines an opcode coverpoint. Collection depends on simulator support; the recorded Verilator run ignores it.
- **Agent, env, and test** wire it together and run a randomized sequence.

## Running it

For the measured open-source execution, use `make test` in the [pinned execution runner](https://github.com/Rivoryxa-Technologies/uvm-execution-verification). It fetches this immutable source revision and the UVM library automatically.

The following commercial simulator make targets are included for adaptation; they are not the commands behind the published execution evidence:

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

This is our public reference structure for a UVM environment. For clients we build block level UVM testbenches with a reference model, constrained random sequences, functional coverage, and a self checking scoreboard. We run them on the client's UVM simulator, or on Verilator with the open source Accellera UVM library when no commercial licence is available, and we deliver the run logs alongside the code.

See the [Rivoryxa profile](https://github.com/Rivoryxa-Technologies) for our full service list, or reach us on [LinkedIn](https://www.linkedin.com/company/rivoryxa-technologies/).
