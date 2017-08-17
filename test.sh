#!/bin/sh

expected_result="/tmp/expected"
test_out="/tmp/om_test_o"

echo "Hello World!" | tee "$expected_result" | ./om > "$test_out"
diff "$expected_result" "$test_out"

rm "$expected_result" "$test_out"
