# QSPI Controller

> [!CAUTION]
> RTL IN PROGRESS. FSM SUBJECT TO CHANGE.

Source: [`rtl/io/qspi_controller.sv`](../rtl/io/qspi_controller.sv)

## Overview

`qspi_controller` is a dedicated FSM that serialises instruction fetch and
data memory accesses from the core datapath over a shared QSPI PMOD
interface (one FLASH device for IMEM, two RAM devices for DMEM). It exposes
a simple req/ack handshake to the core control unit and multiplexes both
memory ports onto a single physical QSPI bus, since only one transaction
can be in flight on the bus at a time.

## Pin mapping

| PMOD signal        | Direction | uio bit | Notes                          |
|---------------------|-----------|---------|---------------------------------|
| QSPI Serial CLK (`sck`) | out   | `uio_out[3]` |                              |
| QSPI CS FLASH (IMEM) (`cs[0]`) | out | `uio_out[0]` | Active low |
| QSPI CS RAM A (`cs[1]`)        | out | `uio_out[6]` | Active low |
| QSPI CS RAM B (`cs[2]`)        | out | `uio_out[7]` | Active low |
| QSPI IO_0 (`sd[0]`) | out (driven by controller during CMD/ADDR/TX) | `uio_out[1]` | |
| QSPI IO_1 (`sd[1]`) | out | `uio_out[2]` | |
| QSPI IO_2 (`sd[2]`) | out | `uio_out[4]` | |
| QSPI IO_3 (`sd[3]`) | out | `uio_out[5]` | |

Reference: [Microchip QSPI PMOD interface docs](https://onlinedocs.microchip.com/oxy/GUID-450989FA-38E4-4D68-AB61-15ADB29AD718-en-US-6/GUID-C2190631-B6F5-4CD7-B6DB-5267DC280E90_3.html).

`uio_oe` drive/direction control is TODO — not yet wired in the current RTL.

## Core-facing interface

### IMEM handshake

| Signal              | Dir | Width | Description |
|----------------------|-----|-------|--------------|
| `ifetch_req_in`      | in  | 1     | Instruction fetch request, asserted by the control unit's Instruction Fetch state. |
| `ifetch_addr_in`     | in  | `IMEM_ADDR_WIDTH` (24) | Instruction address to fetch. |
| `ifetch_done_out`    | out | 1     | Fetch complete / data valid. **Not yet driven in RTL.** |
| `ifetch_data_out`    | out | `XLEN` (32) | Fetched instruction word. **Not yet driven in RTL.** |

### DMEM handshake

| Signal              | Dir | Width | Description |
|----------------------|-----|-------|--------------|
| `funct3`             | in  | 3     | Load/store width qualifier from the core (byte/half/word). Not yet consumed in RTL. |
| `dmem_req_in`        | in  | 1     | Data memory request, asserted by the control unit's Memory Decode state for either a load or a store. |
| `dmem_we_in`         | in  | 1     | Write-enable: `1` = store (`DFETCH`... i.e. `DWRITE_REQ`), `0` = load (`DREAD_REQ`). |
| `dmem_data_in`       | in  | `XLEN` (32) | Store data. |
| `dmem_addr_in`       | in  | `DMEM_ADDR_WIDTH` (24) | Data memory address. |
| `dmem_done_out`      | out | 1     | Access complete / data valid. **Not yet driven in RTL.** |
| `dmem_data_out`      | out | `XLEN` (32) | Load data. **Not yet driven in RTL.** |

`ifetch_req_in`/`dmem_req_in` are expected to originate from the core
control unit's Instruction Fetch and Memory Decode states respectively
(`IFETCH_REQ`, `DFETCH_REQ`/`DWRITE_REQ` in the control-unit FSM — see
[Design requirements](#design-requirements)).

## Transaction (`xact_t`) types

| Enum          | Trigger                          | Command byte (`config_pkg`) |
|----------------|-----------------------------------|-------------------------------|
| `XACT_IFETCH`  | `ifetch_req_in`                   | `IFETCH_CMD` = `8'hEB` (quad I/O fast read) |
| `XACT_DREAD`   | `dmem_req_in && !dmem_we_in`      | `DREAD_CMD` = `8'h0B` (fast read) |
| `XACT_DWRITE`  | `dmem_req_in && dmem_we_in`       | `DWRITE_CMD` = `8'h38` (quad write) |

On entry to `CMD`, the request is latched into `req_q` (transaction type,
address, write data, command byte), giving the rest of the FSM a stable
view of the transaction for its duration.

## FSM

<img width="4000" height="400" alt="QSPI controller state diagram" src="https://github.com/user-attachments/assets/27f9ee8c-8647-4371-8bf8-e894aeb0907a" />

| State   | Purpose                                             | Advances to `next_state` when |
|---------|------------------------------------------------------|--------------------------------|
| `INIT`  | Power-on / reset init sequence for the QSPI device.   | `init_done` |
| `IDLE`  | Waiting for a request.                                | `ifetch_req_in \|\| dmem_req_in` → `CMD` |
| `CMD`   | Shifts out the 8-bit command byte, nibble at a time (2 cycles). | `cmd_done` → `ADDR` |
| `ADDR`  | Shifts out the address (IMEM or DMEM, depending on `req_q.xact`), nibble at a time. | `addr_done` → `DUMMY` |
| `DUMMY` | Dummy/turnaround cycles required by the flash/RAM device before data phase. | `dummy_done` → `RX` (ifetch or load) or `TX` (store) |
| `RX`    | Shifts in read data (ifetch or load).                 | `rx_done` → `DONE` |
| `TX`    | Shifts out write data (store).                        | `tx_done` → `DONE` |
| `DONE`  | Transaction complete; one-cycle pulse state.          | unconditional → `IDLE` |

Notes:
- State is `state_t` (`logic [2:0]`), registered on `posedge clk`, async
  reset to `INIT` on `!rst_n`.
- `req_q` is latched combinationally on `next_state == CMD`, so it is valid
  for the entire `CMD`→`DONE` sequence.
- `count` is a shared nibble/cycle counter reused across `CMD`/`ADDR` (and,
  once implemented, `DUMMY`/`RX`/`TX`).

## Design requirements

Requirements below apply to the **control unit** (the block driving
`ifetch_req_in` / `dmem_req_in` / `dmem_we_in`), not to `qspi_controller`
itself — they constrain the inputs this module can assume.

| ID | Requirement | Status |
|----|-------------|--------|
| `REQ.QSPI.DR.1` | `IFETCH_REQ` and either `DFETCH_REQ` or `DWRITE_REQ` must never be asserted by the control unit in the same cycle. `qspi_controller` does not arbitrate between them — `IDLE`'s `req_q` latch checks `ifetch_req_in` first, so a simultaneous assertion would silently drop the memory request rather than flag an error. | Open — see `TODO` at `rtl/io/qspi_controller.sv:33`; no error/assertion state exists yet in the FSM. |

## Open items

- `ifetch_done_out`, `ifetch_data_out`, `dmem_done_out`, `dmem_data_out` are
  declared but not yet driven — `RX`/`TX`/`DONE` output logic is
  unimplemented.
- `uio_oe` (I/O direction control) is unconnected; the bus direction
  turnaround for read vs. write phases still needs to be modeled.
- `INIT` sequencing (`init_done`) and `DUMMY` cycle count are not yet
  implemented.
- No error/protection state for the `REQ.QSPI.DR.1` violation case
  (simultaneous `ifetch_req_in` and `dmem_req_in`).
- `funct3` is accepted but unused — sub-word load/store handling (byte/half)
  is not yet implemented in the QSPI data phase.
