/*
 * Copyright 2026 Project Montreal contributors.
 *
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 *
 * Project:     Montreal (RV32E SoC for Tiny Tapeout)
 *
 * Module:      common_reg_bank
 * Authors:     Chathil Rajamanthree <chathil.rajaman3@gmail.com>
 *
 * Description: Common register bank for the IO subsystem
 */

module common_reg_bank (
  /* Generic signals. */
  input logic clk_i,
  input logic rst_ni,

  /* IO bus interconnect path. */
  input  io_bus_req_t  req_i,
  output io_bus_resp_t resp_o

  // TODO: Add sideband connections
);

endmodule : common_reg_bank
