/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

/*
 * Copyright 2026 UBC ASIC contributors (Montreal project).
 *
 * Author: Warrick Lo <wlo@warricklo.net>
 *
 * Register file
 *
 * This module contains the register file for the RISC-V core. Each word is
 * partitioned into chunks (default 8 bits). A global chunk selector determines
 * which chunk of each word is accessed for both read and write operations.
 *
 * The register file has one synchronous write port and a configurable number of
 * read ports (default 2). Register 0 is fixed to 0 for all reads.
 */

module regfile #(
  parameter int unsigned WORD_WIDTH = 32,
  parameter int unsigned ADDR_WIDTH = 4,
  parameter int unsigned CHUNK_WIDTH = 8,
  parameter int unsigned NUM_READ_PORTS = 2,

  localparam int unsigned NUM_WORDS  = 2 ** ADDR_WIDTH,
  localparam int unsigned NUM_CHUNKS = WORD_WIDTH / CHUNK_WIDTH
) (
  input logic clk_i,
  input logic [$clog2(NUM_CHUNKS)-1:0] chunk_sel_i,

  input  logic [NUM_READ_PORTS-1:0][ ADDR_WIDTH-1:0] raddr_i,
  output logic [NUM_READ_PORTS-1:0][CHUNK_WIDTH-1:0] rdata_o,

  input logic wen_i,
  input logic [ADDR_WIDTH-1:0] waddr_i,
  input logic [CHUNK_WIDTH-1:0] wdata_i
);

  logic [NUM_WORDS-1:0][WORD_WIDTH-1:0] register;

  always_comb begin
    for (int i = 0; i < NUM_READ_PORTS; i++) begin : gen_read_block
      rdata_o[i] = (raddr_i[i] == 0)
          ? '0 : register[raddr_i[i]][chunk_sel_i*CHUNK_WIDTH +: CHUNK_WIDTH];
    end : gen_read_block
  end

  always_ff @(posedge clk_i) begin
    if (wen_i && (waddr_i != '0)) begin
      /* verilog_lint: waive dff-name-style */
      register[waddr_i][chunk_sel_i*CHUNK_WIDTH +: CHUNK_WIDTH] <= wdata_i;
    end
  end

endmodule : regfile
