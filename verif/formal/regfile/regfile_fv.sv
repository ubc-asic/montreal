/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

/*
 * Copyright 2026 UBC ASIC contributors (Montreal project).
 *
 * Author: Warrick Lo <wlo@warricklo.net>
 *
 * Formal verification of regfile requirements
 *
 * This module verifies the regfile module against the requirements
 * specified in the design specification.
 *
 * The following parameters are used for all tests:
 * - Word width:           32 bits wide
 * - Slice width:          8 bits wide
 * - Number of words:      16 words
 * - Number of read ports: 2
 *
 * The following are design requirements that are assumed to be verifed by construction:
 * - REQ-REGFILE-010
 * - REQ-REGFILE-040
 * REQ-REGFILE-010 is further verified below.
 *
 * The following requirements are verified through this module:
 * - Cover:
 *   - REQ-REGFILE-053
 * - Bounded model checking:
 *   - REQ-REGFILE-010
 *   - REQ-REGFILE-053
 * - K-induction:
 *   - REQ-REGFILE-020
 *   - REQ-REGFILE-030
 *   - REQ-REGFILE-041
 *   - REQ-REGFILE-042
 *   - REQ-REGFILE-043
 *   - REQ-REGFILE-050
 *   - REQ-REGFILE-051
 *   - REQ-REGFILE-052
 *   - REQ-REGFILE-060
 *
 * See also: MAS, Regfile Specification, version 0.2
 *           rtl/regfile.sv
 */

`include "types.svh"

module regfile_fv (
  input logic clk_i,
  input logic rst_ni,
  input logic [1:0] slice_sel_i,

  input logic [1:0][3:0] raddr_i,

  input logic wen_i,
  input logic [3:0] waddr_i,
  input logic [7:0] wdata_i
);

  /*
   * DUT interface and internal signals.
   */

  word_bank_t register;
  logic [1:0][7:0] rdata;

  /*
   * DUT instance.
   */

  regfile #(
    .XLEN(32),
    .SLICE_WIDTH(8),
    .ADDR_WIDTH(4),
    .NUM_READ_PORTS(2)
  ) dut (
    .register_dbg(register),
    .clk_i,
    .rst_ni,
    .slice_sel_i,

    .raddr_i,
    .rdata_o(rdata),

    .wen_i,
    .waddr_i,
    .wdata_i
  );

  /*
   * Some assertions use $past(), which requires at least one clock edge.
   * Those tests will use past_valid to check if a valid history exists.
   */

  logic past_valid;

  initial assume (past_valid == '0);

  always_ff @(posedge clk_i) begin : past_valid_dff
    /* verilog_lint: waive dff-name-style */
    past_valid <= '1;
  end : past_valid_dff

  /*
   * REQ-REGFILE-010:
   * The module must store NUM_WORDS words, each XLEN bits wide.
   */

  /* The definition of 'register' must use the type defined in types.svh. */
  initial assert ($bits(register) == 16 * 32);

  /*
   * REQ-REGFILE-020:
   * Slice k of word n shall correspond to bits [(k+1)*SLICE_WIDTH−1:k*SLICE_WIDTH]
   * of register n, partitioning each word into XLEN/SLICE_WIDTH
   * non-overlapping slices, each SLICE_WIDTH bits wide.
   *
   * REQ-REGFILE-050:
   * The read output rdata_o[i] shall be combinationally derived from
   * the current register state, raddr_i[i], and slice_sel_i. There shall not
   * be any latency on reads.
   *
   * REQ-REGFILE-051:
   * The read output rdata_o[i] must reflect the slice selected by slice_sel_i
   * within the register selected by raddr_i[i].
   *
   * Note: These three requirements are easiest to verify together.
   */

  /* We explicitly ignore the use of part-selects to verify the description of REQ-REGFILE-020. */
  always_comb begin : req_020_050_051
    if (raddr_i[0] != '0) begin
      assert (rdata[0] == register[raddr_i[0]][(slice_sel_i + 1) * 8 - 1 : slice_sel_i * 8]);
    end
    if (raddr_i[1] != '0) begin
      assert (rdata[1] == register[raddr_i[1]][(slice_sel_i + 1) * 8 - 1 : slice_sel_i * 8]);
    end
  end : req_020_050_051

  /*
   * REQ-REGFILE-030:
   * Register contents must be 0 at most one clock after the synchronous reset is asserted.
   */

  always_ff @(posedge clk_i) begin : req_030
    if (past_valid && $past(!rst_ni, 1)) begin
      assert (register == '0);
    end
  end : req_030

  /*
   * REQ-REGFILE-041:
   * Writes to the register file must only occur when wen_i is asserted.
   */

  always_ff @(posedge clk_i) begin : req_041
    if (past_valid && $past(rst_ni && !wen_i, 1)) begin
      /* Satisfies the requirement, but possibly not the intended RTL behaviour.
       * See ticket #14. */
      assert ($stable(register));
    end
  end : req_041

  /*
   * REQ-REGFILE-042:
   * Contents of wdata_i must be written only to the slice selected by slice_sel_i
   * within the register selected by waddr_i. All other slices of the target register
   * shall remain unchanged.
   */

  /* We'll use a part-select to obtain the slice data since we can assume that
   * slice_sel_i will select the correct slice within the target register,
   * according to requirement REQ-REGFILE-020. */
  always_ff @(posedge clk_i) begin : req_042
    /* For register 0, this test will specifically permit writes targeting
     * the register to succeed. The stability of register 0 is separately
     * verified below in REQ-REGFILE-043. */
    for (int i = 0; i < 16; i++) begin : word_loop
      for (int j = 0; j < 4; j++) begin : slice_loop
        /* Ignore reset events. */
        if (past_valid && $past(rst_ni, 1)) begin
          if ($past((waddr_i == i) && (slice_sel_i == j), 1)) begin
            assert ($stable(register[i][j*8+:8]) || (register[i][j*8+:8] == $past(wdata_i, 1)));
          end else begin
            assert ($stable(register[i][j*8+:8]));
          end
        end
      end : slice_loop
    end : word_loop
  end : req_042

  /*
   * REQ-REGFILE-043:
   * Writes to register 0 shall be silently ignored, regardless of the state of wen_i.
   */

  always_ff @(posedge clk_i) begin : req_043
    if (past_valid && $past(rst_ni && (waddr_i == '0), 1)) begin
      assert ($stable(register[0]));
    end
  end : req_043

  /*
   * REQ-REGFILE-052:
   * The read output rdata[i] must be zero when raddr[i] is zero,
   * regardless of any prior writes to register 0.
   */

  always_comb begin : req_052
    if (raddr_i[0] == '0) assert (rdata[0] == '0);
    if (raddr_i[1] == '0) assert (rdata[1] == '0);
  end : req_052

  /*
   * REQ-REGFILE-053:
   * Requirement REQ-REGFILE-052 shall be unconditional: it must hold at power-on
   * without reset having been asserted, and at all times during normal operation.
   */

  logic rst_asserted;

  initial assume (rst_asserted == '0);

  always_ff @(posedge clk_i) begin : req_053
    if (!rst_ni) begin
      rst_asserted <= '1;
    end

    cover (!rst_asserted && wen_i && (waddr_i == '0));
  end : req_053

  /*
   * REQ-REGFILE-060:
   * The module shall not implement any bypass logic. A read and write to
   * the same address in the same cycle shall return the value held in
   * the register prior to the rising clock edge of the current cycle.
   */

  /* Similar to above, we will use a part-select here. */
  always_comb begin : req_060
    if (wen_i && raddr_i[0] != '0 && raddr_i[0] == waddr_i) begin
      assert (rdata[0] == register[raddr_i[0]][slice_sel_i*8+:8]);
    end
    if (wen_i && raddr_i[1] != '0 && raddr_i[1] == waddr_i) begin
      assert (rdata[1] == register[raddr_i[1]][slice_sel_i*8+:8]);
    end
  end : req_060

endmodule : regfile_fv
