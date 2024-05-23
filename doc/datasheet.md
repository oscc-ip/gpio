## Datasheet

### Overview
The `gpio(general purpose input/output)` IP is a fully parameterised soft IP recording the SoC architecture and ASIC backend informations. The IP features an APB4 slave interface, fully compliant with the AMBA APB Protocol Specification v2.0.

### Feature
* 1~32 channels support
* Input and output direction control
* Pin multiplexer with one alternate ouput function
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
| `gpio.gpio_iof_o` | output | gpio function ouput |
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
| [IOCFG]() | 0x1C | 4 | io configuration register |

#### PAD Direction Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:GPIO_NUM]` | none | reserved |
| `[GPIO_NUM-1:0]` | RW | DIR |

reset value: `0x0000_0000`

* DIR: pad direction
    * `DIR[i] = 1'b0`: Ith gpio output
    * `DIR[i] = 1'b1`: Ith gpio input

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

### Program Guide
These registers can be accessed by 4-byte aligned read and write. C-like pseudocode output operation:
```c
gpio.PADDIR[i] = (uint32_t)0 // set Ith gpio ouput mode
gpio.PADOUT[i] = DATA_1_bit  // set Ith gpio output data
```
input operation:
```c
gpio.PADDIR[i]   = (uint32_t)1 // set Ith gpio ouput mode
gpio.INTEN[i]    = (uint32_t)1 // enable Ith gpio irq
gpio.INTTYPE0[i] = (uint32_t)0
gpio.INTTYPE1[i] = (uint32_t)1 // set Ith gpio type

// polling mode
while(gpio.PADDIN[i] == 1) {} 

// irq mode
...
gpio_handle(){
    irq_val = gpio.STAT // read and clear irq flag
}
```

### Resoureces
### References
### Revision History