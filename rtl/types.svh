`ifndef TYPES_SVH
`define TYPES_SVH

typedef logic                                        [config_pkg::XLEN-1:0] word_t;
typedef logic [2 ** config_pkg::REG_ADDR_WIDTH - 1:0][config_pkg::XLEN-1:0] word_bank_t;

typedef logic [config_pkg::SLICE_WIDTH-1:0] slice_t;

`endif /* TYPES_SVH */
