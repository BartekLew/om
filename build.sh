#!/bin/sh -e

preprocess() {
    awk -f liberation.awk $@
}

compile() {
    name=${1%%.s+}
    preprocess $1 > "o/$name.s"
    as -g -o o/$name.o o/$name.s
}

compile liberation.s+

ld o/liberation.o -o liberation

./liberation /usr/bin/hexdump
