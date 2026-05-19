// Wrapper top module for formal verification of simple_alu.
// Instantiates the DUT and the checker side-by-side so the formal tool
// sees both. Used because open-source Yosys does not support bind.
// Note: only DUT ports are accessible here - internal signals (sum, diff)
// cannot be tapped without bind or Verific.
module simple_alu_top_fv (
    input logic        clk_i,
    input logic [31:0] a_i,
    input logic [31:0] b_i,
    input logic        sel_i,
    input logic        rst_ni
);
    logic [31:0] y;
    logic        overflow;

    // DUT instance
    simple_alu dut (
        .clk_i      (clk_i),
        .a_i        (a_i),
        .b_i        (b_i),
        .sel_i      (sel_i),
        .rst_ni     (rst_ni),
        .y_o        (y),
        .overflow_o (overflow)
    );

    // Checker instance - observes DUT outputs
    simple_alu_fv u_checker (
        .clk_i      (clk_i),
        .a_i        (a_i),
        .b_i        (b_i),
        .sel_i      (sel_i),
        .rst_ni     (rst_ni),
        .y_i        (y),
        .overflow_i (overflow)
    );
endmodule
