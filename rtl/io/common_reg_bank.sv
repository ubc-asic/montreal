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
