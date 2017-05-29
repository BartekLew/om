#!/bin/sh

temp_dir=/tmp
out=$temp_dir/om-ui-test.out

for file in om.c test.c text.c
do
    echo "*" | ./om $file > "$out"
    diff "$out" $file
done
