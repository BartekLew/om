#!/bin/sh -e

asmp() {
    awk -f asmp/asmp.awk $@
}

asmp om.s | as -g -o om.o -
asmp text.s | as -g -o text.o -

ld om.o text.o -o om

./test.sh
