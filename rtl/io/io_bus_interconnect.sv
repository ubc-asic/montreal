/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

/*
 * Copyright 2026 UBC ASIC contributors (Montreal project).
 * All rights reserved.
 *
 * Authors: Chathil Rajamanthree <chathil.rajaman3@gmail.com>
 *
 * IO bus interconnect: address-decodes the core-facing request onto one
 * of the peripheral-facing ports below, and muxes the selected
 * peripheral's response back to the core.
 *
 * The Common Regbank is reachable READ-ONLY over this bus (inband).
 * Writes to the regbank do not go through this interconnect at all —
 * they are issued directly by the core over the regbank's sideband
 * port. A `we`-asserted request decoded to the regbank fan-out below
 * should be treated as invalid.
 */

 // Notes for DRs:
 // - Interconnect is purely combinational
 // - Requester and responder are required to flop inputs and outputs

/*
 * // TODO: Address map
 * ===========
 *
 * 0x0000_0000 - 0x00FF_FFFF    FLASH 0
 * 0x0100_0000 - 0x1FFF_FFFF    RESERVED
 * 0x2000_0000 - 0x207F_FFFF    RAM 1
 * 0x2080_0000 - 0x20FF_FFFF    RAM 2
 * 0x2100_0000 - 0x3FFF_FFFF    RESERVED
 * 0x4000_0000 - 0x4000_0FFF    UART 0
 * 0x4100_0000 - 0xFFFF_FFFF    REGISTER BANK
 *
 * // TODO: Common Regbank Register Map
 */
module io_bus_interconnect (
  /* Generic signals. */
  input logic clk_i,
  input logic rst_ni,

  /* Core-facing port. */
  input  io_bus_req_t  core_req_i,
  output io_bus_resp_t core_resp_o,

  /* Fan-out to QSPI Controller. */
  output io_bus_req_t  qspi_req_o,
  input  io_bus_resp_t qspi_resp_i,

  /* Fan-out to UART Controller. */
  output io_bus_req_t  uart_req_o,
  input  io_bus_resp_t uart_resp_i,

  /* Fan-out to Common Regbank. Read-only: writes are issued via the
   * regbank's sideband port, not this bus. */
  output io_bus_req_t  regbank_req_o,
  input  io_bus_resp_t regbank_resp_i
 );

  // ---------------------------------------------------------------
  // Address decode
  // ---------------------------------------------------------------
  typedef enum logic [1:0] {
    TargetQspi,
    TargetUart,
    TargetRegbank,
    TargetNone
  } target_e;
  target_e target;

// Decode Target
 always_comb begin
  case (core_req_i.req_addr[31:24])
    8'h00: target = TargetQspi;
    8'h20: target = TargetQspi;
    8'h40: target = TargetUart;
    8'h41: target = TargetRegbank;
    default : target = TargetNone;
  endcase
 end

// Route I/O
always_comb begin
  case (target)
    TargetQspi: begin 
      qspi_req_o    = core_req_i;
      uart_req_o    = '0;
      regbank_req_o = '0;
      core_resp_o   = qspi_resp_i;
    end
    TargetUart: begin 
      qspi_req_o    = '0;
      uart_req_o    = core_req_i;
      regbank_req_o = '0;
      core_resp_o   = uart_resp_i;
    end
    TargetRegbank: begin 
      qspi_req_o    = '0;
      uart_req_o    = '0;
      regbank_req_o = core_req_i;
      core_resp_o   = regbank_resp_i;
    end
    default: begin
      qspi_req_o    = '0;
      uart_req_o    = '0;
      regbank_req_o = '0;
      core_resp_o   = '0;
    end
  endcase
 end

endmodule : io_bus_interconnect
