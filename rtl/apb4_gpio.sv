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

`include "gpio_define.sv"

module apb4_gpio #(
    parameter int GPIO_NUM = 32
) (
    apb4_if.slave apb4,
    gpio_if.dut   gpio
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

  assign s_apb4_addr = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready = 1'b1;
  assign apb4.pslverr = 1'b0;

  assign gpio.gpio_iof_o = r_iofcfg;
  assign gpio.gpio_out_o = r_gpio_out;
  assign gpio.gpio_dir_o = r_gpio_dir;
  assign s_gpio_rise = r_gpio_sync1 & ~r_gpio_in;  // check if rising edge
  assign s_gpio_fall = ~r_gpio_sync1 & r_gpio_in;  // check if falling edge

  assign s_is_int_rise = (r_gpio_inttype1 & ~r_gpio_inttype0) & s_gpio_rise;
  assign s_is_int_fall = (r_gpio_inttype1 & r_gpio_inttype0) & s_gpio_fall;
  assign s_is_int_lev0 = (~r_gpio_inttype1 & r_gpio_inttype0) & ~r_gpio_in;
  assign s_is_int_lev1 = (~r_gpio_inttype1 & ~r_gpio_inttype0) & r_gpio_in;

  // check if bit if gpio.irq_o is enable and if gpio.irq_o specified by inttype occurred
  assign s_is_int_all  = r_gpio_inten & (s_is_int_rise | s_is_int_fall | s_is_int_lev0 | s_is_int_lev1);
  assign s_rise_int = |s_is_int_all;

  always_ff @(posedge apb4.pclk, negedge apb4.presetn) begin
    if (~apb4.presetn) begin
      gpio.irq_o <= 1'b0;
      r_status   <= '0;
    end else if (~gpio.irq_o && s_rise_int) begin  // rise gpio.irq_o if not already rise
      gpio.irq_o <= 1'b1;
      r_status   <= s_is_int_all;
    end else if (gpio.irq_o && s_apb4_rd_hdshk && (s_apb4_addr == `GPIO_INTSTATUS)) begin //clears int if status is read
      gpio.irq_o <= 1'b0;
      r_status   <= '0;
    end
  end

  // first 2 sync for metastability resolving, last reg used for edge detection
  always_ff @(posedge apb4.pclk, negedge apb4.presetn) begin
    if (~apb4.presetn) begin
      r_gpio_sync0 <= '0;
      r_gpio_sync1 <= '0;
      r_gpio_in    <= '0;
    end else begin
      r_gpio_sync0 <= gpio.gpio_in_i;
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
