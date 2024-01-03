# GPIO

## Features
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

## Build and Test
```bash
make comp    # compile code with vcs
make run     # compile and run test with vcs
make wave    # open fsdb format waveform with verdi
```