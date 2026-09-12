module io_bus_interconnect (
  /* Generic signals. */
  input logic clk_i,
  input logic rst_ni,

  /* Core-facing port. */
  input  io_bus_req_t  core_req_i,
  output io_bus_resp_t core_resp_o,

  /* Fan-out to QSPI controller. */
  output io_bus_req_t  qspi_req_o,
  input  io_bus_resp_t qspi_resp_i,

  /* Fan-out to UART controller. */
  output io_bus_req_t  uart_req_o,
  input  io_bus_resp_t uart_resp_i,

  /* Fan-out to common regbank. */
  output io_bus_req_t  regbank_req_o,
  input  io_bus_resp_t regbank_resp_i
);

endmodule : io_bus_interconnect
