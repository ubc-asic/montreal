/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

/*
 * Copyright 2026 UBC ASIC contributors (Montreal project).
 *
 * Author: Warrick Lo <wlo@warricklo.net>
 *
 * Functional unit
 *
 * This module implements the functional unit (FU). The FU drives
 * the ALU and shifter modules, each of which processes the word
 * one slice at a time (default 8 bits). A new operation is accepted
 * when both valid_i and ready_o are high, and the operation is
 * captured into a register. The module controls the indices for
 * both the read and write slices.
 */

`include "types.svh"

module fu #(
  parameter int unsigned XLEN        = config_pkg::XLEN,
  parameter int unsigned SLICE_WIDTH = config_pkg::SLICE_WIDTH,

  localparam int unsigned SLICE_ADDR_WIDTH = $clog2(XLEN / SLICE_WIDTH)
) (
  input logic clk_i,
  input logic rst_ni,

  input  logic valid_i,
  output logic ready_o,
  input  logic [SLICE_ADDR_WIDTH-1:0] cycle_i,

  input fu_op_t fu_op_i,

  input slice_t a_i,
  input slice_t b_i,

  output slice_t result_o,

  output logic [SLICE_ADDR_WIDTH-1:0] rslice_o,
  output logic [SLICE_ADDR_WIDTH-1:0] wslice_o
);

  fu_op_t fu_op_d, fu_op_q;
  slice_t alu_result;
  logic alu_carry;

  alu #(
    .XLEN       (XLEN),
    .SLICE_WIDTH(SLICE_WIDTH)
  ) alu (
    .clk_i,
    .rst_ni,

    /* Use fu_op_d to select the operation for this cycle, not fu_op_q
     * as it only reflects the captured input one cycle later. */
    .alu_op_i(fu_op_d),
    .count_i (cycle_i),

    .a_i,
    .b_i,

    .result_o(alu_result),
    .carry_o (alu_carry)
  );

  assign ready_o = ~|cycle_i;

  always_comb begin
    /* Capture control signals when ready and input is valid. */
    if (valid_i && ready_o) begin
      fu_op_d = fu_op_i;
    end else begin
      fu_op_d = fu_op_q;
    end

    /* Output multiplexer. We use fu_op_d with the same reasoning as above. */
    unique case (fu_op_d)
      /* ALU operations. */
      ADD, SUB, XOR, OR, AND, SLT, SLTU: begin
        rslice_o = cycle_i;
        wslice_o = cycle_i;
        result_o = alu_result;
      end
      default: begin
        rslice_o = '0;
        wslice_o = '0;
        result_o = '0;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      fu_op_q <= '0;
    end else begin
      fu_op_q <= fu_op_d;
    end
  end

endmodule : fu
