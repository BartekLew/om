#!/bin/sh 

expected_result="/tmp/expected"
test_out="/tmp/om_test_o"

echo "Hello World!" > "$expected_result"
./om "$expected_result" > "$test_out"
diff "$expected_result" "$test_out"

rm "$expected_result" "$test_out"
