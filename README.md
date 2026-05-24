Montreal
========

A RISC-V RV32E processor designed for TinyTapeout.

[RV32E](https://docs.riscv.org/reference/isa/unpriv/unpriv-index.html)
----------------------------------------------------------------------

Reduces number of integer registers to 16 general-purpose registers (x0-x15). Upper 16 registers consume around one quarter of the total area of the core excluding memories, thus their removal saves around 25% core area with a corresponding core power reduction.

Each register is 32 bits wide.

| Register | Description | Purpose |
| -------- | ----------- | ------- |
| x0 | dedicated zero | Source operand for value 0. |
| x1 | return address | Written by JAL/JALR. Holds address to be returned to once a function returns. Must be saved to stack before calling another function. |
| x2 | stack pointer | Always points to top of the stack in RAM. Decremented to allocate space, incremented to free it. CALLEE must restore it BEFORE returning. |
| x3 | global pointer | |
| x4 | thread pointer | |
| x5 | alternate link reg | Second link register for nested JAL sequences. Caller must save if needed across a call. |
| x6 | general scratch reg | |
| x7 | general scratch reg | |
| x8 | frame pointer | |
| x9 | saved register | |
| x10 | first function argument | Also used to return integer results from function. |
| x11 | second function argument | |
| x12 | third function argument | |
| x13 | fourth function argument | |
| x14 | fifth function argument | |
| x15 | sixth function argument | |
| pc | program counter | Address of current instruction |

INSTRUCTION SET
---------------

### Formats

![U-type instructions (LUI)](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/u-type-lui.json5)

![U-type instructions (AUIPC)](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/u-type-auipc.json5)

![J-type instructions](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/j-type.json5)

![I-type instructions (JALR)](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/i-type-jalr.json5)

![B-type instructions](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/b-type.json5)

![I-type instructions (load)](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/i-type-load.json5)

![S-type instructions](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/s-type.json5)

![I-type instructions (arithmetic and logic)](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/i-type-alu.json5)

![I-type instructions (shift)](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/i-type-shift.json5)

![R-type instructions](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/r-type.json5)

![I-type instructions (system)](https://svg.wavedrom.com/github/ubc-asic/montreal-docs/master/images/i-type-system.json5)

### R-Type (Register-to-register)

| Instruction | Description | Encoding (`funct7` \| `funct3` \| `opcode`) |
| ----------- | ----------- | ------------------------------------------ |
| ADD  | Add two registers and store the result in rd. | `0000000` \| `000` \| `0110011` |
| SUB  | Subtract rs2 from rs1 and store the result in rd. | `0100000` \| `000` \| `0110011` |
| SLL  | Shift rs1 left by the amount in rs2 (logical), store result in rd. | `0000000` \| `001` \| `0110011` |
| SLT  | Set rd to 1 if rs1 < rs2 (signed), otherwise 0. | `0000000` \| `010` \| `0110011` |
| SLTU | Set rd to 1 if rs1 < rs2 (unsigned), otherwise 0. | `0000000` \| `011` \| `0110011` |
| XOR  | Bitwise XOR of rs1 and rs2, result in rd. | `0000000` \| `100` \| `0110011` |
| SRL  | Shift rs1 right by the amount in rs2 (logical), store result in rd. | `0000000` \| `101` \| `0110011` |
| SRA  | Shift rs1 right by the amount in rs2 (arithmetic), sign-extend result into rd. | `0100000` \| `101` \| `0110011` |
| OR   | Bitwise OR of rs1 and rs2, result in rd. | `0000000` \| `110` \| `0110011` |
| AND  | Bitwise AND of rs1 and rs2, result in rd. | `0000000` \| `111` \| `0110011` |

### I-Type (Immediate)

#### OP-IMM — Integer immediate ops (opcode `0010011`)

| Instruction | Description | Encoding (`imm[11:0]` \| `funct3` \| `opcode`) |
| ----------- | ----------- | ----------------------------------------------- |
| ADDI  | Add sign-extended 12-bit immediate to rs1, store in rd. | imm \| `000` \| `0010011` |
| SLTI  | Set rd to 1 if rs1 < sign-extended imm (signed), else 0. | imm \| `010` \| `0010011` |
| SLTIU | Set rd to 1 if rs1 < sign-extended imm (unsigned), else 0. | imm \| `011` \| `0010011` |
| XORI  | Bitwise XOR of rs1 and sign-extended imm, result in rd. | imm \| `100` \| `0010011` |
| ORI   | Bitwise OR of rs1 and sign-extended imm, result in rd. | imm \| `110` \| `0010011` |
| ANDI  | Bitwise AND of rs1 and sign-extended imm, result in rd. | imm \| `111` \| `0010011` |

##### Shifting Instructions that carry an encoding disciminator in `imm[11:5]`
| Instruction | Description | Encoding (`imm[11:5]`\| `funct3` \| `opcode`) |
| ----------- | ----------- | ----------------------------------------------- |
| SLLI  | Shift rs1 left by shamt (`imm[4:0]`), logical, store in rd. | `0000000` \| `001` \| `0010011` |
| SRLI  | Shift rs1 right by shamt (`imm[4:0]`), logical, store in rd. | `0000000` \| `101` \| `0010011` |
| SRAI  | Shift rs1 right by shamt (`imm[4:0]`), arithmetic, store in rd. | `0100000` \| `101` \| `0010011` |
