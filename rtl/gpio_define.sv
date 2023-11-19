// Copyright (c) 2023 Beijing Institute of Open Source Chip
// gpio is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_GPIO_DEF_SV
`define INC_GPIO_DEF_SV

/* register mapping
 * GPIO_PADDIR:
 * BITS:   | 31:GPIO_NUM | GPIO_NUM-1:0 |
 * FIELDS: | RES         | DIR          |
 * PERMS:  | NONE        | RW           |
 * --------------------------------------
 * GPIO_PADIN:
 * BITS:   | 31:GPIO_NUM | GPIO_NUM-1:0 |
 * FIELDS: | RES         | IN           |
 * PERMS:  | NONE        | R            |
 * --------------------------------------
 * GPIO_PADOUT:
 * BITS:   | 31:GPIO_NUM | GPIO_NUM-1:0 |
 * FIELDS: | RES         | OUT          |
 * PERMS:  | NONE        | RW           |
 * --------------------------------------
 * GPIO_INTEN:
 * BITS:   | 31:GPIO_NUM | GPIO_NUM-1:0 |
 * FIELDS: | RES         | INTEN        |
 * PERMS:  | NONE        | RW           |
 * --------------------------------------
 * GPIO_INTTYPE0:
 * BITS:   | 31:GPIO_NUM | GPIO_NUM-1:0 |
 * FIELDS: | RES         | INTTYPE0     |
 * PERMS:  | NONE        | RW           |
 * --------------------------------------
 * GPIO_INTTYPE1:
 * BITS:   | 31:GPIO_NUM | GPIO_NUM-1:0 |
 * FIELDS: | RES         | INTTYPE1     |
 * PERMS:  | NONE        | RW           |
 * --------------------------------------
 * GPIO_INTSTATUS:
 * BITS:   | 31:GPIO_NUM | GPIO_NUM-1:0 |
 * FIELDS: | RES         | INTSTATUS    |
 * PERMS:  | NONE        | R            |
 * --------------------------------------
 * GPIO_IOFCFG:
 * BITS:   | 31:GPIO_NUM | GPIO_NUM-1:0 |
 * FIELDS: | RES         | IOCFG        |
 * PERMS:  | NONE        | RW           |
 * --------------------------------------
*/

// verilog_format: off
`define GPIO_PADDIR    4'b0000 // BASEADDR + 0x00
`define GPIO_PADIN     4'b0001 // BASEADDR + 0x04
`define GPIO_PADOUT    4'b0010 // BASEADDR + 0x08
`define GPIO_INTEN     4'b0011 // BASEADDR + 0x0C
`define GPIO_INTTYPE0  4'b0100 // BASEADDR + 0x10
`define GPIO_INTTYPE1  4'b0101 // BASEADDR + 0x14
`define GPIO_INTSTATUS 4'b0110 // BASEADDR + 0x18
`define GPIO_IOFCFG    4'b0111 // BASEADDR + 0x1C

`define GPIO_PADDIR_ADDR    {26'b0, `GPIO_PADDIR   , 2'b00}
`define GPIO_PADIN_ADDR     {26'b0, `GPIO_PADIN    , 2'b00}
`define GPIO_PADOUT_ADDR    {26'b0, `GPIO_PADOUT   , 2'b00}
`define GPIO_INTEN_ADDR     {26'b0, `GPIO_INTEN    , 2'b00}
`define GPIO_INTTYPE0_ADDR  {26'b0, `GPIO_INTTYPE0 , 2'b00}
`define GPIO_INTTYPE1_ADDR  {26'b0, `GPIO_INTTYPE1 , 2'b00}
`define GPIO_INTSTATUS_ADDR {26'b0, `GPIO_INTSTATUS, 2'b00}
`define GPIO_IOFCFG_ADDR    {26'b0, `GPIO_IOFCFG   , 2'b00}
// verilog_format: on

// NOTE: set `GPIO_NUM to actual value to
// avoid the parameterized interface warnings
interface gpio_if #(
    parameter int GPIO_NUM = 8
) ();

  logic [GPIO_NUM-1:0] gpio_in_i;
  logic [GPIO_NUM-1:0] gpio_out_o;
  logic [GPIO_NUM-1:0] gpio_dir_o;
  logic [GPIO_NUM-1:0] gpio_iof_o;
  logic                irq_o;

  // verilog_format: off
  modport dut(input gpio_in_i, output gpio_out_o, output gpio_dir_o, output gpio_iof_o, output irq_o);
  modport tb(output gpio_in_i, input gpio_out_o, input gpio_dir_o, input gpio_iof_o, input irq_o);
  // verilog_format: on
endinterface
`endif
