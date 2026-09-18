# Makefile for compiling the oct-file of the warning fixture

MKOCTFILE ?= mkoctfile

.PHONY: all
all: __ciwarn__.oct

%.oct: %.cc
	$(MKOCTFILE) $<

.PHONY: clean
clean:
	rm -f *.oct *.o
