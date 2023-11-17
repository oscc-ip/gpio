// Copyright (c) 2023 Beijing Institute of Open Source Chip
// gpio is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "apb4_if.sv"
`include "gpio_define.sv"

module apb4_gpio_tb ();
  localparam CLK_PEROID = 10;
  localparam GPIO_NUM = 8;
  logic rst_n_i, clk_i;

  initial begin
    clk_i = 1'b0;
    forever begin
      #(CLK_PEROID / 2) clk_i <= ~clk_i;
    end
  end

  task sim_reset(int delay);
    rst_n_i = 1'b0;
    repeat (delay) @(posedge clk_i);
    #1 rst_n_i = 1'b1;
  endtask

  initial begin
    sim_reset(40);
  end

  apb4_if u_apb4_if (
      clk_i,
      rst_n_i
  );

  gpio_if #(GPIO_NUM) u_gpio_if ();

  test_top #(GPIO_NUM) u_test_top (
      .apb4(u_apb4_if),
      .gpio(u_gpio_if.tb)
  );
  apb4_gpio #(GPIO_NUM) u_apb4_gpio (
      .apb4(u_apb4_if),
      .gpio(u_gpio_if.dut)
  );

endmodule
