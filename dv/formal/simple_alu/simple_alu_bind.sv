// Bind file for simple_alu formal verification.
// Attaches simple_alu_fv to every instance of simple_alu in the design.
// RTL is completely unaware of this file.
//
// bind <dut_module> <fv_module> <instance_name> (<port_connections>);

bind simple_alu simple_alu_fv u_simple_alu_fv (
    .clk      (clk),
    .rst      (rst),
    .a        (a),
    .b        (b),
    .sel      (sel),
    .y        (y),
    .overflow (overflow)
);
