# ASIC Backend Flow

This directory contains the ASIC synthesis and physical design flow used for the RISC-V superscalar processor.

## Overview

The backend flow includes:

- Logic synthesis using Synopsys Design Compiler
- Physical synthesis and place & route using Cadence Encounter
- Timing analysis
- Power analysis
- Area estimation

The processor is implemented in CMOS C35 (350 nm) technology.

---

## Architecture

The synthesized processor is a:

- RISC-V superscalar dual-issue processor
- 5-stage pipeline
- Branch decision in EX stage
- Hazard detection and forwarding support
- Branch Target Buffer (BTB)

---

## Directory Structure

```text
asic/
├── constraints/     # Timing and floorplan constraints
├── synthesis/       # Design Compiler synthesis scripts
├── par/             # Physical design flow (Encounter)
├── reports/         # Timing, area and power reports
└── work/            # Generated temporary files
```

---

## Tools

The following EDA tools were used:

| Tool | Purpose |
|---|---|
| Synopsys Design Compiler | Logic synthesis |
| Cadence Encounter | Place and Route |
| Vivado | FPGA implementation and comparison |

---

## Technology

- CMOS C35 (350 nm)
- Standard-cell based implementation

---

## Results

### Logic Synthesis

| Metric | Value |
|---|---|
| Frequency | ~30 MHz |
| Total Power | ~28 mW |
| Leakage Power | ~70 µW |

### FPGA Implementation

| Metric | Value |
|---|---|
| Frequency | ~70 MHz |
| FPGA | Xilinx Artix-7 |

---

## Critical Path Analysis

The critical path is mainly located between:

- ALU branch logic
- Bubble control logic
- Program Counter update path

The superscalar control logic and branch redirection significantly increase the combinational delay.

---

## Notes

- VHDL compilation order is important.
- Packages must be analyzed before architectural blocks.
- Generated files (`.spf`, `.enc.dat`, `.db`, `WORK/`) should not be committed to Git.

---

## Authors
- Bruno Henrique Spies
- Mathias Michelotti
- Mathieu Escouteloup
