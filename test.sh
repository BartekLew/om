#!/bin/sh 

input="/tmp/input"
test_out="/tmp/om_test_o"
expected="/tmp/expected"

echo "Hello World!\n Welcome foo world!" > "$input"
echo "23" > $expected
echo "foo" | ./om "$input" > "$test_out"
diff "$expected" "$test_out"

echo "foo, foo bar, foo bar baz" > "$input"
echo -e "0\n5\n14" > "$expected"
echo "foo" | ./om "$input" > "$test_out"
diff "$expected" "$test_out"

echo -n "" > "$expected"
echo "" | ./om "$input" > "$test_out"
diff "$expected" "$test_out"

rm "$input" "$test_out" "$expected"
