/*
 * Copyright 2026 Project Montreal contributors.
 *
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 *
 * Project:     Montreal (RV32E SoC for Tiny Tapeout)
 *
 * File:        config.svh
 * Version:     0.1.0
 * Authors:     Warrick Lo <wlo@warricklo.net>
 *
 * Description: Configuration parameters
 */

`ifndef CONFIG_SVH
`define CONFIG_SVH

/* Word width as defined in the RISC-V spec. */
localparam int unsigned XLEN = 32;

/* We use a byte-sliced datapath, inspired by the
 * classic bit-sliced architecture of old CPUs. */
localparam int unsigned SLICE_WIDTH     = 8;
localparam int unsigned SLICE_COUNT     = XLEN / SLICE_WIDTH;
/* SBY fails to evaluate $clog2() when the input is another localparam. */
localparam int unsigned SLICE_SEL_WIDTH = $clog2(XLEN / SLICE_WIDTH);

/* The RV32E ISA defines 16 general-purpose registers.
 * We have two read ports to allow for pipelined reads. */
localparam int unsigned REG_COUNT      = 16;
localparam int unsigned REG_READ_PORTS = 2;
localparam int unsigned REG_ADDR_WIDTH = $clog2(REG_COUNT);

/* Bits needed to encode the datapath's cycle count. */
localparam int unsigned DATAPATH_CYCLE_WIDTH = SLICE_SEL_WIDTH + 1;

/* Bits needed to encode a shift amount within a word or a slice. */
localparam int unsigned WORD_SHIFT_WIDTH  = $clog2(XLEN);
localparam int unsigned SLICE_SHIFT_WIDTH = $clog2(SLICE_WIDTH);

`endif /* CONFIG_SVH */
