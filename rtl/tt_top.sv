/* SPDX-License-Identifier: Apache-2.0 OR CERN-OHL-P-2.0 */

/*
 * Copyright 2024 Tiny Tapeout Ltd.
 * Copyright 2026 UBC ASIC contributors (Montreal project).
 * All rights reserved.
 *
 * Authors: Tiny Tapeout contributors
 *          Chathil Rajamanthree <chathil.rajaman3@gmail.com>
 *
 * Tiny Tapeout top-level module and QSPI PMOD controller
 */

`default_nettype none

/*
 * Tiny Tapeout top-level wrapper.
 *
 * IMPORTANT: The module definition MUST follow the Tiny Tapeout specification
 *            exactly. Do not modify the port names.
 */
module tt_top_ubc_montreal (
  /* verilog_lint: waive-start port-name-suffix */
  /* Dedicated inputs. */
  input wire [7:0] ui_in,

  /* Dedicated outputs. */
  output wire [7:0] uo_out,

  /* I/O: input path. */
  input  wire [7:0] uio_in,
  /* I/O: output path. */
  output wire [7:0] uio_out,
  /* I/O: active-high output enable. */
  output wire [7:0] uio_oe,

  /* Design enable signal. This will be 1 when the design is powered. */
  input wire ena,
  /* Clock. */
  input wire clk,
  /* Active-low reset. */
  input wire rst_n
  /* verilog_lint: waive-stop port-name-suffix */
);

  /* Temporary output assignments. Unused pins must be assigned to 0. */
  assign uo_out  = ui_in + uio_in;
  assign uio_out = '0;
  assign uio_oe  = '0;

  /* Connect all unused inputs to prevent warnings. */
  wire unused = &{ena, clk, rst_n, 1'b0};

  u_rv32e_core_wrapper rv32e_core_wrapper ();

  u_qspi_controller qspi_controller (
    /* Clock. */
    .clk(),
    /* Active-low reset. */
    .rst_n(),

    /* I/O: input path. */
    .uio_in(),
    /* I/O: output path. */
    .uio_out(),
    /* I/O: active high output enable. */
    .uio_oe()
  );

endmodule : tt_top_ubc_montreal
