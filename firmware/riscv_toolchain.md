# Installing and using the RISC-V toolchain

Mostly taken from 
[the picorv readme](https://github.com/YosysHQ/picorv32/blob/main/README.md)

Install dependencies
```
sudo apt-get install autoconf automake autotools-dev curl libmpc-dev \
     libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo \
     gperf libtool patchutils bc zlib1g-dev git libexpat1-dev
```

Create destination
```
sudo mkdir /opt/riscv32i
sudo chown $USER /opt/riscv32i
```

Download and build the toolchain
```
make download-tools
cd riscv-gnu-toolchain-riscv32i/
mkdir build && cd build
./configure --with-arch=rv32i --prefix=/opt/riscv32i
make -j$(nproc)
```

Cloning the toolchain repo and checking out `411d134` didn't work properly, as the submodules failed to download.
The picorv's Makefile needs to be used for downloading, and the toolchain's Makefile needs to be used for building.

