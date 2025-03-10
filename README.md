# risc-v-uart
Handling memory read requests over UART with RISC-V Core (PicoRV32).
An LRU cache is used to demonstrate speed-up over no cache used.

## Usage
```
make lint
# runs verilator in lint only

make sim
# runs the simulation

make gls
# runs the post-synthesis simulation

make icestorm_icesugar_gls
# runs the post-synthesis simulation specific to the ice40-UP5K sg48

make bitstream 
# makes the bitstream

make icestorm_icesugar_program
# flash/program the test board
```

Firmware and controller:
```
inside src/:
make
./serialram <port> <elf file>
# Handles the memory request over UART on a host computer. Requires libserialport

python3 simple_uart.py
# runs an older version of the UART memory controller

inside firmware/:
make
# compiles firmware.c and start.S into an elf file for use with serialram
```

# Acknowledgements
This project was based on 
[verilog_template](https://github.com/sifferman/verilog_template/).

```
Copyright (c) 2025 Ethan Sifferman

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```
