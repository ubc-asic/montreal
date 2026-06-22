/* Testbench for ALU ADD and SUB operations.
 *
 * Functional requirements verified:
 *   FR-ALU-ADD-010 to FR-ALU-ADD-040
 *   FR-ALU-SUB-010 to FR-ALU-SUB-040
 *   FR-ALU-CMN-010 to FR-ALU-CMN-020
 */

module alu_add_sub_tb;
  import montreal_pkg::*;

  logic     clk_i;
  logic     rst_ni;
  fu_op_t   alu_op_i;
  logic [1:0] count_i;
  slice_t   a_i, b_i;
  slice_t   result_o;
  logic     carry_o;

  alu dut (
    .clk_i    (clk_i),
    .rst_ni   (rst_ni),
    .alu_op_i (alu_op_i),
    .count_i  (count_i),
    .a_i      (a_i),
    .b_i      (b_i),
    .result_o (result_o),
    .carry_o  (carry_o)
  );

  /* 10ns clock period. */
  initial clk_i = 0;
  always #5 clk_i = ~clk_i;

  int pass_count;
  int fail_count;

  /* Run one 32-bit ADD or SUB operation across 4 slices.
   * Inputs are presented on negedge so they are stable at the following posedge,
   * where carry_q updates. Result is sampled before the posedge. */
  task automatic run_op(
    input  fu_op_t      op,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result,
    output logic        final_carry
  );
    for (int i = 0; i < 4; i++) begin
      @(negedge clk_i);
      alu_op_i = op;
      count_i  = i[1:0];
      a_i      = a[i*8 +: 8];
      b_i      = b[i*8 +: 8];

      #1; /* Wait for combinational outputs to settle. */
      result[i*8 +: 8] = result_o;
      if (i == 3) final_carry = carry_o;

      @(posedge clk_i); /* Clock edge registers carry_d into carry_q for next slice. */
    end
  endtask

  /* Check result and print pass/fail. */
  task automatic check(
    input string       name,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] got,
    input logic [31:0] expected
  );
    if (got === expected) begin
      $display("  PASS  %s: %h op %h = %h", name, a, b, got);
      pass_count++;
    end else begin
      $display("  FAIL  %s: %h op %h = %h (expected %h)", name, a, b, got, expected);
      fail_count++;
    end
  endtask

  task automatic check_carry(
    input string name,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic        got,
    input logic        expected
  );
    if (got === expected) begin
      $display("  PASS  %s carry: %h op %h -> carry_o = %b", name, a, b, got);
      pass_count++;
    end else begin
      $display("  FAIL  %s carry: %h op %h -> carry_o = %b (expected %b)",
               name, a, b, got, expected);
      fail_count++;
    end
  endtask

  task automatic test_add(input logic [31:0] a, input logic [31:0] b);
    logic [31:0] result;
    logic        final_carry;
    run_op(ADD, a, b, result, final_carry);
    check("ADD", a, b, result, a + b);
  endtask

  task automatic test_sub(input logic [31:0] a, input logic [31:0] b);
    logic [31:0] result;
    logic        final_carry;
    run_op(SUB, a, b, result, final_carry);
    check("SUB", a, b, result, a - b);
  endtask

  task automatic test_add_carry(
    input logic [31:0] a, input logic [31:0] b, input logic expected_carry
  );
    logic [31:0] result;
    logic        final_carry;
    run_op(ADD, a, b, result, final_carry);
    check("ADD", a, b, result, a + b);
    check_carry("ADD", a, b, final_carry, expected_carry);
  endtask

  task automatic test_sub_carry(
    input logic [31:0] a, input logic [31:0] b, input logic expected_carry
  );
    logic [31:0] result;
    logic        final_carry;
    run_op(SUB, a, b, result, final_carry);
    check("SUB", a, b, result, a - b);
    check_carry("SUB", a, b, final_carry, expected_carry);
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;

    /* FR-ALU-CMN-020: reset clears carry_q. */
    rst_ni   = 0;
    alu_op_i = ADD;
    count_i  = 0;
    a_i      = 0;
    b_i      = 0;
    @(posedge clk_i);
    @(posedge clk_i);
    rst_ni = 1;

    $display("=== ADD tests ===");

    /* FR-ALU-ADD-010/020: basic add, no carry. */
    test_add(32'h0000_0001, 32'h0000_0001);  // 1 + 1 = 2

    /* FR-ALU-ADD-030: carry propagates from slice 0 to slice 1. */
    test_add(32'h0000_00FF, 32'h0000_0001);  // 255 + 1 = 256

    /* FR-ALU-ADD-030: carry propagates across all 4 slices. */
    test_add(32'hFFFF_FFFF, 32'h0000_0001);  // -1 + 1 = 0 (wraps)

    /* FR-ALU-ADD-040: carry-out on final slice (overflow cases). */
    test_add_carry(32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1);  // max + max → overflow
    test_add_carry(32'hFFFF_FFFF, 32'h0000_0001, 1'b1);  // -1 + 1 = 0 → overflow
    test_add_carry(32'h0000_0001, 32'h0000_0001, 1'b0);  // no overflow

    /* FR-ALU-CMN-010: multi-byte result assembled correctly. */
    test_add(32'h1234_5678, 32'h8765_4321);  // mixed bytes

    test_add(32'h0000_0000, 32'h0000_0000);  // 0 + 0 = 0

    $display("\n=== SUB tests ===");

    /* FR-ALU-SUB-010/020: basic sub, no borrow. */
    test_sub(32'h0000_0005, 32'h0000_0003);  // 5 - 3 = 2

    /* FR-ALU-SUB-030: borrow propagates from slice 0 to slice 1. */
    test_sub(32'h0000_0100, 32'h0000_0001);  // 256 - 1 = 255

    /* FR-ALU-SUB-030: borrow propagates across all 4 slices. */
    test_sub_carry(32'h0000_0000, 32'h0000_0001, 1'b0);  // 0 - 1 wraps, carry_o = 0 (borrow)
    test_sub_carry(32'h0000_0005, 32'h0000_0003, 1'b1);  // 5 - 3, no borrow → carry_o = 1

    /* FR-ALU-CMN-010: multi-byte result assembled correctly. */
    test_sub(32'hFFFF_FFFF, 32'h0000_0001);  // max - 1

    test_sub(32'h0000_0000, 32'h0000_0000);  // 0 - 0 = 0

    $display("\n=== Results: %0d passed, %0d failed ===", pass_count, fail_count);

    $finish;
  end

endmodule : alu_add_sub_tb
