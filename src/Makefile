.PHONY: clean

CFLAGS = -g -Wall -pedantic -O3 $(shell pkg-config --cflags libserialport)
LIBS = $(shell pkg-config --libs libserialport)

serialram: elf_read.c serialram.c
	gcc $(CFLAGS) $^ $(LIBS) -o $@

%.o: %.c
	gcc -g -Wall $^ -c

clean:
	rm -f serialram *.o
