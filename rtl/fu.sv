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

  localparam int unsigned SLICE_COUNT      = XLEN / SLICE_WIDTH,
  localparam int unsigned SLICE_ADDR_WIDTH = $clog2(SLICE_COUNT)
) (
  input logic clk_i,
  input logic rst_ni,

  input  logic valid_i,
  output logic ready_o,

  /* Cycle count should be SLICE_ADDR_WIDTH+1 bits wide.
   * Right shift operations need one extra cycle to fetch shamt. */
  input logic [SLICE_ADDR_WIDTH:0] cycle_i,

  input fu_op_t fu_op_i,

  input slice_t a_i,
  input slice_t b_i,

  output slice_t result_o,

  output logic [SLICE_ADDR_WIDTH-1:0] rslice_o,
  output logic [SLICE_ADDR_WIDTH-1:0] wslice_o
);

  /* Control. */

  logic ready_d;
  /* Note: use fu_op_d to select the operation for this cycle, not fu_op_q
   * as it only reflects the captured input one cycle later. */
  fu_op_t fu_op_d, fu_op_q;

  /* Arithmetic logic unit. */

  logic alu_carry;
  slice_t alu_result;

  alu #(
    .XLEN       (XLEN),
    .SLICE_WIDTH(SLICE_WIDTH)
  ) alu (
    .clk_i,
    .rst_ni,

    .cycle_i,

     /* Use fu_op_d here (see above). */
    .alu_op_i(fu_op_d),

    .a_i,
    .b_i,

    .result_o(alu_result),
    .carry_o (alu_carry)
  );

  /* Shifter module. */

  logic shift_type, shift_arithmetic;
  logic [SLICE_ADDR_WIDTH-1:0] shifter_rslice, shifter_wslice;
  logic [$clog2(XLEN)-1:0] shamt_d, shamt_q;
  slice_t shifter_result;

  shifter #(
    .XLEN       (XLEN),
    .SLICE_WIDTH(SLICE_WIDTH)
  ) shifter (
    .clk_i,
    .rst_ni,

    .cycle_i,

    .shift_type_i      (shift_type),
    .shift_arithmetic_i(shift_arithmetic),
    .shamt_i           (shamt_d),

    .data_i  (a_i),
    .result_o(shifter_result),

    .rslice_o(shifter_rslice),
    .wslice_o(shifter_wslice)
  );

  /* Use fu_op_d here (see above). */
  assign shift_type       = fu_op_d[2];
  assign shift_arithmetic = fu_op_d[3];

  /* Control signal capture and output selection. */

  always_comb begin
    /* Capture control signals when ready and input is valid,
     * then deassert ready_o on the next clock. */
    if (valid_i && ready_o) begin
      fu_op_d = fu_op_i;
      ready_d = '0;
    end else begin
      fu_op_d = fu_op_q;
      ready_d = ready_o;
      /* Once the word is finished processing, assert ready_o next clock. */
      unique case (fu_op_d)
        ADD, SUB, XOR, OR, AND, SLT, SLTU, SLL: begin
          /* ALU operations and SLL finish after SLICE_COUNT cycles. */
          if (cycle_i == SLICE_COUNT - 1) ready_d = '1;
        end
        SRL, SRA: begin
          /* SRL and SRA operations require an extra cycle. */
          if (cycle_i == SLICE_COUNT) ready_d = '1;
        end
        default: begin end
      endcase
    end

    /* Capture shift amount on cycle 0. */
    if (~|cycle_i) begin
      shamt_d = b_i[$clog2(XLEN)-1:0];
    end else begin
      shamt_d = shamt_q;
    end

    /* Output multiplexer. We use fu_op_d with the same reasoning as above. */
    unique case (fu_op_d)
      /* ALU operations. */
      ADD, SUB, XOR, OR, AND, SLT, SLTU: begin
        rslice_o = cycle_i;
        wslice_o = cycle_i;
        result_o = alu_result;
      end
      /* Shifter operations. */
      SLL, SRL, SRA: begin
        rslice_o = shifter_rslice;
        wslice_o = shifter_wslice;
        result_o = shifter_result;
      end
      default: begin
        rslice_o = '0;
        wslice_o = '0;
        result_o = '0;
      end
    endcase
  end

  /* Register block. */

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      ready_o <= '1;
      fu_op_q <= '0;
      shamt_q <= '0;
    end else begin
      /* verilog_lint: waive dff-name-style */
      ready_o <= ready_d;
      fu_op_q <= fu_op_d;
      shamt_q <= shamt_d;
    end
  end

endmodule : fu
