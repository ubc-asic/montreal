// Interface between core and QSPI pmod 
// https://onlinedocs.microchip.com/oxy/GUID-450989FA-38E4-4D68-AB61-15ADB29AD718-en-US-6/GUID-C2190631-B6F5-4CD7-B6DB-5267DC280E90_3.html

module qspi_controller (
    // Clock
    input  wire       clk,

    // Reset (active low)
    input  wire       rst_n,

    // Bi-directional I/O
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
);

    // ====================================
    //              Pin mapping
    // ====================================

    // QSPI Serial CLK

    // QSPI CS - Active Low

    // QSPI IO_0
    // QSPI IO_1
    // QSPI IO_2
    // QSPI IO_3


    logic       qspi_clk;
    logic       qspi_cs_n;
    logic [3:0] qspi_data;




endmodule
