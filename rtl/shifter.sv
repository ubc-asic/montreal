/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

/*
 * Copyright 2026 UBC ASIC contributors (Montreal project).
 *
 * Author: Warrick Lo <wlo@warricklo.net>
 *
 * Shifter
 *
 * This module implements the shifter for the functional unit (FU).
 * Each word is shifted one slice at a time (default 8 bits). The input
 * counter cycle_i is used to keep track of the current slice. The module
 * will output the address for both the read and write slices.
 *
 * This module assumes that the control signals are all stable until
 * the entire word is finished processing. It also assumes that cycle_i
 * increments by 1, starting at 0.
 */

`include "types.svh"

module shifter #(
  parameter int unsigned XLEN        = config_pkg::XLEN,
  parameter int unsigned SLICE_WIDTH = config_pkg::SLICE_WIDTH,

  localparam int unsigned SLICE_ADDR_WIDTH  = $clog2(XLEN / SLICE_WIDTH),
  localparam int unsigned SLICE_SHAMT_WIDTH = $clog2(SLICE_WIDTH)
) (
  input logic clk_i,
  input logic rst_ni,

  /* Counter input. */
  input logic [SLICE_ADDR_WIDTH-1:0] cycle_i,

  /* Shift direction. 0: left; 1: right. */
  input logic shift_type_i,
  /* Arithmetic shift. */
  input logic shift_arithmetic_i,
  input logic [$clog2(XLEN)-1:0] shamt_i,

  input  slice_t data_i,
  output slice_t result_o,

  output logic [SLICE_ADDR_WIDTH-1:0] rslice_o,
  output logic [SLICE_ADDR_WIDTH-1:0] wslice_o
);

  logic fill_d, fill_q;
  slice_t carry_d, carry_q, carry_in;

  /* Slice shift amounts: shamt1 generates bits kept in this slice; shamt2 generates bits
   * spilled into the carry for the next slice. If shamt1 is 0, then the carry should be 0. */
  logic no_carry;
  logic [SLICE_SHAMT_WIDTH-1:0] shamt1, shamt2;
  assign shamt1 = shamt_i[SLICE_SHAMT_WIDTH-1:0];
  assign {no_carry, shamt2}
      = (SLICE_SHAMT_WIDTH+1)'(SLICE_WIDTH) - (SLICE_SHAMT_WIDTH+1)'(shamt1);

  /* Address of the read slice. Counts up from the least significant slice for
   * left shifts and down from the most significant slice for right shifts. */
  assign rslice_o = shift_type_i ? ~cycle_i : cycle_i;

  /* Signed difference between input and output slices. Must be 1 bit wider
   * so the wrap can be detected in the MSB. */
  logic [SLICE_ADDR_WIDTH:0] slice_diff;
  assign slice_diff = (SLICE_ADDR_WIDTH+1)'(rslice_o) - (SLICE_ADDR_WIDTH+1)'(wslice_o);

  /* Check when the write slice address wraps around the slice boundary,
   * indicating that the slice should be filled with the fill bit. */
  logic is_wrapped;
  assign is_wrapped = (~shift_type_i & ~slice_diff[SLICE_ADDR_WIDTH] & |slice_diff)
      | (shift_type_i & slice_diff[SLICE_ADDR_WIDTH]);

  always_comb begin
    logic sign;
    slice_t raw_result;

    sign = data_i[SLICE_WIDTH-1];

    /* First slice processed for this word. This is the least significant slice
     * for left shifts and the most significant slice for right shifts. */
    if (~|cycle_i) begin
      /* For arithmetic right shifts of a negative value, carry_in is seeded
       * with sign bits, which is for computing the arithmetic shift right
       * of this slice, and the fill bit should be 1. */
      if (shift_type_i && shift_arithmetic_i && sign) begin
        carry_in = no_carry ? '0 : ({SLICE_WIDTH{1'b1}} << shamt2);
        fill_d = '1;
      end else begin
        carry_in = '0;
        fill_d = '0;
      end
    end else begin
      carry_in = carry_q;
      fill_d = fill_q;
    end

    /* Combine this slice's shifted data with the shifted result spilled
     * from the previous slice. */
    raw_result = carry_in | (shift_type_i ? (data_i >> shamt1) : (data_i << shamt1));
    /* Save the shifted data that is spilled over to the next slice. */
    carry_d = no_carry ? '0 : (shift_type_i ? (data_i << shamt2) : (data_i >> shamt2));
    /* Compute the address of the write slice. For left shifts we add and
     * for right shifts we subtract the value of (shamt / SLICE_WIDTH). */
    wslice_o = rslice_o
        + (SLICE_ADDR_WIDTH'(shamt_i >> SLICE_SHAMT_WIDTH) ^ {SLICE_ADDR_WIDTH{shift_type_i}})
        + SLICE_ADDR_WIDTH'(shift_type_i);

    /* If the slice address wraps around, fill the slice with the fill bit. */
    result_o = is_wrapped ? {SLICE_WIDTH{fill_q}} : raw_result;
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      carry_q <= '0;
      fill_q  <= '0;
    end else begin
      carry_q <= carry_d;
      fill_q  <= fill_d;
    end
  end

endmodule : shifter
