// Simple 32-bit ALU supporting addition and subtraction (sel=0/1).
// Outputs are registered. Overflow/underflow detected via 33-bit extended arithmetic.
// Active-low synchronous reset. Used as a sandbox for formal verification.
module simple_alu (

    //inputs
    input logic        clk_i,
    input logic [31:0] a_i,
    input logic [31:0] b_i,
    input logic        sel_i,         //sel = 0 -> ADD, sel = 1 -> SUB
    input logic        rst_ni,        //active LOW sync reset

    //outputs
    output logic [31:0] y_o,
    output logic        overflow_o
);

    logic [32:0] sum;
    logic [32:0] diff;
    logic [31:0] y_r;
    logic        overflow_r;
    logic [31:0] y_next;
    logic        overflow_next;

    always_comb begin
        sum  = {1'b0, a_i} + {1'b0, b_i};
        diff = {1'b0, a_i} - {1'b0, b_i};

        y_next        = '0;
        overflow_next = '0;

        if (rst_ni) begin
            case (sel_i)
                0: begin
                    y_next        = sum[31:0];
                    overflow_next = sum[32];
                end
                1: begin
                    y_next        = diff[31:0];
                    overflow_next = diff[32];
                end
                default: begin
                    y_next        = '0;
                    overflow_next = '0;
                end
            endcase
        end
    end

    always_ff @(posedge clk_i) begin
        y_r        <= y_next;
        overflow_r <= overflow_next;
    end

    assign y_o        = y_r;
    assign overflow_o = overflow_r;

endmodule
