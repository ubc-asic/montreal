`timescale 1ns / 1ps

`include "types.svh"

module fu_tb;

  initial $timeformat(-9, 0, "ns", 10);

  int num, err;

  logic clk, rst_n, valid, ready;
  logic [1:0] rslice, wslice;
  logic [2:0] cycle;
  fu_op_t fu_op;
  slice_t opa, opb, result;
  word_t a, b, out, expected;

  fu #(
    .XLEN       (32),
    .SLICE_WIDTH(8)
  ) dut (
    .clk_i (clk),
    .rst_ni(rst_n),

    .valid_i(valid),
    .ready_o(ready),

    .cycle_i(cycle),

    .fu_op_i(fu_op),

    .a_i(opa),
    .b_i(opb),

    .result_o(result),

    .rslice_o(rslice),
    .wslice_o(wslice)
  );

  always #5 clk = ~clk;

  always begin
    @(posedge clk);
    if (ready) cycle = 0;
    else cycle++;
  end

  always_comb begin
    unique case (rslice)
      0: begin
        opa = a[7:0];
        opb = b[7:0];
      end
      1: begin
        opa = a[15:8];
        opb = b[15:8];
      end
      2: begin
        opa = a[23:16];
        opb = b[23:16];
      end
      3: begin
        opa = a[31:24];
        opb = b[31:24];
      end
      default: begin end
    endcase
  end

  always_ff @(posedge clk) begin
    /* verilog_lint: waive-start dff-name-style */
    if (!rst_n) out <= '0;
    else begin
      unique case (wslice)
        0: out[7:0]   <= result;
        1: out[15:8]  <= result;
        2: out[23:16] <= result;
        3: out[31:24] <= result;
        default: begin end
      endcase
    end
    /* verilog_lint: waive-stop dff-name-style */
  end

  task automatic check (
    input logic [31:0] expected = 'z
  );

    if ($isunknown(expected)) begin
      unique case (fu_op)
        ADD:     expected = a + b;
        SUB:     expected = a - b;
        XOR:     expected = a ^ b;
        OR:      expected = a | b;
        AND:     expected = a & b;
        SLT:     expected = $signed(a) < $signed(b);
        SLTU:    expected = $unsigned(a) < $unsigned(b);
        SLL:     expected = a << b[5:0];
        SRL:     expected = a >> b[5:0];
        SRA:     expected = $signed(a) >>> b[5:0];
        default: expected = 'z;
      endcase
    end

    valid = '1;

    @(posedge clk && ready) valid = '0;

    @(posedge ready);

    num++;

    assert (out == expected) begin
      $display("INFO: %0t: test %0d passed (fu_op = %s, a = %h, b = %h)",
          $time, num, fu_op, a, b);
    end else begin
      err++;
      $display("ERROR: %0t: test %0d failed (fu_op = %s, a = %h, b = %h)",
          $time, num, fu_op, a, b);
      $display("ERROR: %0t: output is %h (%b) but target is %h (%b)",
          $time, out, out, expected, expected);
    end

  endtask : check

  initial begin

    automatic fu_op_t alu_ops[$]   = '{ADD, SUB, XOR, OR, AND, SLT, SLTU};
    automatic fu_op_t shift_ops[$] = '{SLL, SRL, SRA};

    num = 0;
    err = 0;

    clk   = '0;
    rst_n = '0;

    @(posedge clk) @(posedge clk) rst_n = '1;

    $display();
    $display("Starting tests");
    $display("==============");

    /* Trivial and edge cases. */

    fu_op = ADD;

    /* ADD: maximum positive PLUS 1 (signed overflow, wraps to negative). */
    a = 32'h7f_ff_ff_ff;
    b = 32'h00_00_00_01;
    check(32'h80_00_00_00);

    /* ADD: minimum negative PLUS -1 (signed overflow, wraps to positive). */
    a = 32'h80_00_00_00;
    b = 32'hff_ff_ff_ff;
    check(32'h7f_ff_ff_ff);

    /* ADD: minimum negative PLUS minimum negative
     * (signed and unsigned overflow together, wraps to 0). */
    a = 32'h80_00_00_00;
    b = 32'h80_00_00_00;
    check(32'h00_00_00_00);

    /* ADD: 0 PLUS 0 (trivial case, always zero). */
    a = 32'h00_00_00_00;
    b = 32'h00_00_00_00;
    check(32'h00_00_00_00);

    fu_op = SUB;

    /* SUB: maximum positive MINUS -1 (signed overflow, wraps to positive). */
    a = 32'h7f_ff_ff_ff;
    b = 32'hff_ff_ff_ff;
    check(32'h80_00_00_00);

    /* SUB: minimum negative MINUS 1 (signed overflow, wraps to negative). */
    a = 32'h80_00_00_00;
    b = 32'h00_00_00_01;
    check(32'h7f_ff_ff_ff);

    /* SUB: 0 MINUS 1 (underflow, wraps to maximum unsigned value). */
    a = 32'h00_00_00_00;
    b = 32'h00_00_00_01;
    check(32'hff_ff_ff_ff);

    /* SUB: 0 MINUS minimum negative (no positive two's complement
     * to -2^31 exists, wraps to B). */
    a = 32'h00_00_00_00;
    b = 32'h80_00_00_00;
    check(32'h80_00_00_00);

    /* SUB: A MINUS A (always zero). */
    a = 32'ha5_a5_a5_a5;
    b = 32'ha5_a5_a5_a5;
    check(32'h00_00_00_00);

    /* SUB: 0 MINUS 0 (trivial case, always zero). */
    a = 32'h00_00_00_00;
    b = 32'h00_00_00_00;
    check(32'h00_00_00_00);

    fu_op = XOR;

    /* XOR: A XOR A (results in all zeroes). */
    a = 32'hff_ff_ff_ff;
    b = 32'hff_ff_ff_ff;
    check(32'h00_00_00_00);

    /* XOR: complementary bit patterns (results in all ones). */
    a = 32'ha5_a5_a5_a5;
    b = 32'h5a_5a_5a_5a;
    check(32'hff_ff_ff_ff);

    /* XOR: A XOR 0 (identity, result is A). */
    a = 32'ha5_a5_a5_a5;
    b = 32'h00_00_00_00;
    check(32'ha5_a5_a5_a5);

    /* XOR: A XOR all ones (result is bitwise complement of A). */
    a = 32'ha5_a5_a5_a5;
    b = 32'hff_ff_ff_ff;
    check(32'h5a_5a_5a_5a);

    fu_op = OR;

    /* OR: 0 OR 0 (results in all zeroes). */
    a = 32'h00_00_00_00;
    b = 32'h00_00_00_00;
    check(32'h00_00_00_00);

    /* OR: all ones OR 0 (results in all ones). */
    a = 32'hff_ff_ff_ff;
    b = 32'h00_00_00_00;
    check(32'hff_ff_ff_ff);

    /* OR: complementary nibble patterns (results in all ones). */
    a = 32'hf0_f0_f0_f0;
    b = 32'h0f_0f_0f_0f;
    check(32'hff_ff_ff_ff);

    /* OR: complementary bit patterns (results in all ones). */
    a = 32'ha5_a5_a5_a5;
    b = 32'h5a_5a_5a_5a;
    check(32'hff_ff_ff_ff);

    /* OR: A OR A (identity, result is A). */
    a = 32'ha5_a5_a5_a5;
    b = 32'ha5_a5_a5_a5;
    check(32'ha5_a5_a5_a5);

    fu_op = AND;

    /* AND: all ones AND all ones (results in all ones). */
    a = 32'hff_ff_ff_ff;
    b = 32'hff_ff_ff_ff;
    check(32'hff_ff_ff_ff);

    /* AND: all ones AND 0 (results in all zeroes). */
    a = 32'hff_ff_ff_ff;
    b = 32'h00_00_00_00;
    check(32'h00_00_00_00);

    /* AND: complementary nibble patterns (results in all zeroes). */
    a = 32'hf0_f0_f0_f0;
    b = 32'h0f_0f_0f_0f;
    check(32'h00_00_00_00);

    /* AND: complementary bit patterns (results in all zeroes). */
    a = 32'ha5_a5_a5_a5;
    b = 32'h5a_5a_5a_5a;
    check(32'h00_00_00_00);

    /* AND: A AND A (identity, result is A). */
    a = 32'ha5_a5_a5_a5;
    b = 32'ha5_a5_a5_a5;
    check(32'ha5_a5_a5_a5);

    fu_op = SLT;

    /* SLT: minimum negative versus maximum positive (A < B, result is 1). */
    a = 32'h80_00_00_00;
    b = 32'h7f_ff_ff_ff;
    check(32'h00_00_00_01);

    /* SLT: maximum positive versus minimum negative (A > B, result is 0). */
    a = 32'h7f_ff_ff_ff;
    b = 32'h80_00_00_00;
    check(32'h00_00_00_00);

    /* SLT: -1 versus 0 (A < B, result is 1). */
    a = 32'hff_ff_ff_ff;
    b = 32'h00_00_00_00;
    check(32'h00_00_00_01);

    /* SLT: A versus A (equal, result is 0). */
    a = 32'ha5_a5_a5_a5;
    b = 32'ha5_a5_a5_a5;
    check(32'h00_00_00_00);

    /* SLT: 0 versus 0 (equal, result is 0). */
    a = 32'h00_00_00_00;
    b = 32'h00_00_00_00;
    check(32'h00_00_00_00);

    fu_op = SLTU;

    /* SLTU: minimum negative versus maximum positive, unsigned (A > B, result is 0). */
    a = 32'h80_00_00_00;
    b = 32'h7f_ff_ff_ff;
    check(32'h00_00_00_00);

    /* SLTU: 0 versus maximum unsigned (A < B, result is 1). */
    a = 32'h00_00_00_00;
    b = 32'hff_ff_ff_ff;
    check(32'h00_00_00_01);

    /* SLTU: maximum unsigned versus 0 (A > B, result is 0). */
    a = 32'hff_ff_ff_ff;
    b = 32'h00_00_00_00;
    check(32'h00_00_00_00);

    /* SLTU: A versus A (equal, result is 0). */
    a = 32'ha5_a5_a5_a5;
    b = 32'ha5_a5_a5_a5;
    check(32'h00_00_00_00);

    /* SLTU: 0 versus 0 (equal, result is 0). */
    a = 32'h00_00_00_00;
    b = 32'h00_00_00_00;
    check(32'h00_00_00_00);

    /* Randomised test cases. */

    foreach (alu_ops[i]) begin
      fu_op = alu_ops[i];

      for (int i = 0; i < 16; i++) begin
        a = signed'($urandom);
        b = signed'($urandom);
        check();
      end
    end

    foreach (shift_ops[i]) begin
      fu_op = shift_ops[i];
      for (b = 0; b < 16; b++) begin
        a = 32'b1100_1010_1110_1101_1011_0111_0101_0011;
        check();

        a = 32'b0011_0101_0001_0010_0100_1000_1010_1100;
        check();
      end
    end

    $display();
    $display("Test summary");
    $display("============");

    $display("%0d out of %0d tests passed", num - err, num);
    if (err == 0) $display("All tests have passed");
    $display();

    @(posedge clk) $finish;

  end

endmodule : fu_tb
