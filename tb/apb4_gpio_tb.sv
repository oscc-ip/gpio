`timescale 1ns / 1ps

`include "helper.sv"

module apb_archinfo_tb ();
  localparam LED_GPIO_NUM = 8;
  logic rst_n_i, clk_i;

  task sim_config();
    $timeformat(-9, 1, "ns", 10);
    $fsdbDumpfile("./asic_top.fsdb");
    $fsdbDumpvars(0, apb_archinfo_tb);
  endtask

  task reset();
    clk_i   = 1'b0;
    rst_n_i = 1'b0;
    repeat (40) @(posedge clk_i);
    #1 rst_n_i = 1'b1;
  endtask

  always #5.000 clk_i <= ~clk_i;  // 100MHz

  initial begin
    Helper::start_banner();
    sim_config();
    reset();
    Helper::print("tb init done");
    Helper::check("cfg_basic", 23, 22, Helper::EQUL);
    // read test
    // u_apb4_master_model.cmp_data(8'd0, 32'hFFFF_0000, 32'h101F_1010);
    // #12;
    // u_apb4_master_model.cmp_data(8'd0, 32'hFFFF_0004, 32'hFFFF_2022);
    // #12;
    // u_apb4_master_model.cmp_data(8'd0, 32'hFFFF_0008, 32'hFFFF_FFFF);
    Helper::end_banner();
    #11000 $finish;
  end

  apb4_if u_apb4_if (
      clk_i,
      rst_n_i
  );

  logic [LED_GPIO_NUM-1:0] s_gpio_in, s_gpio_out, s_gpio_dir, s_gpio_iof;
  wire [LED_GPIO_NUM-1:0] s_gpio_pad;
  apb4_master_model u_apb4_master_model (u_apb4_if);
  apb4_gpio #(LED_GPIO_NUM) u_apb4_gpio (
      .apb4      (u_apb4_if),
      .gpio_in_i (s_gpio_in),
      .gpio_out_o(s_gpio_out),
      .gpio_dir_o(s_gpio_dir),
      .gpio_iof_o(s_gpio_iof)
  );

  for (genvar i = 0; i < LED_GPIO_NUM; i++) begin
    // gpio_led_model u_gpio_led_model(s_gpio_pad[i]);

    tri_pd_pad_h u_tri_pd_pad_h (
        .i_i   (s_gpio_out[i]),
        .oen_i (s_gpio_dir[i]),
        .c_o   (s_gpio_in[i]),
        .pad_io(s_gpio_pad[i])
    );
  end

endmodule
