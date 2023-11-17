// Copyright (c) 2023 Beijing Institute of Open Source Chip
// gpio is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "helper.sv"
`include "test_base.sv"

class TestGPIO extends TestBase;
  string name;

  extern function new(string name = "test_gpio");
  extern task test_reset_register();
  extern task test_irq();
endclass

function TestGPIO::new(string name);
  super.new();
  this.name = name;
endfunction

task TestGPIO::test_reset_register();
  super.test_reset_register();
  
endtask

task TestGPIO::test_irq();
  super.test_irq();
endtask
