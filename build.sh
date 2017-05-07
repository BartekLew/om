#!/bin/sh -x

compile="gcc -g -Wall -pedantic -std=c11"

$compile -o test test.c text.c && ./test
