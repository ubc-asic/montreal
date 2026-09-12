/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

/*
 * Copyright 2026 UBC ASIC contributors (Montreal project).
 * All rights reserved.
 *
 * Authors: Chathil Rajamanthree <chathil.rajaman3@gmail.com>
 *
 * Montreal RV32E IO Wrapper
 *
 * Provides a clean, generic bus interface between the Montreal core and IO block.
 */

module io_wrapper (
  /* Generic signals. */
  input logic clk_i,
  input logic rst_ni,

  /* Core-facing port. */
  input  io_bus_req_t  core_req_i,
  output io_bus_resp_t core_resp_o,

  /* Sideband port. */
  // TODO

  /* Chip-level pins. */
  /* verilog_lint: waive-start port-name-suffix */
  input  logic [7:0] uio_in,
  output logic [7:0] uio_out,
  output logic [7:0] uio_oe
  /* verilog_lint: waive-stop port-name-suffix */
);

  io_bus_req_t  uart_req;
  io_bus_resp_t uart_resp;
  io_bus_req_t  qspi_req;
  io_bus_resp_t qspi_resp;
  io_bus_req_t  regbank_req;
  io_bus_resp_t regbank_resp;

  /* Contains packet forwarding logic from one master to many slaves. */
  // TODO: Leave unstitched until relevant modules completed and initial verif complete
  io_bus_interconnect u_io_bus_interconnect (
    /* Generic signals. */
    .clk_i,
    .rst_ni,

    /* Core-facing port. */
    .core_req_i (),
    .core_resp_o(),

    /* Fan-out to QSPI controller. */
    .qspi_req_o (),
    .qspi_resp_i(),

    /* Fan-out to UART controller. */
    .uart_req_o (),
    .uart_resp_i(),

    /* Fan-out to common regbank. */
    .regbank_req_o (),
    .regbank_resp_i()
  );

  // TODO: Leave unstitched until relevant modules completed and initial verif complete
  qspi_controller u_qspi_controller (
    /* Generic signals. */
    .clk_i,
    .rst_ni,

    /* IO bus interconnect path. */
    .req_i (),
    .resp_o(),

    /* Chip-level pins. */
    .uio_in (),
    .uio_out(),
    .uio_oe ()
  );

  // TODO: Stitch UART module

  /* Common register bank. */
  // TODO: Leave unstitched until relevant modules completed and initial verif complete
  common_reg_bank u_common_reg_bank (
    /* Generic signals. */
    .clk_i,
    .rst_ni,

    /* IO bus interconnect path. */
    .req_i (),
    .resp_o()

    // TODO: Add sideband connections
  );

endmodule : io_wrapper
