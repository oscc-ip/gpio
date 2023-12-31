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

`include "register.sv"
`include "edge_det.sv"
`include "gpio_define.sv"

module apb4_gpio (
    apb4_if.slave apb4,
    gpio_if.dut   gpio
);

  logic [3:0] s_apb4_addr;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk;

  logic [`GPIO_PIN_NUM-1:0] s_gpio_in;
  logic [`GPIO_PIN_NUM-1:0] s_gpio_dir_d, s_gpio_dir_q;
  logic s_gpio_dir_en;
  logic [`GPIO_PIN_NUM-1:0] s_gpio_out_d, s_gpio_out_q;
  logic s_gpio_out_en;
  logic [`GPIO_PIN_NUM-1:0] s_gpio_inten_d, s_gpio_inten_q;
  logic s_gpio_inten_en;
  logic [`GPIO_PIN_NUM-1:0] s_gpio_inttype0_d, s_gpio_inttype0_q;
  logic s_gpio_inttype0_en;
  logic [`GPIO_PIN_NUM-1:0] s_gpio_inttype1_d, s_gpio_inttype1_q;
  logic s_gpio_inttype1_en;
  logic [`GPIO_PIN_NUM-1:0] s_gpio_intstatus_d, s_gpio_intstatus_q;
  logic s_gpio_intstatus_en;
  logic [`GPIO_PIN_NUM-1:0] s_gpio_iofcfg_d, s_gpio_iofcfg_q;
  logic s_gpio_iofcfg_en;

  logic [`GPIO_PIN_NUM-1:0] s_gpio_rise, s_gpio_fall;
  logic [`GPIO_PIN_NUM-1:0] s_is_int_rise, s_is_int_fall;
  logic [`GPIO_PIN_NUM-1:0] s_is_int_lev0, s_is_int_lev1, s_is_int_all;
  logic s_rise_int, s_irq;

  assign s_apb4_addr = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready = 1'b1;
  assign apb4.pslverr = 1'b0;

  assign gpio.gpio_dir_o = s_gpio_dir_q;
  assign gpio.gpio_out_o = s_gpio_out_q;
  assign gpio.gpio_iof_o = s_gpio_iofcfg_q;
  assign gpio.irq_o = s_irq;

  assign s_is_int_rise = (s_gpio_inttype1_q & ~s_gpio_inttype0_q) & s_gpio_rise;
  assign s_is_int_fall = (s_gpio_inttype1_q & s_gpio_inttype0_q) & s_gpio_fall;
  assign s_is_int_lev0 = (~s_gpio_inttype1_q & s_gpio_inttype0_q) & ~s_gpio_in;
  assign s_is_int_lev1 = (~s_gpio_inttype1_q & ~s_gpio_inttype0_q) & s_gpio_in;
  assign s_is_int_all  = s_gpio_inten_q & (s_is_int_rise | s_is_int_fall | s_is_int_lev0 | s_is_int_lev1);
  assign s_rise_int = |s_is_int_all;

  edge_det #(2, `GPIO_PIN_NUM) u_edge_det (
      apb4.pclk,
      apb4.presetn,
      gpio.gpio_in_i,
      s_gpio_in,
      s_gpio_rise,
      s_gpio_fall
  );

  assign s_gpio_dir_en = s_apb4_wr_hdshk && s_apb4_addr == `GPIO_PADDIR;
  assign s_gpio_dir_d  = s_gpio_dir_en ? apb4.pwdata[`GPIO_PIN_NUM-1:0] : s_gpio_dir_q;
  dffer #(`GPIO_PIN_NUM) u_gpio_paddir_dffer (
      apb4.pclk,
      apb4.presetn,
      s_gpio_dir_en,
      s_gpio_dir_d,
      s_gpio_dir_q
  );

  assign s_gpio_out_en = s_apb4_wr_hdshk && s_apb4_addr == `GPIO_PADOUT;
  assign s_gpio_out_d  = s_gpio_out_en ? apb4.pwdata[`GPIO_PIN_NUM-1:0] : s_gpio_out_q;
  dffer #(`GPIO_PIN_NUM) u_gpio_padin_dffer (
      apb4.pclk,
      apb4.presetn,
      s_gpio_out_en,
      s_gpio_out_d,
      s_gpio_out_q
  );

  assign s_gpio_inten_en = s_apb4_wr_hdshk && s_apb4_addr == `GPIO_INTEN;
  assign s_gpio_inten_d  = s_gpio_inten_en ? apb4.pwdata[`GPIO_PIN_NUM-1:0] : s_gpio_inten_q;
  dffer #(`GPIO_PIN_NUM) u_gpio_inten_dffer (
      apb4.pclk,
      apb4.presetn,
      s_gpio_inten_en,
      s_gpio_inten_d,
      s_gpio_inten_q
  );

  assign s_gpio_inttype0_en = s_apb4_wr_hdshk && s_apb4_addr == `GPIO_INTTYPE0;
  assign s_gpio_inttype0_d = s_gpio_inttype0_en ? apb4.pwdata[`GPIO_PIN_NUM-1:0] : s_gpio_inttype0_q;
  dffer #(`GPIO_PIN_NUM) u_gpio_inttype0_dffer (
      apb4.pclk,
      apb4.presetn,
      s_gpio_inttype0_en,
      s_gpio_inttype0_d,
      s_gpio_inttype0_q
  );

  assign s_gpio_inttype1_en = s_apb4_wr_hdshk && s_apb4_addr == `GPIO_INTTYPE1;
  assign s_gpio_inttype1_d = s_gpio_inttype1_en ? apb4.pwdata[`GPIO_PIN_NUM-1:0] : s_gpio_inttype1_q;
  dffer #(`GPIO_PIN_NUM) u_gpio_inttype1_dffer (
      apb4.pclk,
      apb4.presetn,
      s_gpio_inttype1_en,
      s_gpio_inttype1_d,
      s_gpio_inttype1_q
  );

  assign s_gpio_iofcfg_en = s_apb4_wr_hdshk && s_apb4_addr == `GPIO_IOFCFG;
  assign s_gpio_iofcfg_d  = s_gpio_iofcfg_en ? apb4.pwdata[`GPIO_PIN_NUM-1:0] : s_gpio_iofcfg_q;
  dffer #(`GPIO_PIN_NUM) u_gpio_iofcfg_dffer (
      apb4.pclk,
      apb4.presetn,
      s_gpio_iofcfg_en,
      s_gpio_iofcfg_d,
      s_gpio_iofcfg_q
  );

  assign s_irq = |s_gpio_intstatus_q;
  assign s_gpio_intstatus_en = (s_irq && s_apb4_rd_hdshk && s_apb4_addr == `GPIO_INTSTATUS) || (~s_irq && s_rise_int);
  always_comb begin
    s_gpio_intstatus_d = s_gpio_intstatus_q;
    if (s_irq && s_apb4_rd_hdshk && s_apb4_addr == `GPIO_INTSTATUS) begin
      s_gpio_intstatus_d = '0;  // NOTE: clear all pin trigger statement
    end else if (~s_irq && s_rise_int) begin
      s_gpio_intstatus_d = s_is_int_all;
    end
  end
  dffer #(`GPIO_PIN_NUM) u_gpio_intstatus_dffer (
      apb4.pclk,
      apb4.presetn,
      s_gpio_intstatus_en,
      s_gpio_intstatus_d,
      s_gpio_intstatus_q
  );

  always_comb begin
    apb4.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `GPIO_PADDIR:    apb4.prdata[`GPIO_PIN_NUM-1:0] = s_gpio_dir_q;
        `GPIO_PADIN:     apb4.prdata[`GPIO_PIN_NUM-1:0] = s_gpio_in;
        `GPIO_PADOUT:    apb4.prdata[`GPIO_PIN_NUM-1:0] = s_gpio_out_q;
        `GPIO_INTEN:     apb4.prdata[`GPIO_PIN_NUM-1:0] = s_gpio_inten_q;
        `GPIO_INTTYPE0:  apb4.prdata[`GPIO_PIN_NUM-1:0] = s_gpio_inttype0_q;
        `GPIO_INTTYPE1:  apb4.prdata[`GPIO_PIN_NUM-1:0] = s_gpio_inttype1_q;
        `GPIO_INTSTATUS: apb4.prdata[`GPIO_PIN_NUM-1:0] = s_gpio_intstatus_q;
        `GPIO_IOFCFG:    apb4.prdata[`GPIO_PIN_NUM-1:0] = s_gpio_iofcfg_q;
        default:         apb4.prdata[`GPIO_PIN_NUM-1:0] = '0;
      endcase
    end
  end
endmodule
