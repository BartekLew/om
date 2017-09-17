#!/bin/sh -e

asmp() {
    awk -f asmp.awk $@
    cat /tmp/asmp.tmp
}

compile() {
    name=${1%%.s+}
    asmp $1 > "o/$name.s"
    as -g -o o/$name.o o/$name.s
}

compile conscious.s+
as -g -o o/text.o text.s

ld o/conscious.o o/text.o -entry conscious -o conscious

./conscious
