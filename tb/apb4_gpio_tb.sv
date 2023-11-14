`timescale 1ns / 1ps

module apb_archinfo_tb ();
  logic rst_n_i, clk_i;
  always #5.000 clk_i <= ~clk_i;  // 100MHz

  initial begin
    $timeformat(-9, 1, "ns", 10);
    $fsdbDumpfile("./asic_top.fsdb");
    $fsdbDumpvars(0, apb_archinfo_tb);
  end

  initial begin
    clk_i   = 1'b0;
    rst_n_i = 1'b0;
    repeat (40) @(posedge clk_i);
    #1 rst_n_i = 1'b1;
    $display("%t [INFO]: tb init done", $time);

    // read test
    u_apb4_master_model.cmp_data(8'd0, 32'hFFFF_0000, 32'h101F_1010);
    #12;
    u_apb4_master_model.cmp_data(8'd0, 32'hFFFF_0004, 32'hFFFF_2022);
    #12;
    u_apb4_master_model.cmp_data(8'd0, 32'hFFFF_0008, 32'hFFFF_FFFF);
    #11000 $finish;
  end

  logic [31:0] sync, out, dir, iof;
  logic irq;
  apb4_if u_apb4_if (
      clk_i,
      rst_n_i
  );

  apb4_master_model u_apb4_master_model (u_apb4_if);
  apb4_archinfo u_apb4_archinfo (u_apb4_if);


endmodule
