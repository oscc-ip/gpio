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

`define REG_PADDIR 4'b0000 //BASEADDR+0x00
`define REG_PADIN 4'b0001 //BASEADDR+0x04
`define REG_PADOUT 4'b0010 //BASEADDR+0x08
`define REG_INTEN 4'b0011 //BASEADDR+0x0C
`define REG_INTTYPE0 4'b0100 //BASEADDR+0x10
`define REG_INTTYPE1 4'b0101 //BASEADDR+0x14
`define REG_INTSTATUS 4'b0110 //BASEADDR+0x18
`define REG_IOFCFG 4'b0111 //BASEADDR+0x1C


module apb4_gpio #(
    parameter GPIO_NUM = 32 // <= 32
) (
           apb4_if                apb4,
    input  logic   [GPIO_NUM-1:0] gpio_in_i,
    output logic   [GPIO_NUM-1:0] gpio_in_sync_o,
    output logic   [GPIO_NUM-1:0] gpio_out_o,
    output logic   [GPIO_NUM-1:0] gpio_dir_o,
    output logic   [GPIO_NUM-1:0] gpio_iof_o,
    output logic                  irq_o
);

  logic [31:0] r_gpio_inten;
  logic [31:0] r_gpio_inttype0;
  logic [31:0] r_gpio_inttype1;
  logic [31:0] r_gpio_out;
  logic [31:0] r_gpio_dir;
  logic [31:0] r_gpio_sync0;
  logic [31:0] r_gpio_sync1;
  logic [31:0] r_gpio_in;
  logic [31:0] r_iofcfg;
  logic [31:0] s_gpio_rise;
  logic [31:0] s_gpio_fall;
  logic [31:0] s_is_int_rise;
  logic [31:0] s_is_int_fall;
  logic [31:0] s_is_int_lev0;
  logic [31:0] s_is_int_lev1;
  logic [31:0] s_is_int_all;
  logic        s_rise_int;
  logic [ 3:0] s_apb_addr;
  logic [31:0] r_status;

  assign s_apb_addr = apb4.paddr[5:2];
  assign gpio_in_sync_o = r_gpio_sync1;
  assign s_gpio_rise = r_gpio_sync1 & ~r_gpio_in;  //foreach input check if rising edge
  assign s_gpio_fall = ~r_gpio_sync1 & r_gpio_in;  //foreach input check if falling edge

  assign s_is_int_rise = (r_gpio_inttype1 & ~r_gpio_inttype0) & s_gpio_rise;  // inttype 01 rise
  assign s_is_int_fall = (r_gpio_inttype1 & r_gpio_inttype0) & s_gpio_fall;  // inttype 00 fall
  assign s_is_int_lev0 = (~r_gpio_inttype1 & r_gpio_inttype0) & ~r_gpio_in;  // inttype 10 level 0
  assign s_is_int_lev1 = (~r_gpio_inttype1 & ~r_gpio_inttype0) & r_gpio_in;  // inttype 11 level 1

  //check if bit if irq_o is enable and if irq_o specified by inttype occurred
  assign s_is_int_all  = r_gpio_inten & (((s_is_int_rise | s_is_int_fall) | s_is_int_lev0) | s_is_int_lev1);
  //is any bit enabled and specified irq_o happened?
  assign s_rise_int = |s_is_int_all;

  always_ff @(posedge apb4.hclk, negedge apb4.hresetn) begin
    if (~apb4.hresetn) begin
      irq_o    <= 1'b0;
      r_status <= 'h0;
    end else if (!irq_o && s_rise_int) begin  //rise irq_o if not already rise
      irq_o    <= 1'b1;
      r_status <= s_is_int_all;
    end else if ((((irq_o && apb4.psel) && apb4.penable) && !apb4.pwrite) && (s_apb_addr == `REG_INTSTATUS)) begin    //clears int if status is read
      irq_o    <= 1'b0;
      r_status <= 'h0;
    end
  end

  always_ff @(posedge apb4.hclk or negedge apb4.hresetn) begin
    if (~apb4.hresetn) begin
      r_gpio_sync0 <= 'h0;
      r_gpio_sync1 <= 'h0;
      r_gpio_in    <= 'h0;
    end else begin
      r_gpio_sync0 <= gpio_in_i;  //first 2 sync for metastability resolving
      r_gpio_sync1 <= r_gpio_sync0;
      r_gpio_in    <= r_gpio_sync1;  //last reg used for edge detection
    end
  end

  always_ff @(posedge apb4.hclk, negedge apb4.hresetn) begin
    if (~apb4.hresetn) begin
      r_gpio_inten    <= 'b0;
      r_gpio_inttype0 <= 'b0;
      r_gpio_inttype1 <= 'b0;
      r_gpio_out      <= 'b0;
      r_gpio_dir      <= 'b0;
      r_iofcfg        <= 'b0;
    end else if ((apb4.psel && apb4.penable) && apb4.pwrite) begin
      case (s_apb_addr)
        `REG_PADDIR:   r_gpio_dir <= apb4.pwdata;
        `REG_PADOUT:   r_gpio_out <= apb4.pwdata;
        `REG_INTEN:    r_gpio_inten <= apb4.pwdata;
        `REG_INTTYPE0: r_gpio_inttype0 <= apb4.pwdata;
        `REG_INTTYPE1: r_gpio_inttype1 <= apb4.pwdata;
        `REG_IOFCFG:   r_iofcfg <= apb4.pwdata;
      endcase
    end
  end

  always_comb begin
    unique case (s_apb_addr)
      `REG_PADDIR:    apb4.prdata = r_gpio_dir;
      `REG_PADIN:     apb4.prdata = r_gpio_in;
      `REG_PADOUT:    apb4.prdata = r_gpio_out;
      `REG_INTEN:     apb4.prdata = r_gpio_inten;
      `REG_INTTYPE0:  apb4.prdata = r_gpio_inttype0;
      `REG_INTTYPE1:  apb4.prdata = r_gpio_inttype1;
      `REG_INTSTATUS: apb4.prdata = r_status;
      `REG_IOFCFG:    apb4.prdata = r_iofcfg;
      default:        apb4.prdata = 'h0;
    endcase
  end

  assign gpio_iof_o  = r_iofcfg;
  assign gpio_out_o  = r_gpio_out;
  assign gpio_dir_o  = r_gpio_dir;
  assign apb4.pready = 1'b1;
  assign apb4.pslerr = 1'b0;

endmodule
