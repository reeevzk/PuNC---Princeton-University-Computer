16-bit Stored-Program Processor (SystemVerilog + FPGA)

**Overview**

This project implements a 16-bit stored-program processor designed from scratch and deployed on an FPGA. The processor supports a custom instruction set, executes programs from on-chip memory, and demonstrates a full hardware-software stack: ISA design, RTL implementation, control logic, and FPGA integration.

The goal of this project was to explore microarchitectural design tradeoffs and correctness in a simple yet complete CPU, with an emphasis on clean control flow, modular RTL, and verifiable execution semantics.

**Architecture Summary**

Architecture style: 16-bit Stored-program, single-core processor

Execution model: Sequential instruction; fetch–decode–execute

Implementation language: Verilog

Target platform: FPGA

**Core Components**

Program Counter (PC)
- Manages sequential instruction fetch and control flow changes.

Instruction Memory
- Stores executable programs loaded onto the FPGA.

Register File
- General-purpose registers used for arithmetic, logic, and control operations.

ALU
- Supports arithmetic and logical operations defined by the ISA.

Control Unit
- Decodes instructions and generates control signals for datapath coordination.

Data Memory
- Supports load/store operations.

**Instruction Set Architecture (ISA)**

The processor implements a custom 16-bit ISA designed to balance simplicity and expressiveness.

Instruction categories include:

- Arithmetic operations (e.g. add, subtract)

- Logical operations (e.g. and, or)

- Memory operations (load/store)

- Control flow (branch, jump)

Instruction formats are fixed-width and optimized for straightforward decode logic.

**FPGA Implementation**

The processor is synthesized and deployed on an FPGA, enabling:

- Hardware validation beyond simulation

- Debugging via  on-board signals and referencing waveforms

- The FPGA top-level module integrates end-to-end tests execute small programs to verify correct instruction sequencing and state updates


**Future Work**

- Instruction pipelining

- Expanded ISA with multiply or shift operations

- Interruption and exception handling

- Formal verification using SystemVerilog Assertions

- Performance analysis (CPI, critical path)

**Motivation**


This project was built to deepen understanding of processor microarchitecture, RTL design, and hardware execution models, and to serve as a foundation for more advanced chip design work.

