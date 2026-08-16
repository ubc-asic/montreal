`timescale 1ns / 1ps

/*
 * Copyright 2026 Project Montreal contributors.
 *
 * SPDX-License-Identifier: CERN-OHL-P-2.0
 *
 * Project:      Montreal (RV32E SoC for Tiny Tapeout)
 *
 * Module:       shifter_tb
 * Tool version: Vivado 2025.2
 * Authors:      Warrick Lo <wlo@warricklo.net>
 *
 * Description:  Testbench for the shifter
 */

`include "types.svh"

module shifter_tb;

  initial $timeformat(-9, 0, "ns", 10);

  int num, err;

  logic clk, rst_n, shift_type, shift_arithmetic;
  logic [1:0] cycle, rslice, wslice;
  logic [4:0] shamt;
  logic [7:0] data, result;
  logic [31:0] in, out, expected;
  fu_op_t fu_op;

  shifter #(
    .XLEN       (32),
    .SLICE_WIDTH(8)
  ) dut (
    .clk_i (clk),
    .rst_ni(rst_n),

    .cycle_i(cycle),

    .shift_type_i      (shift_type),
    .shift_arithmetic_i(shift_arithmetic),
    .shamt_i           (shamt),

    .data_i  (data),
    .result_o(result),

    .rslice_o(rslice),
    .wslice_o(wslice)
  );

  always #5 clk = ~clk;

  always_comb begin
    unique case (rslice)
      0: data = in[7:0];
      1: data = in[15:8];
      2: data = in[23:16];
      3: data = in[31:24];
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

  task automatic check;

    unique case (fu_op)
      SLL: begin
        shift_type       = '0;
        shift_arithmetic = '0;
        expected         = $unsigned(in) << shamt;
      end
      SRL: begin
        shift_type       = '1;
        shift_arithmetic = '0;
        expected         = $unsigned(in) >> shamt;
      end
      SRA: begin
        shift_type       = '1;
        shift_arithmetic = '1;
        expected         = $signed(in) >>> shamt;
      end
      default: begin
        shift_type       = 'z;
        shift_arithmetic = 'z;
        expected         = 'z;
      end
    endcase

    @(posedge clk) cycle = 0;
    @(posedge clk) cycle = 1;
    @(posedge clk) cycle = 2;
    @(posedge clk) cycle = 3;

    @(posedge clk) @(posedge clk);

    num++;

    assert (out == expected) begin
      $display("INFO: %0t: test %0d passed (fu_op = %s, shamt = %0d, in = %h)",
          $time, num, fu_op, shamt, in);
    end else begin
      err++;
      $display("ERROR: %0t: test %0d failed (fu_op = %s, shamt = %0d, in = %h)",
          $time, num, fu_op, shamt, in);
      $display("ERROR: %0t: output is %h (%b) but target is %h (%b)",
          $time, out, out, expected, expected);
    end

  endtask : check

  initial begin : test

    automatic fu_op_t shift_ops[$] = '{SLL, SRL, SRA};

    num = 0;
    err = 0;

    clk   = '0;
    rst_n = '0;

    @(posedge clk) rst_n = '1;

    $display();
    $display("Starting tests");
    $display("==============");

    foreach (shift_ops[i]) begin
      fu_op = shift_ops[i];
      for (shamt = 0; shamt < 16; shamt++) begin
        in = 32'b1100_1010_1110_1101_1011_0111_0101_0011;
        check();

        in = 32'b0011_0101_0001_0010_0100_1000_1010_1100;
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

  end : test

endmodule : shifter_tb
