# Synchronous FIFO in Verilog (parameterized, self-checking testbench)

A single-clock, parameterized FIFO buffer written in Verilog, verified with a self-checking testbench that uses a reference model, and synthesized and implemented in Vivado 2024.2 for a Xilinx Kintex-7 device.

**Status:** simulation passes (20,193 checks, 0 errors). Not tested on hardware (no FPGA board).

## Specification

| Item | Value |
|---|---|
| Clocking | Single clock, rising edge |
| Reset | Asynchronous assert, active high (`rst`) |
| Data width | `DW` (default 8) |
| Depth | `DEPTH` (default 16, **must be a power of two**) |
| Read data | Registered: `dout` is valid one clock after an accepted read |
| Flags | `full`, `empty`, derived from an occupancy counter |

### Ports

| Signal | Dir | Description |
|---|---|---|
| `clk` | in | Clock |
| `rst` | in | Asynchronous reset, active high |
| `wr_en` | in | Write request |
| `r_en` | in | Read request |
| `din[DW-1:0]` | in | Write data |
| `dout[DW-1:0]` | out | Read data (registered) |
| `full` | out | High when the FIFO holds `DEPTH` words |
| `empty` | out | High when the FIFO holds no words |

## How it works

The memory is a circular buffer with two pointers and a counter:

<img width="363" height="208" alt="image" src="https://github.com/user-attachments/assets/a8df7c09-9082-4a72-94a0-4a7852c0ad4d" />

- `wr_ptr` points to the next slot to write and `r_ptr` to the oldest unread slot. Both wrap to 0 automatically because `DEPTH` is a power of two.
- `count` holds the number of stored words, from 0 to `DEPTH`. It needs `AW+1` bits, where `AW = $clog2(DEPTH)`.
- A request is **accepted** only if the FIFO state allows it: `do_wr = wr_en && !full`, `do_rd = r_en && !empty`.
- `count` is updated once per clock from both events together: write only, +1; read only, -1; both or neither, unchanged.

### Behavior in the corner cases

| Situation | What happens |
|---|---|
| Write while full | Ignored; no data or pointer corruption |
| Read while empty | Ignored; `dout` keeps its old value |
| Read and write together, FIFO neither full nor empty | Both happen; `count` is unchanged |
| Read and write together, FIFO empty | Only the write happens (no read-through) |
| Read and write together, FIFO full | Only the read happens |

### Design history

An early version updated `count` with two separate assignments in the same clock edge (one for the write, one for the read). The last assignment wins in Verilog, so a simultaneous read and write lost the write, and the FIFO drifted into reporting `empty` while data was still stored. The original testbench never exercised a same-cycle read and write, so it missed this. The current version uses a single `case` statement on `{do_wr, do_rd}`. The final testbench detects the bug when it is reintroduced.

## Verification

`tb/fifo_tb.v` is self-checking. A behavioral reference model (an array with its own pointers and count) predicts which requests are accepted and what data should come out. After every clock edge the testbench compares `dout`, `full` and `empty` against the model, counts mismatches, and prints `RESULT: PASS` or `RESULT: FAIL`.

| # | Test | Purpose |
|---|---|---|
| 1 | Reset | Flags correct after reset |
| 2 | Fill to full, then keep writing | Overflow is ignored |
| 3 | Drain to empty, then keep reading | Underflow is ignored |
| 4 | Read and write together, FIFO empty | Only the write is accepted |
| 5 | Sustained read and write together, mid-level (100 cycles) | Counter stays consistent (catches the original bug) |
| 6 | Read and write together, FIFO full | Only the read is accepted |
| 7 | 20,000 cycles of random read, write and data | Corner cases not planned by hand |

Result: **20,193 checks, 0 errors, `RESULT: PASS`**, also confirmed at depths 4, 8, 32 and 64 with data width 12.

### Mutation check

To confirm the testbench actually detects bugs, the `count` update was temporarily replaced with two separate assignments. The testbench reported `RESULT: FAIL` with `empty` and `dout` mismatches (screenshot in `docs/`), then passed again after restoring the `case` statement.

### Waveforms

| Fill to full | Drain to empty | Simultaneous read and write |
|---|---|---|
| ![fill](docs/waveform_fill_full.png) | ![drain](docs/waveform_drain_empty.png) | ![rw](docs/waveform_simultaneous_rw.png) |

## Running the simulation

**Vivado:** add `rtl/fifo.v` as a design source and `tb/fifo_tb.v` as a simulation source. Set `fifo_tb` as the simulation top, then in the Tcl Console run `run all`. Look for `RESULT: PASS`.

**Icarus Verilog:**

```
iverilog -g2012 -o sim rtl/fifo.v tb/fifo_tb.v
vvp sim
```

## Synthesis and implementation results

Vivado 2024.2, target `xc7k70tfbv676-1` (Kintex-7), module synthesized out of context with `constraints/fifo.xdc` (clock period 4 ns).

| Metric | Result |
|---|---|
| Slice LUTs | 61 |
| Slice registers | 149 |
| F7 / F8 muxes | 16 / 8 |
| Slices | 51 |
| Clock period tested | 4 ns (250 MHz) |
| Worst negative slack (setup) | +1.481 ns |
| Worst hold slack | +0.164 ns |
| Failing endpoints | 0 |

At a 10 ns clock the same design had a setup slack of +7.216 ns. Timing was verified at 4 ns (250 MHz); a rough estimate from slack, 1 / (4 ns - 1.481 ns), is about 397 MHz, which is **not** a measured result.

### Notes

- The 149 registers are the memory implemented as flip-flops (16 x 8 = 128) plus `wr_ptr` (4), `r_ptr` (4), `count` (5) and `dout` (8). The F7 and F8 muxes form the 16:1 read mux. A distributed-RAM version (`ram_style = "distributed"`) would trade registers for LUT RAM.
- Timing covers internal register-to-register paths only. Input and output delays are not constrained because the module is not connected to real pins.
- Results come from implementation only. The design has not been run on an FPGA board.

## Limitations and next steps

- Single clock only. An asynchronous FIFO needs Gray-coded pointers and two-flop synchronizers; a version of this design for two clock domains is the planned next step.
- No almost-full or almost-empty flags, no overflow or underflow error outputs, and no first-word-fall-through read mode.
- Add assertions (SystemVerilog) and coverage to the testbench.

```

## Author

Param Tomar, B.Tech Electronics and Communication Engineering, JIIT Noida
