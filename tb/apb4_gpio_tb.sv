`timescale 1ns / 1ps

module apb4_gpio_tb ();
  logic rst_n_i, clk_i;

  always #5.000 clk_i <= ~clk_i;  // 100MHz

  initial begin
    clk_i   = 1'b0;
    rst_n_i = 1'b0;
    repeat (40) @(posedge clk_i);
    #16 rst_n_i = 1;
  end

  initial begin
    if ($test$plusargs("dump_fst_wave")) begin
      $dumpfile("sim.wave");
      $dumpvars(0, apb4_gpio_tb);
    end else if ($test$plusargs("default_args")) begin
      $display("=========sim default args===========");
    end
    $display("sim 11000ns");
    #11000 $finish;
  end

  logic [31:0] sync, out, dir, iof;
  logic irq;
  apb4_if u_apb4_if (
      clk_i,
      rst_n_i
  );
  apb4_gpio #(32) u_apb4_gpio (
      .apb4          (u_apb4_if)
      .gpio_in_i     (32'b0),
      .gpio_in_sync_o(sync),
      .gpio_out_o    (out),
      .gpio_dir_o    (dir),
      .gpio_iof_o    (iof),
      .irq_o         (irq)
  );


endmodule
