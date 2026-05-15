// Formal verification module for simple_alu.
// All ports are inputs - this module only observes DUT signals, never drives them.
// Instantiated via simple_alu_top_fv.sv wrapper (bind unsupported in open-source Yosys).
module simple_alu_fv (
    input logic        clk,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic        sel,
    input logic        rst,

    input logic [31:0] y,
    input logic        overflow
  );

    // -------------------------------------------------------------------------
    // Initial assumptions - constrain starting state so solver doesn't
    // explore garbage initial register values
    // -------------------------------------------------------------------------
    initial assume(~rst);
    initial assume(y == '0);
    initial assume(overflow == 1'b0);

    //assertion check: if rst deasserted, y tied to 0
    //assertions are what we want to prove, formal verification is the engine that proves it
    // property p_rst_y;          
    //     @(posedge clk)
    //     ~rst |=> (y=='0);      
    // endproperty
    // a_rst_y: assert property (p_rst_y)
    //     else $error("RESET CHECK FAILED: rst=%0b y=%0h, expected y=0", rst, y);

    // Reset check - y must be 0 one cycle after reset asserts (active low)
    always @(posedge clk) begin
        if ( $past(~rst)) begin
            assert (y == '0);
            assert (overflow == 0);
        end
    end

    // -------------------------------------------------------------------------
    // Cover statements - solver finds shortest path to reach each state
    // These generate VCD traces you can inspect in GTKWave
    // -------------------------------------------------------------------------

    always @(posedge clk) begin      
        cover ($past(sel == 0) && overflow == 1'b1);  // addition overflow
        cover ($past(sel == 1) && overflow == 1'b1);  // subtraction underflow  
    end


endmodule
