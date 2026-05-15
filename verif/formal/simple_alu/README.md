# simple_alu Formal Verification

Run with: `sby -f simple_alu.sby` from this directory.

Reference: https://yosyshq.readthedocs.io/projects/sby/en/latest/reference.html

## Mode

Bounded Model Check (BMC, depth=100): proves assertions hold for the first 100 clock cycles.
A counterexample waveform is generated on failure.

Prove mode (k-induction): proves assertions hold for infinite time. Much stronger guarantee but harder to converge. Change `mode bmc` to `mode prove` in the `.sby` to use it.

## Properties

| Name              | Status      | Description                              |
|-------------------|-------------|------------------------------------------|
| `a_rst_check`     | implemented | y == 0 one cycle after reset asserts     |
| `a_rst_overflow`  | planned     | overflow == 0 one cycle after reset      |
| `a_add`           | planned     | y == a+b one cycle after sel=0           |
| `a_sub`           | planned     | y == a-b one cycle after sel=1           |
| `a_overflow_add`  | planned     | overflow correct for addition            |
| `a_overflow_sub`  | planned     | overflow correct for subtraction         |