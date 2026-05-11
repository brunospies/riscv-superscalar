# riscv-superscalar

Development of a RISC-V superscalar processor as part of the *Projet Thématique* course at ENSEIRB-MATMECA.

This project focuses on the design and implementation of a dual-issue superscalar RISC-V processor, including FPGA implementation and ASIC backend synthesis flow.

The repository is currently under development and documentation will be expanded progressively.

---

## Repository Structure

```text
riscv-superscalar/
├── asic/       # ASIC synthesis and physical design flow
├── docs/       # Project documentation and reports
├── fpga/       # FPGA-specific modules and top-level files
├── rtl/        # Core RTL VHDL source files
├── software/   # Software and test programs
├── tb/         # Testbenches and simulation files
```

---

## Current Features

- RISC-V superscalar dual-issue architecture
- 5-stage pipeline
- Branch handling and hazard management
- Forwarding logic
- Branch Target Buffer (BTB)
- FPGA implementation
- ASIC synthesis and physical design flow

---

## Authors

- Bruno Henrique Spies
- Mathias Michelotti
- Mathieu Escouteloup
