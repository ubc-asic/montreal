module alu
  import montreal_pkg::*;
#(
  parameter int unsigned XLEN        = config_pkg::XLEN,
  parameter int unsigned SLICE_WIDTH = config_pkg::SLICE_WIDTH,

  localparam int unsigned SLICE_ADDR_WIDTH = $clog2(XLEN / SLICE_WIDTH)
) (
  input logic   clk_i,
  input logic   rst_ni,
  input fu_op_t alu_op_i,

  input logic [SLICE_ADDR_WIDTH-1:0] count_i,

  input slice_t a_i,
  input slice_t b_i,

  output slice_t result_o,
  output logic   carry_o
);

  logic negate_b;

  /* We used Karnaugh maps here. If the encoding for fu_op_t changes, this has to be updated. */
  assign negate_b = alu_op_i[3] || (!alu_op_i[2] && alu_op_i[1]);

  /* Carry signals. */
  logic carry, carry_d, carry_q;

  /* Adder width is SLICE_WIDTH + 1 to account for carry-out. */
  logic [SLICE_WIDTH:0] adder_a, adder_b, adder_result;

  /* For the first slice, carry-in must be driven to zero for addition 
   * and one for subtraction or comparisons. All other slices use the 
   * carry-out from the previous slice */

  assign carry   = (count_i == '0) ? negate_b : carry_q;

  /* ADD, SUB, SLT, SLTU use the same adder to computer their results*/
  
  assign adder_a = {1'b0, a_i};
  assign adder_b = {1'b0, (b_i ^ {SLICE_WIDTH{negate_b}})};
  assign adder_result = adder_a + adder_b + (SLICE_WIDTH + 1)'(carry);
  assign carry_o = adder_result[SLICE_WIDTH];
  assign carry_d = carry_o;

  /* Combinational arithmetic/logic core. */
  always_comb begin : alu_core
    result_o = '0;

    unique casez (alu_op_i[2:0])
      /* ADD, SUB, SLT, SLTU. */
      3'b0??: begin
        result_o = adder_result[SLICE_WIDTH-1:0];
      end
      /* XOR. */
      3'b100: begin end
      /* OR. */
      3'b110: begin end
      /* AND. */
      3'b111: begin end
      default: begin end
    endcase
  end : alu_core

  always_ff @(posedge clk_i) begin : carry_ff
    if (!rst_ni) begin
      carry_q <= '0;
    end else begin
      carry_q <= carry_d;
    end
  end : carry_ff

endmodule : alu
