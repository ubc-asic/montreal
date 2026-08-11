/*
 * Copyright 2026 Project Montreal contributors.
 *
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 *
 * Project:       Montreal (RV32E SoC for Tiny Tapeout)
 *
 * Module:        regfile
 * Specification: Montreal MAS, Register File v0.3
 * Version:       0.2.0
 * Authors:       Warrick Lo <wlo@warricklo.net>
 *
 * Description:   RV32E register file
 *
 * This module contains the register file for the RISC-V core. Each word
 * is partitioned into slices (default 8 bits). Separate read and write
 * slice selectors determine which slice of each word is accessed for
 * their respective operation.
 *
 * The register file has one synchronous write port and a configurable
 * number of read ports (default 2). Register 0 is fixed to 0 for
 * all reads.
 */

`include "types.svh"

module regfile #(
  parameter int unsigned XLEN           = config_pkg::XLEN,
  parameter int unsigned SLICE_WIDTH    = config_pkg::SLICE_WIDTH,
  parameter int unsigned ADDR_WIDTH     = config_pkg::REG_ADDR_WIDTH,
  parameter int unsigned NUM_READ_PORTS = config_pkg::REG_NUM_READ_PORTS,

  localparam int unsigned NUM_WORDS        = 2 ** ADDR_WIDTH,
  localparam int unsigned SLICE_ADDR_WIDTH = $clog2(XLEN / SLICE_WIDTH)
) (
/* Expose the internal register state for formal verification.
 * Yosys/SBY cannot reliably reference hierarchical signals after
 * elaboration and optimisation. */
`ifdef FORMAL
  /* verilog_lint: waive port-name-suffix */
  output word_bank_t register_dbg,
`endif

  input logic clk_i,
  input logic rst_ni,

  input  logic [SLICE_ADDR_WIDTH-1:0]                rslice_i,
  input  logic [NUM_READ_PORTS-1:0][ADDR_WIDTH-1:0]  raddr_i,
  output logic [NUM_READ_PORTS-1:0][SLICE_WIDTH-1:0] rdata_o,

  input logic wen_i,
  input logic [SLICE_ADDR_WIDTH-1:0] wslice_i,
  input logic [ADDR_WIDTH-1:0]       waddr_i,
  input logic [SLICE_WIDTH-1:0]      wdata_i
);

  word_bank_t register;

/* Debug signal for formal verification. See above. */
`ifdef FORMAL
  assign register_dbg = register;
`endif

  always_comb begin
    for (int i = 0; i < NUM_READ_PORTS; i++) begin : gen_read_block
      rdata_o[i] = (raddr_i[i] == '0)
          ? '0 : register[raddr_i[i]][rslice_i*SLICE_WIDTH+:SLICE_WIDTH];
    end : gen_read_block
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      register <= '0;
    end else if (wen_i && (waddr_i != '0)) begin
      /* verilog_lint: waive dff-name-style */
      register[waddr_i][wslice_i*SLICE_WIDTH+:SLICE_WIDTH] <= wdata_i;
    end
  end

endmodule : regfile
