/* SPDX-License-Identifier: CERN-OHL-P-2.0 */

module regfile_check (
  input logic clk_i,
  input logic rst_ni,
  input logic [3:0] slice_sel_i,

  input logic [1:0][3:0] raddr_i,
  input logic [1:0][7:0] rdata_i,

  input logic wen_i,
  input logic [3:0] waddr_i,
  input logic [7:0] wdata_i
);

  initial assume (!rst_ni);
  initial assume (rdata_i == '0);

/* Symbiyosys does not support property. */
`ifndef SYMBIYOSYS

  assume property (@(posedge clk_i) raddr_i[0] == waddr_i);
  assume property (@(posedge clk_i) raddr_i[1] == waddr_i);
  assume property (@(posedge clk_i) waddr_i != '0);
  assume property (@(posedge clk_i) $stable(slice_sel_i));

  property ff_reset;
    @(posedge clk_i) disable iff (rst_ni)
      rdata_i == '0;
  endproperty : ff_reset

  property ff_store;
    @(posedge clk_i) disable iff (!rst_ni)
      (wen_i |=> rdata_i[0] == $past(wdata_i, 1))
      and
      (wen_i |=> rdata_i[1] == $past(wdata_i, 1));
  endproperty : ff_store

  assert property (ff_reset);
  assert property (ff_store);

  cover property (ff_reset);
  cover property (ff_store);

`else /* SYMBIYOSYS */

  always_comb begin
    assume property (raddr_i[0] == waddr_i);
    assume property (raddr_i[1] == waddr_i);
    assume property (waddr_i != '0);
  end

  always_ff @(posedge clk_i) begin
    assume property ($stable(slice_sel_i));
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      assert (rdata_i[0] == '0);
      assert (rdata_i[1] == '0);
    end else begin
      if ($past(wen_i, 1) && $past(rst_ni, 1)) begin
        assert (rdata_i[0] == $past(wdata_i, 1));
        assert (rdata_i[1] == $past(wdata_i, 1));
      end
    end
  end

`endif /* SYMBIYOSYS */

endmodule : regfile_check
