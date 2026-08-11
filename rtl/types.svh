/*
 * Copyright 2026 Project Montreal contributors.
 *
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 *
 * Project:     Montreal (RV32E SoC for Tiny Tapeout)
 *
 * File:        types.svh
 * Version:     0.1.0
 * Authors:     Warrick Lo <wlo@warricklo.net>
 *
 * Description: Type definitions
 */

`ifndef TYPES_SVH
`define TYPES_SVH

typedef logic                                        [config_pkg::XLEN-1:0] word_t;
typedef logic [2 ** config_pkg::REG_ADDR_WIDTH - 1:0][config_pkg::XLEN-1:0] word_bank_t;

typedef logic [config_pkg::SLICE_WIDTH-1:0] slice_t;

typedef enum logic [3:0] {
  /* Arithmetic operations. */
  ADD  = 4'b0000,
  SUB  = 4'b1000,
  /* Logical operations. */
  XOR  = 4'b0100,
  OR   = 4'b0110,
  AND  = 4'b0111,
  /* Shift operations. */
  SLL  = 4'b0001,
  SRL  = 4'b0101,
  SRA  = 4'b1101,
  /* Conditional set operations. */
  SLT  = 4'b0010,
  SLTU = 4'b0011
} fu_op_t;

`endif /* TYPES_SVH */
