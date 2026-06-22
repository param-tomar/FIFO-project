# FIFO-project
This is a fully simulated project on the fifo module working (first in, first out). The simulation response shows the full condition where our fifo module tells us that its memory is full. It also has the feature to let user know when its empty.

# Synchronous FIFO — Verilog

![Language](https://img.shields.io/badge/Language-Verilog-blue)
![Simulator](https://img.shields.io/badge/Simulator-Vivado-green)
![Status](https://img.shields.io/badge/Simulation-Passing-brightgreen)

## What This Does
A parameterised synchronous FIFO implemented in Verilog HDL.
Supports configurable data width and depth. Verified with a
self-checking testbench that writes 8 values and reads them
back, confirming FIFO ordering and full/empty flag behaviour.

## Block Diagram
<img width="363" height="208" alt="image" src="https://github.com/user-attachments/assets/a8df7c09-9082-4a72-94a0-4a7852c0ad4d" />
din[7:0] ──► [ mem[0:DEPTH-1] ] ──► dout[7:0]

wr_en ──►         │         ◄── rd_en

wr_ptr / rd_ptr / count

│          │

full        empty

## Parameters
DW | 8 | Data width in bits 
DEPTH | 16 | Number of entries 

## Files
 `fifo.v` | RTL implementation 
 `fifo_tb.v` | Self-checking testbench 

## How to Simulate (Vivado)
1. Create RTL project in Vivado
2. Add `fifo.v` as design source
3. Add `fifo_tb.v` as simulation source
4. Run Behavioral Simulation
5. Check TCL console for PASS/FAIL output

## Key Concepts Demonstrated
- Parameterised RTL design
- Pointer-based FIFO implementation  
- Full and empty flag logic
- Self-checking testbench methodology

## Simulation Result
<img width="1366" height="729" alt="image" src="https://github.com/user-attachments/assets/7daa2948-46d9-42f5-8024-bc47b11d22bb" />
