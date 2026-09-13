/*
 * Copyright 2026 Project Montreal contributors.
 *
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 *
 * Project:       Montreal (RV32E SoC for Tiny Tapeout)
 *
 * Module:        alu
 * Specification: Montreal MAS, Functional Unit v0.1
 * Version:       0.1.0
 * Authors:       Warrick Lo <wlo@warricklo.net>
 *                Dariell Sugiaman <dari3llsugiaman@gmail.com>
 *
 * Description:   Arithmetic logic unit
 *
 * This module implements the ALU for the functional unit (FU).
 * Each word is processed one slice at a time (default 8 bits).
 * Comparisons can be processed on the last cycle with the carry-out.
 *
 * This module assumes that the control signals are all stable until
 * the entire word is finished processing. It also assumes that cycle_i
 * increments by 1, starting at 0.
 */

`include "config.svh"
`include "types.svh"

module alu (
  input logic clk_i,
  input logic rst_ni,

  input logic [DATAPATH_CYCLE_WIDTH-1:0] cycle_i,

  input fu_op_t alu_op_i,

  input slice_t a_i,
  input slice_t b_i,

  output slice_t result_o,
  output logic   carry_o
);

  logic negate_b;

  /* We used Karnaugh maps here. If the encoding for fu_op_t changes, this has to be updated. */
  assign negate_b = alu_op_i[3] || (!alu_op_i[2] && alu_op_i[1]);

  /* Carry signals. */
  logic carry, carry_d, carry_q;

  /* For the first slice, carry-in must be driven to zero for addition
   * and one for subtraction or comparisons. All other slices use the
   * carry-out from the previous slice */
  assign carry = (cycle_i == '0) ? negate_b : carry_q;

  /* Adder width is SLICE_WIDTH + 1 to account for carry-out. */
  logic [SLICE_WIDTH:0] adder_a, adder_b, adder_result;

  assign adder_a = {1'b0, a_i};
  assign adder_b = {1'b0, (b_i ^ {SLICE_WIDTH{negate_b}})};

  /* ADD, SUB, SLT, SLTU use the same adder to computer their results*/
  assign adder_result = adder_a + adder_b + (SLICE_WIDTH + 1)'(carry);

  assign carry_o = adder_result[SLICE_WIDTH];
  assign carry_d = carry_o;

  /* Combinational arithmetic/logic core. */
  always_comb begin : alu_core
    unique casez (alu_op_i[2:0])
      /* ADD, SUB, SLT, SLTU. */
      3'b0??:  result_o = adder_result[SLICE_WIDTH-1:0];
      /* XOR. */
      3'b100:  result_o = a_i ^ b_i;
      /* OR. */
      3'b110:  result_o = a_i | b_i;
      /* AND. */
      3'b111:  result_o = a_i & b_i;
      /* Default case. */
      default: result_o = 'x;
    endcase
  end : alu_core

  always_ff @(posedge clk_i) begin : carry_ff
    if (!rst_ni) begin
      carry_q <= '0;
    end else begin
      carry_q <= carry_d;
    end
  end : carry_ff

endmodule : alu
