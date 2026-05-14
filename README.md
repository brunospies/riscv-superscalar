# riscv-superscalar

Development of a RISC-V superscalar processor as part of the *Projet Thématique* course at ENSEIRB-MATMECA.

This project focuses on the design and implementation of a dual-issue superscalar RISC-V processor. The repository covers the entire hardware development lifecycle, from RTL design and simulation to FPGA implementation and ASIC backend synthesis flow.

## Architecture Overview

![RISC-V Superscalar Architecture Diagram](docs/RISCV_Superscalar_Ilustration.png)

The core is designed to maximize Instruction Per Cycle (IPC) throughput by fetching, decoding, and executing up to two instructions simultaneously.

**Key Architecture Features:**
- **Dual-Issue Superscalar:** Capable of dispatching two instructions per clock cycle.
- **5-Stage Pipeline:** Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory (MEM), and Write-Back (WB).
- **Branch Prediction:** Features a **Bimodal Branch Target Buffer (BTB)**. To optimize performance and hardware inference, branch decisions and target addresses are resolved and evaluated in the **EX stage**.
- **Hazard Management:** Full data forwarding logic to minimize pipeline stalls.

---

## Repository Structure

```text
riscv-superscalar/
├── asic/       # ASIC synthesis and physical design flow (Design Compiler/Encounter)
├── docs/       # Project documentation, architecture diagrams, and reports
├── fpga/       # FPGA implementation files, XDC constraints, and bitstream deployment
├── rtl/        # Core RTL VHDL source files (Frontend)
├── software/   # Test programs (C/Assembly), firmware, and compilation toolchains
├── tb/         # Testbenches and Simulation environments
```

---
## Project Presentation

📄 [Download the presentation](docs/Present_ProjetThematique.pdf)

---
## 1. Simulation

Functional verification and waveform analysis are handled in the `tb/` directory.

Currently, the simulation environment is built around a **Vivado Project** located in the `tb/` folder. Simply open the `.xpr` file in Vivado to run the testbenches.

> **Future Work:** Automate the Vivado simulation project creation using Tcl scripts to allow a seamless command-line simulation flow.

---

## 2. FPGA Implementation

The processor is fully synthesizable and tested on physical hardware (Xilinx Artix-7/Nexys A7). The Vivado project for synthesis, place & route, and bitstream generation is located in the `fpga/` directory.

> **Future Work:** Similar to the simulation environment, the GUI-based Vivado project will be replaced/complemented by automated Tcl scripts for batch-mode bitstream generation.

### Running on the FPGA (Hardware Flow)
To test the processor on the physical board, a Python workflow is provided to send machine code and retrieve memory dumps over UART.

**Execution Steps:**
1. Toggle **Switch 1** to the `ON` position to hold the processor in `Reset`.
2. Run the deployment script located in `fpga/scripts/`:
   ```bash
   python fpga/scripts/test.py
   ```
3. The script will send the compiled `.txt` code to the FPGA Instruction Memory.
4. Toggle **Switch 1** to `OFF` to release the reset and start processor execution.
5. Once the program finishes, press the **Center Button (BTNC)** on the FPGA to trigger the "Memory Scan".
6. The Python script will receive the contents of the Data Memory and display the results in your terminal.

### Performance and Power Analysis (Hardware-Level)

The table below summarizes the results obtained by running the **BubbleSort** algorithm, comparing efficiency across different branch decision stages and the impact of the BTB predictor.

| Configuration | Max Frequency | Execution Time | Total Power | Energy Consumption |
| :--- | :---: | :---: | :---: | :---: |
| **No Pred - ID** | 40 MHz | 16.6 µs | 0.385 W | 6.39 µJ |
| **No Pred - EX** | 75 MHz | 10.5 µs | 0.496 W | 5.21 µJ |
| **BTB - ID** | 40 MHz | 14.6 µs | 0.392 W | 5.72 µJ |
| **BTB - EX** | 65 MHz | **9.58 µs** | 0.542 W | **5.19 µJ** |

#### Key Insights:
* **Energy Efficiency:** The **BTB - EX** configuration proved to be the most efficient overall, achieving the lowest execution time and total energy consumption (5.19 µJ), despite having higher instantaneous power.
* **Frequency vs. IPC Trade-off:** While branch decision in the ID stage theoretically benefits IPC, it strains the critical path, limiting frequency to 40 MHz. Resolving branches in the EX stage allows for significantly higher clock speeds (up to 75 MHz).
* **Impact of BTB:** The implementation of the Bimodal predictor reduced both execution time and energy consumption in both scenarios, validating the effectiveness of the superscalar architecture with branch prediction.

---
## 3. ASIC Conception

The backend flow for Application-Specific Integrated Circuit (ASIC) design is hosted in the `asic/` directory. This section contains the synthesis (`synthesis/`), place and route (`par/`), timing analysis, power analysis, and physical constraints required to map the RTL design to a standard-cell technology node.

You can check the complete ASIC backend documentation here:

📄 [ASIC Backend Flow Documentation](asic/README.md)

---

## Results & Comparison

### Physical Synthesis Results (PAR)

| Metric | Value |
|---|---|
| Fmax | ~40 MHz |
| Total Power | 36.94 mW |
| Leakage Power | 68.5 µW |
| Switching Power | 18.55 mW |
| Total Area | 2.49 mm² |
| Technology | CMOS C35 (350 nm) |


---
### IPC and Frequency Comparison

| Configuration | IPC (BubbleSort) | FPGA Frequency (Xilinx Artix-7) |
|---|---|---|
| Superscalar (ID) | 1.10 | 40 MHz |
| Superscalar (EX) | 0.93 | 75 MHz |
| Superscalar (ID) + BTB Bimodal | 1.25 | 40 MHz |
| Superscalar (EX) + BTB Bimodal | 1.17 | 65 MHz |

The superscalar architecture with branch decision in the ID stage presents the highest IPC values, but with a lower maximum frequency due to the increased critical path complexity.  
In contrast, the EX-stage branch decision achieves higher operating frequencies at the cost of a slightly lower IPC.

---

### Frequency Comparison with Other Processors

| Processor | Architecture | Technology | Frequency | Particularities |
|---|---|---|---|---|
| MIPS R3000 | Scalar, 5 stages | 1 µm / 350 nm | 20–33 MHz | Classical RISC architecture |
| RVCoreP | RISC-V 5-stage pipeline | Modern FPGA | >100 MHz | FPGA-oriented implementation |
| Wildcat RISC-V | Educational pipeline | FPGA | ~50–100 MHz | Forwarding and hazard management |
| Our Work (ASIC) | RISC-V superscalar dual-issue | CMOS C35 (350 nm) | ~37 MHz | BTB, forwarding, branch prediction |
| Our Work (FPGA) | RISC-V superscalar dual-issue | Artix-7 FPGA | ~70 MHz | FPGA implementation of the same core |

---

The obtained frequencies are coherent with the targeted CMOS C35 technology node and with the increased complexity introduced by the superscalar dual-issue architecture and branch prediction logic.

---

## Authors

- Bruno Henrique Spies
- Mathias Michelotti
- Mathieu Escouteloup
