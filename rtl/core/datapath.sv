/*
 * Copyright 2026 Project Montreal contributors.
 *
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 *
 * Project:       Montreal (RV32E SoC for Tiny Tapeout)
 *
 * Module:        datapath
 * Specification: Montreal MAS, Datapath v0.1
 * Version:       0.1.0
 * Authors:       Warrick Lo <wlo@warricklo.net>
 *
 * Description:   RV32E datapath
 */

`include "config.svh"
`include "types.svh"

module datapath (
  input logic clk_i,
  input logic rst_ni,

  input word_t inst_i,

  input imm_fmt_t imm_fmt_i,
  input fu_op_t   fu_op_i,
  input logic     commit_i,

  input logic       asel_i,
  input logic       bsel_i,
  input logic [1:0] wsel_i,

  output slice_t result_o
);

endmodule : datapath
