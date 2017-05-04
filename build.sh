#!/bin/sh -x

compile="gcc -Wall -pedantic -std=c11"

$compile -o test test.c text.c && ./test
