.PHONY: clean

CFLAGS = -g -Wall $(shell pkg-config --cflags libserialport)
LIBS = $(shell pkg-config --libs libserialport)

serialram: serialram.c
	gcc $(CFLAGS) $< $(LIBS) -o $@

clean:
	rm -f serialram
