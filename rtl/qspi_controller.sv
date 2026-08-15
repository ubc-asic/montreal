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

 /* 
 * QSPI controller is a dedicated FSM responsible for serialising instruction fetch and data memory accesses over the QSPI PMOD interface
 * Implements a simple req/ack interface to the cpu datapath
 */
module qspi_controller 
  import config_pkg::*;
  (
  /* verilog_lint: waive-start port-name-suffix */
  /* Clock. */
  input wire clk,
  /* Active-low reset. */
  input wire rst_n,
  /* I/O: input path. */
  input wire [7:0] uio_in,
  /* I/O: output path. */
  output wire [7:0] uio_out,
  /* I/O: active-high output enable. */
  output wire [7:0] uio_oe,
  /* verilog_lint: waive-stop port-name-suffix */

  /* IMEM handshake */
  input   wire ifetch_req_in,
  input   wire ifetch_addr_in,
  output  wire ifetch_done_out,
  output  wire [XLEN-1:0] ifetch_data_out,

  /* DMEM handshake */
  input   wire [2:0] funct3,
  input   wire dmem_req_in,
  input   wire dmem_we_in,
  input   wire dmem_addr_in,
  output  wire dmem_done_out,
  output  wire [XLEN-1:0] dmem_data_out
  );

  logic       qspi_clk;
  logic       qspi_cs_n;
  logic [3:0] qspi_data;

  logic       init_done;

  // State definition
  typedef enum logic [2:0] {
    INIT,
    IDLE,
    CMD,
    ADDR,
    DUMMY,
    TX,
    RX,
    DONE
  } state_t;
  state_t state, next_state;

  // Next state logic
  always @(*) begin
    next_state = state;
    case (state)
      INIT: if (init_done) next_state = IDLE;
      default: next_state = state;
    endcase
  end

  // State reg
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= INIT;
    end
  end

  // Outputs
  always_ff @(posedge clk) begin
    if (!rst_n) begin

    end
  end

endmodule : qspi_controller
