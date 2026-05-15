// Simple 32-bit ALU supporting addition and subtraction (sel=0/1).
// Outputs are registered. Overflow/underflow detected via 33-bit extended arithmetic.
// Active-low synchronous reset. Used as a sandbox for formal verification.
module simple_alu (

    //inputs
    input logic        clk,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic        sel,         //sel = 0 -> ADD, sel = 1 -> SUB
    input logic        rst,         //active LOW sync reset

    //outputs
    output logic [31:0] y,
    output logic        overflow
);

    logic [32:0] sum;
    logic [32:0] diff;

    always_comb begin
        sum  = {1'b0, a} + {1'b0, b};
        diff = {1'b0, a} - {1'b0, b};
    end

    always_ff @(posedge clk) begin
    if (~rst) begin
        y <= '0;
        overflow <= '0;
    end
    else begin
        case (sel)
        0:  begin
                y <= sum[31:0];
                overflow <= sum[32];
        end
        1:  begin
                y <= diff[31:0];
                overflow <= diff[32];
        end
        endcase
    end
    end
endmodule
