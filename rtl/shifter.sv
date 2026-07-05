/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

`include "types.svh"

module shifter #(
  parameter int unsigned XLEN        = config_pkg::XLEN,
  parameter int unsigned SLICE_WIDTH = config_pkg::SLICE_WIDTH,

  localparam int unsigned SLICE_ADDR_WIDTH  = $clog2(XLEN / SLICE_WIDTH),
  localparam int unsigned SLICE_SHAMT_WIDTH = $clog2(SLICE_WIDTH)
) (
  input logic clk_i,
  input logic rst_ni,

  /* Shift direction. 0: left; 1: right. */
  input logic shift_type_i,
  /* Arithmetic shift. */
  input logic shift_arithmetic_i,
  input logic [$clog2(XLEN)-1:0] shamt_i,

  input slice_t data_i,
  input logic [SLICE_ADDR_WIDTH-1:0] slice_i,

  output slice_t result_o,
  output logic [SLICE_ADDR_WIDTH-1:0] slice_o
);

  slice_t next_slice_d, next_slice_q;

  /* Slice shift amounts. shamt1: bits kept in this slice; shamt2: bits spilled into
   * the carry for the next slice. If shamt1 is 0, then the carry should be 0. */
  logic next_slice_zero;
  logic [SLICE_SHAMT_WIDTH-1:0] shamt1, shamt2;
  assign shamt1 = shamt_i[SLICE_SHAMT_WIDTH-1:0];
  assign {next_slice_zero, shamt2}
      = (SLICE_SHAMT_WIDTH+1)'(SLICE_WIDTH) - (SLICE_SHAMT_WIDTH+1)'(shamt1);

  /* Signed difference between input and output slices. Must be 1 bit wider
   * so the wrap can be detected in the MSB. */
  logic [SLICE_ADDR_WIDTH:0] slice_diff;
  assign slice_diff = (SLICE_ADDR_WIDTH+1)'(slice_i) - (SLICE_ADDR_WIDTH+1)'(slice_o);

  /* Latch the fill bit once, on the most significant slice of a right shift. */
  logic fill_d, fill_q;
  assign fill_d = (shift_type_i && &slice_i)
      ? (shift_arithmetic_i ? data_i[SLICE_WIDTH-1] : '0)
      : fill_q;

  always_comb begin
    /* Right shifts: goes from most to least significant slice. */
    if (shift_type_i) begin
      /* Vacated slice: fill with the fill bit (0 for logical shifts,
       * sign bit for arithmetic shifts). */
      if (slice_diff[SLICE_ADDR_WIDTH]) begin
        result_o = {SLICE_WIDTH{fill_q}};

      /* First slice: shift only as there is no carry. */
      end else if (&slice_i) begin
        if (shift_arithmetic_i) begin
          result_o = $signed(data_i) >>> shamt1;
        end else begin
          result_o = data_i >> shamt1;
        end

      /* Other slices: shift and combine with the carried bits. */
      end else begin
        result_o = next_slice_q | (data_i >> shamt1);
      end

      /* These are the bits that spill past the slice's boundary. */
      next_slice_d = next_slice_zero ? '0 : (data_i << shamt2);

      /* Output slice address. */
      slice_o = slice_i - SLICE_ADDR_WIDTH'(shamt_i >> SLICE_SHAMT_WIDTH);

    /* Left shifts: goes from least to most significant slice. */
    end else begin
      /* Vacated slice: fill with 0. */
      if (!slice_diff[SLICE_ADDR_WIDTH] && |slice_diff) begin
        result_o = '0;

      /* First slice: shift only as there is no carry. */
      end else if (~|slice_i) begin
        result_o = data_i << shamt1;

      /* Other slices: shift and combine with the carried bits. */
      end else begin
        result_o = next_slice_q | (data_i << shamt1);
      end

      /* These are the bits that spill past the slice's boundary. */
      next_slice_d = next_slice_zero ? '0 : (data_i >> shamt2);

      /* Output slice address. */
      slice_o = slice_i + SLICE_ADDR_WIDTH'(shamt_i >> SLICE_SHAMT_WIDTH);
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      next_slice_q <= '0;
      fill_q       <= '0;
    end else begin
      next_slice_q <= next_slice_d;
      fill_q       <= fill_d;
    end
  end

endmodule : shifter
