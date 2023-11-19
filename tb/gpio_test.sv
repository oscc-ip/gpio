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
  int                    gpio_num,     gpio_mask;
  int                    dir_val,      in_val;
  int                    out_val,      inten_val;
  int                    inttype0_val, inttype1_val;
  virtual apb4_if.master apb4;
  virtual gpio_if.tb     gpio;

  extern function new(string name = "gpio_test", int gpio_num, virtual apb4_if.master apb4,
                      virtual gpio_if.tb gpio);
  extern task test_reset_reg();
  extern task test_wr_rd_reg(input bit [31:0] run_times = 1000);
  extern task test_gpio_io(input bit [31:0] run_times = 1000);
  extern task test_gpio_cfg(input bit [31:0] run_times = 1000);
  extern task test_irq(input bit [31:0] run_times = 1000);
endclass

function GPIOTest::new(string name, int gpio_num, virtual apb4_if.master apb4,
                       virtual gpio_if.tb gpio);
  super.new("apb4_master", apb4);
  this.name         = name;
  this.gpio_num     = gpio_num;
  this.gpio_mask    = (1 << (gpio_num)) - 1;
  this.dir_val      = 0;
  this.in_val       = 0;
  this.out_val      = 0;
  this.inten_val    = 0;
  this.inttype0_val = 0;
  this.inttype1_val = 0;
  this.apb4         = apb4;
  this.gpio         = gpio;
endfunction

task GPIOTest::test_reset_reg();
  super.test_reset_reg();
  // verilog_format: off
  this.rd_check(`GPIO_PADDIR_ADDR, "PADDIR REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_PADIN_ADDR, "PADIN REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_PADOUT_ADDR, "PADOUT REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_INTEN_ADDR, "INTEN REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_INTTYPE0_ADDR, "INTTYPE0 REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_INTTYPE1_ADDR, "INTTYPE1 REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_INTSTATUS_ADDR, "INTSTATUS REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  this.rd_check(`GPIO_IOFCFG_ADDR, "IOFCFG REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  // verilog_format: on
endtask

task GPIOTest::test_wr_rd_reg(input bit [31:0] run_times = 1000);
  super.test_wr_rd_reg();
  // verilog_format: off
  for (int i = 0; i < run_times; i++) begin
    this.wr_check(`GPIO_PADDIR_ADDR, "PADDIR REG", $random & this.gpio_mask, Helper::EQUL);
    this.wr_check(`GPIO_PADOUT_ADDR, "PADOUT REG", $random & this.gpio_mask, Helper::EQUL);
    this.wr_check(`GPIO_INTEN_ADDR, "INTEN REG", $random & this.gpio_mask, Helper::EQUL);
    this.wr_check(`GPIO_INTTYPE0_ADDR, "INTTYPE0 REG", $random & this.gpio_mask, Helper::EQUL);
    this.wr_check(`GPIO_INTTYPE1_ADDR, "INTTYPE1 REG", $random & this.gpio_mask, Helper::EQUL);
    this.wr_check(`GPIO_IOFCFG_ADDR, "IOFCFG REG", $random & this.gpio_mask, Helper::EQUL);
  end
  // verilog_format: on
endtask

task GPIOTest::test_gpio_io(input bit [31:0] run_times = 1000);
  $display("=== [test gpio io] ===");
  // reg: dir, out, in, clear int enable
  this.write(`GPIO_INTEN_ADDR, 32'b0);
  for (int i = 0; i < run_times; i++) begin
    this.dir_val = $random & this.gpio_mask;
    this.in_val  = $random & this.gpio_mask;
    this.out_val = $random & this.gpio_mask;

    this.write(`GPIO_PADDIR_ADDR, this.dir_val);
    this.gpio.gpio_in_i = this.in_val;
    this.write(`GPIO_PADOUT_ADDR, this.out_val);

    Helper::check("GPIO WRITE OUT", this.gpio.gpio_out_o, this.out_val, Helper::EQUL);
    Helper::check("GPIO DIR", this.gpio.gpio_dir_o, this.dir_val, Helper::EQUL);
    this.rd_check(`GPIO_PADIN_ADDR, "GPIO READ IN", this.in_val, Helper::EQUL);
  end
endtask

task GPIOTest::test_gpio_cfg(input bit [31:0] run_times = 1000);
  $display("=== [test gpio cfg] ===");
  for (int i = 0; i < run_times; i++) begin
    this.wr_check(`GPIO_IOFCFG_ADDR, "IOFCFG REG", $random & this.gpio_mask, Helper::EQUL);
  end
endtask

task GPIOTest::test_irq(input bit [31:0] run_times = 1000);
  super.test_irq();
  // reg: inten, type0, type1
  // check irq, status
  for (int i = 0; i < run_times; i++) begin
    this.in_val = $random & this.gpio_mask;
    // this.in_val = 8'hFF;

    $display("1: in_val: %h, super.rd_data: %h", this.in_val, super.rd_data);
    // all irq high triggered test
    this.write(`GPIO_INTEN_ADDR, 32'hFF);
    this.write(`GPIO_INTTYPE0_ADDR, 32'b0);
    this.write(`GPIO_INTTYPE1_ADDR, 32'b0);
    this.gpio.gpio_in_i = this.in_val;
    repeat (4) @(posedge this.apb4.pclk);
    this.read(`GPIO_INTSTATUS_ADDR);
    $display("2: in_val: %h, super.rd_data: %h", this.in_val, super.rd_data);
    this.read(`GPIO_INTSTATUS_ADDR);
    $display("3: in_val: %h, super.rd_data: %h", this.in_val, super.rd_data);
    // this.rd_check(`GPIO_INTSTATUS_ADDR, "INTSTATUS REG", 32'hFF, Helper::EQUL);


    // this.inten_val    = $random & this.gpio_mask;
    // this.inttype0_val = $random & this.gpio_mask;
    // this.inttype1_val = $random & this.gpio_mask;
  end
endtask

`endif
