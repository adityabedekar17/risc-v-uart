.PHONY: test clean
CROSS := /opt/riscv32i/bin/riscv32-unknown-elf-
CFLAGS := -Wall

icesugar_fw.elf: start.S firmware.c
	$(CROSS)gcc $(CFLAGS) -mabi=ilp32 -march=rv32i -Wl,-Bstatic,-T,sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $^

objdump.txt: icesugar_fw.elf
	$(CROSS)objdump -S $^ > $@

test:
	@$(CROSS)gcc --version

clean:
	rm ./icesugar_fw.elf ./objdump.txt
