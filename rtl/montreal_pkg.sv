/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

package montreal_pkg;

  typedef logic unsigned [config_pkg::XLEN-1:0]        word_t;
  typedef logic unsigned [config_pkg::SLICE_WIDTH-1:0] slice_t;

  typedef enum logic [3:0] {
    /* Arithmetic operations. */
    ADD       = 4'b0000,
    SUB       = 4'b1000,
    /* Logical operations. */
    XOR       = 4'b0100,
    OR        = 4'b0110,
    AND       = 4'b0111,
    /* Shift operations. */
    SLL       = 4'b0001,
    SRL       = 4'b0101,
    SRA       = 4'b1101,
    /* Conditional set operations. */
    SLT       = 4'b0010,
    SLTU      = 4'b0011,
    /* Zicond operations. */
    CZERO_EQZ = 4'b1001,
    CZERO_NEZ = 4'b1011
  } fu_op_t;

endpackage : montreal_pkg
