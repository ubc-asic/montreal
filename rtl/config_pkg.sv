/*
 * Copyright 2026 Project Montreal contributors.
 *
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 *
 * Project:     Montreal (RV32E SoC for Tiny Tapeout)
 *
 * Package:     config_pkg
 * Version:     0.1.0
 * Authors:     Warrick Lo <wlo@warricklo.net>
 *
 * Description: Configuration parameters
 */

package config_pkg;

  /* Word width as defined in the RISC-V spec. */
  localparam int unsigned XLEN = 32;

  /* We use a byte-sliced datapath, inspired by the
   * classic bit-sliced architecture of old CPUs. */
  localparam int unsigned SLICE_WIDTH = 8;

  /* The RV32E ISA defines 16 general-purpose registers.
   * We have two read ports to allow for pipelined reads. */
  localparam int unsigned REG_ADDR_WIDTH     = 4;
  localparam int unsigned REG_NUM_READ_PORTS = 2;

endpackage : config_pkg
