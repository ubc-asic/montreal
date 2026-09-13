/*
 * Copyright 2026 Project Montreal contributors.
 *
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 *
 * Project:     Montreal (RV32E SoC for Tiny Tapeout)
 *
 * Module:      qspi_controller
 * Authors:     Chathil Rajamanthree <chathil.rajaman3@gmail.com>
 *
 * Description: Interface for the QSPI peripheral
 */

module qspi_controller (
  /* Generic signals. */
  input logic clk_i,
  input logic rst_ni,

  /* IO bus interconnect path. */
  input  io_bus_req_t  req_i,
  output io_bus_resp_t resp_o,

  /* Chip-level pins. */
  /* verilog_lint: waive-start port-name-suffix */
  input  logic [7:0] uio_in,
  output logic [7:0] uio_out,
  output logic [7:0] uio_oe
  /* verilog_lint: waive-stop port-name-suffix */
);

  logic       qspi_clk;
  logic       qspi_cs_n;
  logic [3:0] qspi_data;

  /* Suppress Yosys check errors. */
  assign uio_out = '0;
  assign uio_oe  = '0;

endmodule : qspi_controller
