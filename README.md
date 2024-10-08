# GPIO

## Features
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

FULL vision of datatsheet can be found in [datasheet.md](./doc/datasheet.md).

## Build and Test
```bash
make comp    # compile code with vcs
make run     # compile and run test with vcs
make wave    # open fsdb format waveform with verdi
```