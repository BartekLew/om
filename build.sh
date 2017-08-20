#!/bin/sh -e

as om.s -g -o om.o
as text.s -g -o text.o

ld om.o text.o -o om

./test.sh
