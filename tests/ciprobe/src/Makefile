# Makefile for compiling the oct-file of the test package

MKOCTFILE ?= mkoctfile

.PHONY: all
all: __ciprobe__.oct

%.oct: %.cc
	$(MKOCTFILE) $<

.PHONY: clean
clean:
	rm -f *.oct *.o
