/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

/*
 * Copyright 2026 UBC ASIC contributors (Montreal project).
 * All rights reserved.
 *
 * Authors: Chathil Rajamanthree <chathil.rajaman3@gmail.com>
 *
 * Interface between core and QSPI Pmod
 *
 * https://onlinedocs.microchip.com/oxy/GUID-450989FA-38E4-4D68-AB61-15ADB29AD718-en-US-6/GUID-C2190631-B6F5-4CD7-B6DB-5267DC280E90_3.html
 */

/*
 * Pin mapping
 * ===========
 *
 * QSPI Serial CLK
 *
 * QSPI CS - Active Low
 *
 * QSPI IO_0
 * QSPI IO_1
 * QSPI IO_2
 * QSPI IO_3
 */
module qspi_controller (
  /* verilog_lint: waive-start port-name-suffix */
  /* Clock. */
  input wire clk,
  /* Active-low reset. */
  input wire rst_n,

  /* I/O: input path. */
  input  wire [7:0] uio_in,
  /* I/O: output path. */
  output wire [7:0] uio_out,
  /* I/O: active-high output enable. */
  output wire [7:0] uio_oe
  /* verilog_lint: waive-stop port-name-suffix */
);

  logic       qspi_clk;
  logic       qspi_cs_n;
  logic [3:0] qspi_data;

endmodule : qspi_controller
