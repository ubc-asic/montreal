// Wrapper top module for formal verification of simple_alu.
// Instantiates the DUT and the checker side-by-side so the formal tool
// sees both. Used because open-source Yosys does not support bind.
// Note: only DUT ports are accessible here - internal signals (sum, diff)
// cannot be tapped without bind or Verific.
module simple_alu_top_fv (
    input logic        clk,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic        sel,
    input logic        rst
);
    logic [31:0] y;
    logic        overflow;

    // DUT instance
    simple_alu dut (.*);

    // Checker instance - observes DUT outputs
    simple_alu_fv u_checker (
        .clk      (clk),
        .a        (a),
        .b        (b),
        .sel      (sel),
        .rst      (rst),
        .y        (y),
        .overflow (overflow)
    );
endmodule
