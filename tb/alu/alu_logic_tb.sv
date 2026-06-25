/* Testbench for ALU XOR, OR, AND operations.
 *
 * Logical operations are purely combinational per slice — no carry propagation.
 * carry_o is NOT valid for logical operations and MUST NOT be used by the
 * caller. It is not checked in this testbench.
 */

module alu_logic_tb;
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

  initial clk_i = 0;
  always #5 clk_i = ~clk_i;

  int pass_count;
  int fail_count;

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

      #1;
      result[i*8 +: 8] = result_o;
      if (i == 3) final_carry = carry_o;

      @(posedge clk_i);
    end
  endtask

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

  task automatic test_xor(input logic [31:0] a, input logic [31:0] b);
    logic [31:0] result;
    logic        final_carry;
    run_op(XOR, a, b, result, final_carry);
    check("XOR", a, b, result, a ^ b);
  endtask

  task automatic test_or(input logic [31:0] a, input logic [31:0] b);
    logic [31:0] result;
    logic        final_carry;
    run_op(OR, a, b, result, final_carry);
    check("OR", a, b, result, a | b);
  endtask

  task automatic test_and(input logic [31:0] a, input logic [31:0] b);
    logic [31:0] result;
    logic        final_carry;
    run_op(AND, a, b, result, final_carry);
    check("AND", a, b, result, a & b);
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;

    rst_ni   = 0;
    alu_op_i = XOR;
    count_i  = 0;
    a_i      = 0;
    b_i      = 0;
    @(posedge clk_i);
    @(posedge clk_i);
    rst_ni = 1;

    $display("=== XOR tests ===");
    test_xor(32'hFFFF_FFFF, 32'hFFFF_FFFF);  // all 1s XOR all 1s = 0
    test_xor(32'hFFFF_FFFF, 32'h0000_0000);  // all 1s XOR 0 = all 1s
    test_xor(32'hAAAA_AAAA, 32'h5555_5555);  // alternating bits
    test_xor(32'h1234_5678, 32'h8765_4321);  // mixed
    test_xor(32'h0000_0000, 32'h0000_0000);  // 0 XOR 0 = 0

    $display("\n=== OR tests ===");
    test_or(32'hFFFF_FFFF, 32'h0000_0000);   // all 1s OR 0 = all 1s
    test_or(32'h0000_0000, 32'h0000_0000);   // 0 OR 0 = 0
    test_or(32'hAAAA_AAAA, 32'h5555_5555);   // alternating → all 1s
    test_or(32'h1234_5678, 32'h8765_4321);   // mixed
    test_or(32'hFFFF_FFFF, 32'hFFFF_FFFF);   // all 1s OR all 1s = all 1s

    $display("\n=== AND tests ===");
    test_and(32'hFFFF_FFFF, 32'hFFFF_FFFF);  // all 1s AND all 1s = all 1s
    test_and(32'hFFFF_FFFF, 32'h0000_0000);  // all 1s AND 0 = 0
    test_and(32'hAAAA_AAAA, 32'h5555_5555);  // alternating → 0
    test_and(32'h1234_5678, 32'h8765_4321);  // mixed
    test_and(32'h0000_0000, 32'h0000_0000);  // 0 AND 0 = 0

    $display("\n=== Results: %0d passed, %0d failed ===", pass_count, fail_count);

    $finish;
  end

endmodule : alu_logic_tb
