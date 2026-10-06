# Predicated 32-bit RISC Processor

A simplified **32-bit predicated RISC processor** designed and implemented in Verilog. The project includes the processor datapath, control path, instruction set, RTL implementation, and a simulation-based verification environment.

## Overview

This project implements a 32-bit RISC processor with:

* 32 general-purpose 32-bit registers
* Predicated instruction execution
* Separate instruction and data memories
* Register, immediate, and jump instruction formats
* Five-stage processor organization:

  * Fetch
  * Decode
  * Execute
  * Memory Access
  * Write Back
* Support for arithmetic, logical, memory, jump, call, and return instructions
* Verilog RTL implementation
* Assembly and binary test programs
* Simulation-based verification with waveform analysis

## Processor Specifications

| Feature                   | Specification                      |
| ------------------------- | ---------------------------------- |
| Instruction size          | 32 bits                            |
| Word size                 | 32 bits                            |
| General-purpose registers | 32 (`R0`–`R31`)                    |
| `R0`                      | Hardwired to zero                  |
| `R30`                     | Program Counter (PC)               |
| `R31`                     | Return Address Register            |
| Memory organization       | Separate instruction/data memories |
| Memory addressing         | Word addressable                   |
| Execution                 | Predicated                         |
| RTL language              | Verilog                            |

## Predicated Execution

Every instruction contains a predicate register `Rp` that determines whether the instruction executes.

* If `Reg[Rp] == 0`, the instruction is **not executed**.
* If `Reg[Rp] != 0`, the instruction **executes normally**.
* To execute an instruction unconditionally, `Rp` can be set to `R0` according to the processor's predicate convention.

This allows instructions to be conditionally executed without requiring separate branch instructions for every condition.

## Instruction Formats

### R-Type

```text
+--------+------+-------+-------+-------+---------+
| Opcode |  Rp  |  Rd   |  Rs   |  Rt   | Unused  |
|  5 bit | 5 bit| 5 bit | 5 bit | 5 bit | 7 bit   |
+--------+------+-------+-------+-------+---------+
```

### I-Type

```text
+--------+------+-------+-------+--------------+
| Opcode |  Rp  |  Rd   |  Rs   | Immediate    |
|  5 bit | 5 bit| 5 bit | 5 bit |   12 bit     |
+--------+------+-------+-------+--------------+
```

### J-Type

```text
+--------+------+------------------------------+
| Opcode |  Rp  |           Offset             |
|  5 bit | 5 bit|           22 bit             |
+--------+------+------------------------------+
```

## Instruction Set

| Instruction | Type | Opcode | Operation                             |
| ----------- | ---: | -----: | ------------------------------------- |
| `ADD`       |    R |    `0` | `Rd = Rs + Rt`                        |
| `SUB`       |    R |    `1` | `Rd = Rs - Rt`                        |
| `OR`        |    R |    `2` | `Rd = Rs \| Rt`                       |
| `NOR`       |    R |    `3` | `Rd = ~(Rs \| Rt)`                    |
| `AND`       |    R |    `4` | `Rd = Rs & Rt`                        |
| `ADDI`      |    I |    `5` | `Rd = Rs + Imm`                       |
| `ORI`       |    I |    `6` | `Rd = Rs \| Imm`                      |
| `NORI`      |    I |    `7` | `Rd = ~(Rs \| Imm)`                   |
| `ANDI`      |    I |    `9` | `Rd = Rs & Imm`                       |
| `LW`        |    I |   `10` | `Rd = Mem(Rs + Imm)`                  |
| `SW`        |    I |   `11` | `Mem(Rs + Imm) = Rd`                  |
| `J`         |    J |   `12` | Jump to target address                |
| `CALL`      |    J |   `13` | Jump and save return address in `R31` |
| `JR`        |    R |   `14` | Jump to address stored in `Rs`        |

All operations are performed using 32-bit values.

## Immediate Values

Immediate values are extended according to the instruction type:

* **Logical instructions** (`ORI`, `NORI`, `ANDI`) use **zero extension**.
* **Arithmetic and memory instructions** use **sign extension**.
* Negative values use **two's-complement representation**.

## Branch and Jump Addressing

Jump targets are calculated by adding the sign-extended instruction offset to the current value of the PC.

The processor supports:

* `J` — unconditional/conditional jump through the predicate mechanism
* `CALL` — function call with the return address stored in `R31`
* `JR` — return or register-based jump using an address stored in a register

## Processor Architecture

The processor is organized into five main stages:

```text
        ┌─────────┐
        │  Fetch  │
        └────┬────┘
             │
             ▼
        ┌─────────┐
        │ Decode  │
        └────┬────┘
             │
             ▼
        ┌─────────┐
        │ Execute │
        │   ALU   │
        └────┬────┘
             │
             ▼
        ┌─────────┐
        │ Memory  │
        │ Access  │
        └────┬────┘
             │
             ▼
        ┌──────────┐
        │Write Back│
        └──────────┘
```

### Datapath

The datapath contains the major components required to execute the instruction set, including:

* Program Counter
* Register file
* Instruction memory
* Data memory
* ALU
* Immediate extension logic
* Multiplexers
* Write-back logic
* Jump and branch address logic
* Predicate evaluation logic
* Return-address handling

### Control Path

The control unit decodes the opcode and generates the control signals required by the datapath.

Control signals determine operations such as:

* Register file write enable
* Data memory read/write
* ALU operation
* ALU operand selection
* Immediate extension mode
* Register write-back source
* Jump selection
* Call/return control
* Predicate enable
* Destination register selection

## Memory Organization

The processor uses separate memories for instructions and data.

### Instruction Memory

Stores 32-bit processor instructions.

### Data Memory

Stores 32-bit data words used by `LW` and `SW`.

The memory system is **word addressable**, meaning each address identifies a 32-bit word.

## Verification

A simulation-based verification environment is included to validate the processor implementation.

The verification environment supports:

1. Loading instructions into instruction memory.
2. Executing programs using the processor's ISA.
3. Monitoring register and memory values.
4. Checking instruction behavior.
5. Testing predicated execution.
6. Verifying jump and function-call behavior.
7. Inspecting simulation waveforms.

### Verification Coverage

Test programs are designed to cover:

* Arithmetic operations
* Logical operations
* Immediate operations
* Load/store operations
* Predicated execution
* Jump instructions
* Function calls
* Register jumps
* Negative immediate values
* Zero and non-zero predicate values
* Register and memory state changes
* Instruction sequencing

## Test Programs

The repository contains test programs written using the processor's instruction set.

Each test program can be represented in:

* Assembly form
* 32-bit binary instruction form

The programs are used to demonstrate the correct operation of individual instructions as well as complete instruction sequences.

## Repository Structure

```text
.
├── rtl/
│   ├── processor.v
│   ├── datapath.v
│   ├── control_unit.v
│   ├── alu.v
│   ├── register_file.v
│   ├── instruction_memory.v
│   └── data_memory.v
│
├── testbench/
│   └── processor_tb.v
│
├── programs/
│   ├── assembly/
│   └── binary/
│
├── diagrams/
│   ├── datapath/
│   └── control/
│
├── simulation/
│   └── waveforms/
│
└── README.md
```

> The exact directory structure may vary depending on the implementation.

## Design Goals

The main design goals are:

* Keep the datapath modular and easy to understand.
* Separate datapath and control logic.
* Support the complete instruction set.
* Make instruction decoding deterministic.
* Implement predicate checking directly in the execution flow.
* Provide a reusable simulation environment.
* Make the RTL easy to extend and debug.

## Tools

The processor is implemented using:

* **Verilog HDL**
* RTL simulation tools
* Waveform viewers for debugging and verification

## Documentation

Additional documentation includes:

* Processor datapath diagrams
* Control-path diagrams
* Control signal truth tables
* State diagrams
* Boolean equations
* Instruction encoding details
* Assembly test programs
* Binary machine-code programs
* Simulation waveforms
* Verification results

## License

This project is provided for educational and research purposes. See the repository license for usage and redistribution terms.
