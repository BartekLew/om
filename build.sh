#!/bin/sh

as om.s -o om.o
ld om.o -o om

./test.sh
