// Formal verification module for simple_alu.
// All ports are inputs - this module only observes DUT signals, never drives them.
// Instantiated via simple_alu_top_fv.sv wrapper (bind unsupported in open-source Yosys).
module simple_alu_fv (
    input logic        clk_i,
    input logic [31:0] a_i,
    input logic [31:0] b_i,
    input logic        sel_i,
    input logic        rst_ni,

    input logic [31:0] y_i,
    input logic        overflow_i
  );

    // -------------------------------------------------------------------------
    // Initial assumptions - constrain starting state so solver doesn't
    // explore garbage initial register values
    // -------------------------------------------------------------------------
    initial assume (~rst_ni);
    initial assume (y_i == '0);
    initial assume (overflow_i == 1'b0);

    //assertion check: if rst deasserted, y tied to 0
    //assertions are what we want to prove, formal verification is the engine that proves it
    // property p_rst_y;
    //     @(posedge clk_i)
    //     ~rst_ni |=> (y_i=='0);
    // endproperty
    // a_rst_y: assert property (p_rst_y)
    //     else $error("RESET CHECK FAILED: rst_ni=%0b y_i=%0h, expected y=0", rst_ni, y_i);

    // Reset check - y must be 0 one cycle after reset asserts (active low)
    always @(posedge clk_i) begin
        if ($past(~rst_ni)) begin
            assert (y_i == '0);
            assert (overflow_i == 0);
        end
    end

    // -------------------------------------------------------------------------
    // Cover statements - solver finds shortest path to reach each state
    // These generate VCD traces you can inspect in GTKWave
    // -------------------------------------------------------------------------

    always @(posedge clk_i) begin
        cover ($past(sel_i == 0) && overflow_i == 1'b1);  // addition overflow
        cover ($past(sel_i == 1) && overflow_i == 1'b1);  // subtraction underflow
    end

endmodule
