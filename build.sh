#!/bin/sh

compile="gcc -g -Wall -pedantic -std=c11"

result='0'

for module in text test om
do
    $compile $module.c -c -o $module.o
    if [[ "$?" != 0 ]];then
        result='1'
    fi
done

if [[ "$result" != 0 ]]; then
    echo "compilation failed"
    exit 1
fi

$compile -o test test.o text.o &&
    $compile -o om om.o text.o

if [[ "$?" != 0 ]]; then
    echo "linking failed"
    exit 2
fi

./test && ./ui-test.sh
if [[ "$?" != 0 ]]; then
    echo "test failed"
    exit 3
fi
