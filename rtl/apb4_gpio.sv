// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// -- Adaptable modifications are redistributed under compatible License --
//
// Copyright (c) 2023 Beijing Institute of Open Source Chip
// gpio is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

// verilog_format: off
`define GPIO_PADDIR    4'b0000 // BASEADDR + 0x00
`define GPIO_PADIN     4'b0001 // BASEADDR + 0x04
`define GPIO_PADOUT    4'b0010 // BASEADDR + 0x08
`define GPIO_INTEN     4'b0011 // BASEADDR + 0x0C
`define GPIO_INTTYPE0  4'b0100 // BASEADDR + 0x10
`define GPIO_INTTYPE1  4'b0101 // BASEADDR + 0x14
`define GPIO_INTSTATUS 4'b0110 // BASEADDR + 0x18
`define GPIO_IOFCFG    4'b0111 // BASEADDR + 0x1C
// verilog_format: on

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

module apb4_gpio #(
    parameter int GPIO_NUM = 32
) (
    // verilog_format: off
    apb4_if.slave               apb4,
    // verilog_format: on
    input  logic [GPIO_NUM-1:0] gpio_in_i,
    output logic [GPIO_NUM-1:0] gpio_in_sync_o,
    output logic [GPIO_NUM-1:0] gpio_out_o,
    output logic [GPIO_NUM-1:0] gpio_dir_o,
    output logic [GPIO_NUM-1:0] gpio_iof_o,
    output logic                irq_o
);

  logic [3:0] s_apb4_addr;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk;
  logic [GPIO_NUM-1:0] r_gpio_inten;
  logic [GPIO_NUM-1:0] r_gpio_inttype0;
  logic [GPIO_NUM-1:0] r_gpio_inttype1;
  logic [GPIO_NUM-1:0] r_gpio_out;
  logic [GPIO_NUM-1:0] r_gpio_dir;
  logic [GPIO_NUM-1:0] r_gpio_sync0;
  logic [GPIO_NUM-1:0] r_gpio_sync1;
  logic [GPIO_NUM-1:0] r_gpio_in;
  logic [GPIO_NUM-1:0] r_iofcfg;
  logic [GPIO_NUM-1:0] r_status;
  logic [GPIO_NUM-1:0] s_gpio_rise;
  logic [GPIO_NUM-1:0] s_gpio_fall;
  logic [GPIO_NUM-1:0] s_is_int_rise;
  logic [GPIO_NUM-1:0] s_is_int_fall;
  logic [GPIO_NUM-1:0] s_is_int_lev0;
  logic [GPIO_NUM-1:0] s_is_int_lev1;
  logic [GPIO_NUM-1:0] s_is_int_all;
  logic                s_rise_int;

  if (GPIO_NUM < 1 || GPIO_NUM > 32) begin
    $error("GPIO_NUM must be strictly larger than 0 and less than 33");
  end

  assign s_apb4_addr = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready = 1'b1;
  assign apb4.pslverr = 1'b0;

  assign gpio_iof_o = r_iofcfg;
  assign gpio_out_o = r_gpio_out;
  assign gpio_dir_o = r_gpio_dir;
  assign gpio_in_sync_o = r_gpio_sync1;
  assign s_gpio_rise = r_gpio_sync1 & ~r_gpio_in;  // check if rising edge
  assign s_gpio_fall = ~r_gpio_sync1 & r_gpio_in;  // check if falling edge

  assign s_is_int_rise = (r_gpio_inttype1 & ~r_gpio_inttype0) & s_gpio_rise;
  assign s_is_int_fall = (r_gpio_inttype1 & r_gpio_inttype0) & s_gpio_fall;
  assign s_is_int_lev0 = (~r_gpio_inttype1 & r_gpio_inttype0) & ~r_gpio_in;
  assign s_is_int_lev1 = (~r_gpio_inttype1 & ~r_gpio_inttype0) & r_gpio_in;

  // check if bit if irq_o is enable and if irq_o specified by inttype occurred
  assign s_is_int_all  = r_gpio_inten & (s_is_int_rise | s_is_int_fall | s_is_int_lev0 | s_is_int_lev1);
  assign s_rise_int = |s_is_int_all;

  always_ff @(posedge apb4.pclk, negedge apb4.presetn) begin
    if (~apb4.presetn) begin
      irq_o    <= 1'b0;
      r_status <= '0;
    end else if (~irq_o && s_rise_int) begin  // rise irq_o if not already rise
      irq_o    <= 1'b1;
      r_status <= s_is_int_all;
    end else if (irq_o && s_apb4_rd_hdshk && (s_apb4_addr == `GPIO_INTSTATUS)) begin //clears int if status is read
      irq_o    <= 1'b0;
      r_status <= '0;
    end
  end

  // first 2 sync for metastability resolving, last reg used for edge detection
  always_ff @(posedge apb4.pclk, negedge apb4.presetn) begin
    if (~apb4.presetn) begin
      r_gpio_sync0 <= '0;
      r_gpio_sync1 <= '0;
      r_gpio_in    <= '0;
    end else begin
      r_gpio_sync0 <= gpio_in_i;
      r_gpio_sync1 <= r_gpio_sync0;
      r_gpio_in    <= r_gpio_sync1;
    end
  end

  always_ff @(posedge apb4.pclk, negedge apb4.presetn) begin
    if (~apb4.presetn) begin
      r_gpio_inten    <= '0;
      r_gpio_inttype0 <= '0;
      r_gpio_inttype1 <= '0;
      r_gpio_out      <= '0;
      r_gpio_dir      <= '0;
      r_iofcfg        <= '0;
    end else if (s_apb4_wr_hdshk) begin
      unique case (s_apb4_addr)
        `GPIO_PADDIR:   r_gpio_dir <= apb4.pwdata[GPIO_NUM-1:0];
        `GPIO_PADOUT:   r_gpio_out <= apb4.pwdata[GPIO_NUM-1:0];
        `GPIO_INTEN:    r_gpio_inten <= apb4.pwdata[GPIO_NUM-1:0];
        `GPIO_INTTYPE0: r_gpio_inttype0 <= apb4.pwdata[GPIO_NUM-1:0];
        `GPIO_INTTYPE1: r_gpio_inttype1 <= apb4.pwdata[GPIO_NUM-1:0];
        `GPIO_IOFCFG:   r_iofcfg <= apb4.pwdata[GPIO_NUM-1:0];
      endcase
    end
  end

  always_comb begin
    apb4.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `GPIO_PADDIR:    apb4.prdata[GPIO_NUM-1:0] = r_gpio_dir;
        `GPIO_PADIN:     apb4.prdata[GPIO_NUM-1:0] = r_gpio_in;
        `GPIO_PADOUT:    apb4.prdata[GPIO_NUM-1:0] = r_gpio_out;
        `GPIO_INTEN:     apb4.prdata[GPIO_NUM-1:0] = r_gpio_inten;
        `GPIO_INTTYPE0:  apb4.prdata[GPIO_NUM-1:0] = r_gpio_inttype0;
        `GPIO_INTTYPE1:  apb4.prdata[GPIO_NUM-1:0] = r_gpio_inttype1;
        `GPIO_INTSTATUS: apb4.prdata[GPIO_NUM-1:0] = r_status;
        `GPIO_IOFCFG:    apb4.prdata[GPIO_NUM-1:0] = r_iofcfg;
        default:         apb4.prdata[GPIO_NUM-1:0] = '0;
      endcase
    end
  end
endmodule
