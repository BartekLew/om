#!/bin/sh -x

compile="gcc -g -Wall -pedantic -std=c11"

for module in text test om
do
    $compile $module.c -c -o $module.o
done

$compile -o test test.o text.o &&
    $compile -o om om.o text.o  &&
    ./test && ./ui-test.sh
