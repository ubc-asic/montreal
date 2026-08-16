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

  localparam int IMEM_ADDR_NIBBLES = IMEM_ADDR_WIDTH/4;
  localparam int DMEM_ADDR_NIBBLES = DMEM_ADDR_WIDTH/4;

  logic       qspi_clk;
  logic       qspi_cs_n;
  logic [3:0] qspi_data;

  logic       init_done;
  logic       cmd_done;
  logic       addr_done;
  logic       dummy_done;
  logic       rx_done;
  logic       tx_done;

  reg [3:0]   count;

  // PMOD TXN packet definition
  typedef struct packed {
    logic       sck;  // clk
    logic [2:0] cs;   // cs[2] = RAM B, cd[1] = RAM A, cs[0] = FLASH (IMEM)
    logic [3:0] sd;   // 4 data lines
  } qspi_pmod_t;
  qspi_pmod_t  qspi_pmod_txn;

  // Assign uio outputs
  assign uio_out[7] = qspi_pmod_txn.cs[2];
  assign uio_out[6] = qspi_pmod_txn.cs[1];
  assign uio_out[5] = qspi_pmod_txn.sd[3];
  assign uio_out[4] = qspi_pmod_txn.sd[2];
  assign uio_out[3] = qspi_pmod_txn.sck;
  assign uio_out[2] = qspi_pmod_txn.sd[1];
  assign uio_out[1] = qspi_pmod_txn.sd[0];
  assign uio_out[0] = qspi_pmod_txn.cs[0];

  // QSPI TXN Types
  typedef enum logic [1:0] {
    XACT_IFETCH, // instruction fetch req
    XACT_DREAD,  // data load req
    XACT_DWRITE  // data store req
  } xact_t;

  // QSPI REQ packet definition
  typedef struct packed {
    xact_t                    xact;       // Type of txn
    reg [IMEM_ADDR_WIDTH-1:0] imem_addr;  // Imemory address
    reg [DMEM_ADDR_WIDTH-1:0] dmem_addr;  // Dmemory address
    reg [XLEN-1:0]            data;       // input data
    reg [7:0]                 cmd;        // CMD Byte
  } qspi_req_t;
  qspi_req_t req_q;

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

  // Register TXN REQ when we go to CMD phase
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      req_q <= '0;
    end else begin
      if (next_state == CMD) begin
        if (ifetch_req_in) begin
          req_q.xact      <= XACT_IFETCH;
          req_q.imem_addr <= ifetch_addr_in;
          req_q.dmem_addr <= '0;
          req_q.data      <= '0;
          req_q.cmd       <= IFETCH_CMD;
        end
        else if (dmem_req_in && dmem_we_in) begin
          req_q.xact      <= XACT_DWRITE;
          req_q.imem_addr <= '0;
          req_q.dmem_addr <= dmem_addr_in;
          req_q.data      <= dmem_data_in;
          req_q.cmd       <= DWRITE_CMD;
        end
        else if (dmem_req_in && !dmem_we_in) begin
          req_q.xact      <= XACT_DREAD;
          req_q.imem_addr <= '0;
          req_q.dmem_addr <= dmem_addr_in;
          req_q.data      <= '0;
          req_q.cmd       <= DREAD_CMD;
        end
      end
    end
  end

  // Outputs
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      qspi_pmod_txn <= 0;
      count <= 0;
      cmd_done <= 0;
      addr_done <= 0;
    end else begin
      case (next_state)
      IDLE: begin
        qspi_pmod_txn <= 0;
        count <= 0;
        cmd_done <=0;
        addr_done <= 0;
      end
      CMD: begin
        // Output upper cmd byte
        if (count == 0)  begin
          qspi_pmod_txn.sd <= req_q.cmd[7:4];
          count <= count + 1;
        end
        // Output lower cmd byte
        if (count == 1)  begin
          qspi_pmod_txn.sd <= req_q.cmd[3:0];
          count <= 0;
          cmd_done <=1;
        end
      end
      ADDR: begin
        // If IFETCH req
        if (req_q.xact == XACT_IFETCH) begin

          qspi_pmod_txn.sd <= req_q.imem_addr[IMEM_ADDR_WIDTH-1-4*count-:4];

          if (count == 4'(IMEM_ADDR_NIBBLES - 1))  begin
            count <= 0;
            addr_done <= 1;
          end
        end

        // If DMEM req
        else if ((req_q.xact == XACT_DREAD) || (req_q.xact == XACT_DWRITE)) begin

          qspi_pmod_txn.sd <= req_q.dmem_addr[DMEM_ADDR_WIDTH-1-4*count-:4];

          if (count == 4'(DMEM_ADDR_NIBBLES - 1))  begin
            count <= 0;
            addr_done <= 1;
          end
        end
      end
      default: qspi_pmod_txn <=0;
      endcase
    end
  end


endmodule : qspi_controller
