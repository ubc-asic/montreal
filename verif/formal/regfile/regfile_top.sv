/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

module regfile_top (
  input logic clk_i,
  input logic rst_ni,
  input logic [3:0] slice_sel_i,

  input logic [1:0][3:0] raddr_i,

  input logic wen_i,
  input logic [3:0] waddr_i,
  input logic [7:0] wdata_i
);

  logic [1:0][7:0] rdata;

  regfile #(
    .XLEN(32),
    .SLICE_WIDTH(8),
    .ADDR_WIDTH(4),
    .NUM_READ_PORTS(2)
  ) dut (
    .clk_i,
    .rst_ni,
    .slice_sel_i,

    .raddr_i,
    .rdata_o(rdata),

    .wen_i,
    .waddr_i,
    .wdata_i
  );

  regfile_check inst_checker (
    .clk_i,
    .rst_ni,
    .slice_sel_i,

    .raddr_i,
    .rdata_i(rdata),

    .wen_i,
    .waddr_i,
    .wdata_i
  );

endmodule : regfile_top
