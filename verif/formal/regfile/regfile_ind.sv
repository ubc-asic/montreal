/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

/**
 * @brief  Formal verification of regfile requirements
 * @author Warrick Lo
 */

`include "types.svh"

module regfile_ind (
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

  always_ff @(posedge clk_i) begin
    /* verilog_lint: waive dff-name-style */
    past_valid <= '1;
  end

  /*
   * REQ-REGFILE-010:
   * The module must store NUM_WORDS words, each XLEN bits wide.
   *
   * Notes: This verification module assumes NUM_WORDS = 16 and XLEN = 32.
   *        The definition of 'register' must use the type defined
   *        in types.svh.
   */

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
   * Notes: This verification module assumes XLEN = 32 and SLICE_WIDTH = 8.
   *        These three requirements are easiest to verify together.
   */

  always_comb begin
    if (raddr_i[0] != '0) begin
      assert (rdata[0] == register[raddr_i[0]][(slice_sel_i + 1) * 8 - 1 : slice_sel_i * 8]);
    end
    if (raddr_i[1] != '0) begin
      assert (rdata[1] == register[raddr_i[1]][(slice_sel_i + 1) * 8 - 1 : slice_sel_i * 8]);
    end
  end

  /*
   * REQ-REGFILE-030:
   * Register contents must be 0 at most one clock after the synchronous reset is asserted.
   */

  always_ff @(posedge clk_i) begin
    if (past_valid && $past(!rst_ni, 1)) begin
      assert (register == '0);
    end
  end

  /*
   * REQ-REGFILE-040:
   * Writes to the register file must only occur on the rising edge of clk_i.
   */

  /* Structural requirement satisfied by construction. */

  /*
   * REQ-REGFILE-041:
   * Writes to the register file must only occur when wen_i is asserted.
   */

  always_ff @(posedge clk_i) begin
    if (past_valid && $past(rst_ni && !wen_i, 1)) begin
      /* Satisfies the requirement, but possibly not the intended RTL behaviour.
       * See ticket #14. */
      assert ($stable(register));
    end
  end

  /*
   * REQ-REGFILE-042:
   * Contents of wdata_i must be written only to the slice selected by slice_sel_i
   * within the register selected by waddr_i. All other slices of the target register
   * shall remain unchanged.
   */

  /* We'll use a part-select to obtain the slice data since we can assume that
   * slice_sel_i will select the correct slice within the target register,
   * according to requirement REQ-REGFILE-020. */
  always_ff @(posedge clk_i) begin
    for (int i = 0; i < 16; i++) begin
      for (int j = 0; j < 4; j++) begin
        /* Ignore reset events. */
        if (!past_valid) begin
        end else if ($past(!rst_ni)) begin
        end else if ((i == $past(waddr_i)) && (j == $past(slice_sel_i))) begin
          assert ($stable(register[i][j*8+:8]) || (register[i][j*8+:8] == $past(wdata_i)));
        end else begin
          assert ($stable(register[i][j*8+:8]));
        end
      end
    end
  end

  /*
   * REQ-REGFILE-043:
   * Writes to register 0 shall be silently ignored, regardless of the state of wen_i.
   */

  always_ff @(posedge clk_i) begin
    if (past_valid && $past(rst_ni && waddr_i == '0)) begin
      assert ($stable(register[0]));
    end
  end

  /*
   * REQ-REGFILE-052:
   * The read output rdata[i] must be zero when raddr[i] is zero,
   * regardless of any prior writes to register 0.
   */

  always_comb begin
    if (raddr_i[0] == '0) assert (rdata[0] == '0);
    if (raddr_i[1] == '0) assert (rdata[1] == '0);
  end

  /*
   * REQ-REGFILE-053:
   * Requirement DR-REGFILE-052 shall be unconditional: it must hold at power-on
   * without reset having been asserted, and at all times during normal operation.
   */

  logic rst_asserted;

  initial assume (rst_asserted == '0);

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      rst_asserted <= '1;
    end

    cover (!rst_asserted);
  end

  /*
   * REQ-REGFILE-060:
   * The module shall not implement any bypass logic. A read and write to
   * the same address in the same cycle shall return the value held in
   * the register prior to the rising clock edge of the current cycle.
   */

  logic [7:0] x0, x8;
  assign x0 = register[0];
  assign x8 = register[8];

  always_comb begin
    if (wen_i && raddr_i[0] != '0 && raddr_i[0] == waddr_i) begin
      assert (rdata[0] == register[raddr_i[0]][slice_sel_i*8+:8]);
    end
    if (wen_i && raddr_i[1] != '0 && raddr_i[1] == waddr_i) begin
      assert (rdata[1] == register[raddr_i[1]][slice_sel_i*8+:8]);
    end
  end

endmodule : regfile_ind
