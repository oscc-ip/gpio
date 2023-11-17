// Copyright (c) 2023 Beijing Institute of Open Source Chip
// gpio is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_GPIO_TEST_SV
`define INC_GPIO_TEST_SV

`include "apb4_master.sv"
`include "gpio_define.sv"

class GPIOTest extends APB4Master;
  string                 name;
  int                    gpio_num;
  int                    gpio_val;
  virtual apb4_if.master apb4;
  virtual gpio_if.tb     gpio;

  extern function new(string name = "gpio_test", int gpio_num, virtual apb4_if.master apb4,
                      virtual gpio_if.tb gpio);
  extern task test_reset_register();
  extern task test_wr_rd_register(input bit [31:0] run_times = 1000);
  extern task test_io_register(input bit [31:0] run_times = 1000);
endclass

function GPIOTest::new(string name, int gpio_num, virtual apb4_if.master apb4,
                       virtual gpio_if.tb gpio);
  super.new("apb4_master", apb4);
  this.name     = name;
  this.gpio_num = gpio_num;
  this.gpio_val = 1 << gpio_num - 1;
  this.apb4     = apb4;
  this.gpio     = gpio;
endfunction

task GPIOTest::test_reset_register();
  super.test_reset_register();
  // verilog_format: off
  this.rd_check(`GPIO_PADDIR_ADDR, "PADDIR REG", 32'b0 & this.gpio_val, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_PADIN_ADDR, "PADIN REG", 32'b0 & this.gpio_val, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_PADOUT_ADDR, "PADOUT REG", 32'b0 & this.gpio_val, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_INTEN_ADDR, "INTEN REG", 32'b0 & this.gpio_val, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_INTTYPE0_ADDR, "INTTYPE0 REG", 32'b0 & this.gpio_val, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_INTTYPE1_ADDR, "INTTYPE1 REG", 32'b0 & this.gpio_val, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_INTSTATUS_ADDR, "INTSTATUS REG", 32'b0 & this.gpio_val, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_IOFCFG_ADDR, "IOFCFG REG", 32'b0 & this.gpio_val, Helper::EQUL, Helper::INFO);
  // verilog_format: on
endtask

task GPIOTest::test_wr_rd_register(input bit [31:0] run_times = 1000);
  super.test_wr_rd_register();
  // verilog_format: off
  for (int i = 0; i < run_times; i++) begin
    this.wr_check(`GPIO_PADDIR_ADDR, "PADDIR REG", $random & this.gpio_val, Helper::EQUL);
    this.wr_check(`GPIO_PADOUT_ADDR, "PADOUT REG", $random & this.gpio_val, Helper::EQUL);
    this.wr_check(`GPIO_INTEN_ADDR, "INTEN REG", $random & this.gpio_val, Helper::EQUL);
    this.wr_check(`GPIO_INTTYPE0_ADDR, "INTTYPE0 REG", $random & this.gpio_val, Helper::EQUL);
    this.wr_check(`GPIO_INTTYPE1_ADDR, "INTTYPE1 REG", $random & this.gpio_val, Helper::EQUL);
    this.wr_check(`GPIO_IOFCFG_ADDR, "IOFCFG REG", $random & this.gpio_val, Helper::EQUL);
  end
  // verilog_format: on
endtask

`endif
