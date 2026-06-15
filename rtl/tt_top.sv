/*
 * Copyright (c) 2026 UBC ASIC
 * SPDX-License-Identifier: Apache-2.0
 */

// Core wrapper + QSPI PMOD controller

`default_nettype none

module tt_top (
    /* verilog_lint: waive-start port-name-suffix */
    // Dedicated inputs
    input  wire [7:0] ui_in,

    // Dedicated outputs
    output wire [7:0] uo_out,

    // Bi-directional I/O
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)

    // Enable design
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it

    // Clock
    input  wire       clk,      // clock

    // Reset
    input  wire       rst_n     // reset_n - low to reset
    /* verilog_lint: waive-stop port-name-suffix */
);

    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
    assign uio_out = 0;
    assign uio_oe  = 0;

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, clk, rst_n, 1'b0};


    u_rv32e_core_wrapper rv32e_core_wrapper(

    );


    u_qspi_controller qspi_controller(
        // Clock
        .clk(),

        // Reset
        .rst_n(),

        // Bi-directional I/O
        .uio_in(),   // IOs: Input path
        .uio_out(),  // IOs: Output path
        .uio_oe(),   // IOs: Enable path (active high: 0=input, 1=output)
    );
endmodule
