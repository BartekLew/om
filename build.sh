#!/bin/sh -e

awk -f asmp.awk om.s | as -g -o om.o -
awk -f asmp.awk text.s | as -g -o text.o -

ld om.o text.o -o om

./test.sh
