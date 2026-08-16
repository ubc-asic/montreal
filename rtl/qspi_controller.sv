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

 // TODO: Add error state: if ifetch_req & dmem_req asserted at same time

module qspi_controller #(
  parameter int unsigned XLEN             = config_pkg::XLEN,
  parameter int unsigned DMEM_ADDR_WIDTH  = config_pkg::DMEM_ADDR_WIDTH,
  parameter int unsigned IMEM_ADDR_WIDTH  = config_pkg::IMEM_ADDR_WIDTH,
  parameter logic [7:0]  IFETCH_CMD       = config_pkg::IFETCH_CMD,
  parameter logic [7:0]  DWRITE_CMD       = config_pkg::DWRITE_CMD,
  parameter logic [7:0]  DREAD_CMD        = config_pkg::DREAD_CMD
) (
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
  input   wire [IMEM_ADDR_WIDTH-1:0] ifetch_addr_in,
  output  wire ifetch_done_out,
  output  wire [XLEN-1:0] ifetch_data_out,

  /* DMEM handshake */
  input   wire [2:0] funct3,
  input   wire dmem_req_in,
  input   wire dmem_we_in,
  input   wire [XLEN-1:0] dmem_data_in,
  input   wire [DMEM_ADDR_WIDTH-1:0] dmem_addr_in,
  output  wire dmem_done_out,
  output  wire [XLEN-1:0] dmem_data_out
  );

  logic       qspi_clk;
  logic       qspi_cs_n;
  logic [3:0] qspi_data;

  logic       init_done;
  logic       cmd_done;
  logic       addr_done;
  logic       dummy_done;
  logic       rx_done;
  logic       tx_done;

  reg [IMEM_ADDR_WIDTH-1:0] imem_addr_q;   // Clocks in imem address input
  reg [DMEM_ADDR_WIDTH-1:0] dmem_addr_q;   // Clocks in dmem address input
  reg [XLEN-1:0]            dmem_data_q;   // Clocks in data input

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
      INIT:   if (init_done)                    next_state = IDLE;
      IDLE:   if (ifetch_req_in || dmem_req_in) next_state = CMD;
      CMD:    if (cmd_done)                     next_state = ADDR;
      ADDR:   if (addr_done)                    next_state = DUMMY;
      DUMMY:  begin 
        if (dummy_done && (ifetch_req_in || (dmem_req_in && !dmem_we_in))) next_state = RX; // RX if ifetch/load
        else if (dummy_done && (dmem_req_in && dmem_we_in))                next_state = TX; // TX if store
      end
      RX: if (rx_done) next_state = DONE;
      TX: if (tx_done) next_state = DONE;
      DONE: next_state = IDLE;
      default: next_state = state;
    endcase
  end

  // State reg
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= INIT;
    end else begin
      state <= next_state;
    end
  end

  // Outputs
  always_ff @(posedge clk) begin
    if (!rst_n) begin

    end
  end

endmodule : qspi_controller
