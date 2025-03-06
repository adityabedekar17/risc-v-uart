.PHONY: clean

CFLAGS = -g -Wall -O3 $(shell pkg-config --cflags libserialport)
LIBS = $(shell pkg-config --libs libserialport)

serialram: elf_read.c serialram.c
	g++ $(CFLAGS) $^ $(LIBS) -o $@

%.o: %.c
	g++ -g -Wall $^ -c

clean:
	rm -f serialram *.o
