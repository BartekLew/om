#!/bin/sh

as om.s -g -o om.o
ld om.o -o om

./test.sh
