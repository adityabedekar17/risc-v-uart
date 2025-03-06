.PHONY: clean

CFLAGS = -g -Wall $(shell pkg-config --cflags libserialport)
LIBS = $(shell pkg-config --libs libserialport)

serialram: serialram.c elf_read.o
	gcc $(CFLAGS) $^ $(LIBS) -o $@

elf_read.o: elf_read.c
	gcc -Wall -g $^ -c

clean:
	rm -f serialram elf_read.o
