## Datasheet

### Overview
The `gpio(general purpose input/output)` IP is a fully parameterised soft IP recording the SoC architecture and ASIC backend informations. The IP features an APB4 slave interface, fully compliant with the AMBA APB Protocol Specification v2.0.

### Feature
* 1~32 channels support
* Input and output direction control
* Pin multiplexer with two alternate ouput function
* Three configurable modes
    * input pull-down with schmitt trigger
    * ouput push-pull
    * alternate function push-pull
* Maskable input interrupt with multiple triggering modes
    * rise mode
    * fall mode
    * high-level mode
    * low-level mode
* Static synchronous design
* Full synthesizable

### Interface
| port name | type        | description          |
|:--------- |:------------|:---------------------|
| apb4      | interface   | apb4 slave interface |
| gpio ->| interface | gpio interface |
| `gpio.gpio_in_i` | input | gpio data input |
| `gpio.gpio_out_o` | output | gpio data output |
| `gpio.gpio_dir_o` | output | gpio direction output |
| `gpio.gpio_alt_in_o` | output | alter io data output |
| `gpio.gpio_alt_0_out_i` | input | alter 0 channel data output |
| `gpio.gpio_alt_0_dir_i` | input | alter 0 channel direction output |
| `gpio.gpio_alt_1_out_i` | input | alter 1 channel data output |
| `gpio.gpio_alt_1_dir_i` | input | alter 1 channel direction output |
| `gpio.irq_o` | output | gpio interrupt output |

### Register

| name | offset  | length | description |
|:----:|:-------:|:-----: | :---------: |
| [PADDIR](#pad-direction-register) | 0x0 | 4 | pad direction register |
| [PADIN](#pad-data-in-register) | 0x4 | 4 | pad data in register |
| [PADOUT](#pad-data-out-register) | 0x8 | 4 | pad data out register |
| [INTEN](#interrupt-enable-register) | 0xC | 4 | interrupt enable register |
| [INTTYPE0](#interrupt-type0-register) | 0x10 | 4 | interrupt type0 register |
| [INTTYPE1](#interrupt-type1-register) | 0x14 | 4 | interrupt type1 register |
| [INTSTAT](#interrupt-state-register) | 0x18 | 4 | interrupt state register |
| [IOCFG](#io-config-register) | 0x1C | 4 | io configuration register |
| [PINMUX](#pin-mux-register) | 0x20 | 4 | pin mux register |

#### PAD Direction Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RW | DIR |

reset value: `0x0000_0000`

* DIR: pad direction
    * `DIR[i] = 1'b0`: Ith gpio input
    * `DIR[i] = 1'b1`: Ith gpio output

#### PAD Data In Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RO | IN |

reset value: `0x0000_0000`

* IN: pad data in

#### PAD Data Out Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RW | OUT |

reset value: `0x0000_0000`

* OUT: pad data out

#### Interrupt Enable Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RW | INTEN |

reset value: `0x0000_0000`

* INTEN: interrupt enable
    * `INTEN[i] = 1'b0`: disable Ith gpio input interrupt
    * `INTEN[i] = 1'b1`: otherwise

#### Interrupt Type0 Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RW | INTTYPE0 |

reset value: `0x0000_0000`

* INTTYPE0: interrupt type0

#### Interrupt Type1 Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RW | INTTYPE1 |

reset value: `0x0000_0000`

* INTTYPE1: interrupt type1

* `INTTYPE1 INTTYPE0 = 2'b00`: high level trigger
* `INTTYPE1 INTTYPE0 = 2'b01`: low level trigger
* `INTTYPE1 INTTYPE0 = 2'b10`: rise edge trigger
* `INTTYPE1 INTTYPE0 = 2'b11`: fall level trigger

#### Interrupt State Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RO | INTSTAT |

reset value: `0x0000_0000`

* INTSTAT: interrupt state

#### IO Config Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RW | IOCFG |

reset value: `0x0000_0000`

* IOCFG: io control mode config
    * `IOCFG[i] = 1'b0`: software control mode
    * `IOCFG[i] = 1'b1`: alternate control mode

#### Pin Mux Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RW | PINMUX |

reset value: `0x0000_0000`

* PINMUX: alternate io channel select
    * `PINMUX[i] = 1'b0`: alternate 0 channel io select
    * `PINMUX[i] = 1'b1`: alternate 1 channel io select

### Program Guide
These registers can be accessed by 4-byte aligned read and write. C-like pseudocode output operation:
```c
// software control
gpio.IOCFG[i]  = (uint32_t)0      // set to software control mode
gpio.PADDIR[i] = (uint32_t)0      // set Ith gpio ouput mode
gpio.PADOUT[i] = DATA_1_bit       // set Ith gpio output data
// alternate control
gpio.IOCFG[i]  = (uint32_t)1      // set to alternate io control mode
gpio.PINMUX[i] = (uint32_t)[0, 1] // set the alternate channel io
...                               // specific IP function config...
```
input operation:
```c
gpio.IOCFG       = (uint32_t)0    // set to software control mode
gpio.PADDIR[i]   = (uint32_t)1    // set Ith gpio ouput mode
gpio.INTEN[i]    = (uint32_t)1    // enable Ith gpio irq
gpio.INTTYPE0[i] = (uint32_t)0    // set Ith gpio rise edge trigger
gpio.INTTYPE1[i] = (uint32_t)1    // set Ith gpio rise edge trigger

// polling mode
while(gpio.PADDIN[i] == 1) {} 

// irq mode
...
gpio_handle(){
    irq_val = gpio.STAT           // read and clear irq flag
}
```
complete driver and test codes in [driver](../driver/) dir.

### Resoureces
### References
### Revision History