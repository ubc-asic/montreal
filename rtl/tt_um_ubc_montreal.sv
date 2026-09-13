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
/* verilog_lint: waive module-filename */
module tt_um_ubc_montreal (
  /* verilog_lint: waive-start port-name-suffix */
  /* Dedicated inputs. */
  input wire [7:0] ui_in,

  /* Dedicated outputs. */
  output wire [7:0] uo_out,

  /* IO: input path. */
  input  wire [7:0] uio_in,
  /* IO: output path. */
  output wire [7:0] uio_out,
  /* IO: active-high output enable. */
  output wire [7:0] uio_oe,

  /* Design enable signal. This will be 1 when the design is powered. */
  input wire ena,
  /* Clock. */
  input wire clk,
  /* Active-low reset. */
  input wire rst_n
  /* verilog_lint: waive-stop port-name-suffix */
);

  /* IO bus handshaking. */
  io_bus_req_t  core_req;
  io_bus_resp_t core_resp;

  /* TODO: Temporary output assignments. Unused pins must be assigned to 0. */
  assign uo_out  = ui_in + uio_in;
  assign uio_out = '0;
  assign uio_oe  = '0;

  /* Connect all unused inputs to prevent warnings. */
  wire unused = &{ena, clk, rst_n, 1'b0};

  rv32e_core_wrapper u_rv32e_core_wrapper ();

  io_wrapper u_io_wrapper (
    .clk_i,
    .rst_ni,

    .core_req_i (core_req),
    .core_resp_o(core_resp),

    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe)
  );

endmodule : tt_um_ubc_montreal
