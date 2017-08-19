#!/bin/sh 

input="/tmp/input"
test_out="/tmp/om_test_o"
expected="/tmp/expected"
diff="/tmp/diff"

test_case() {
    input_text=$1
    expected_out=$2
    pattern=$3
    expected_result=$4

    echo -e "$input_text" > "$input"
    echo -en "$expected_out" > "$expected"
    echo -e "$pattern" | ./om "$input" > "$test_out"
    result=$?

    diff "$expected" "$test_out" > "$diff"
    if [[ "$?" -ne "0" || "$result" != $expected_result ]]; then
        echo "test case failed"
        echo "input: $input_text"
        echo "pattern: $pattern"
        echo "result: $result, expected: $expected_result"
        echo "output diff: "
        cat "$diff"
        echo
    fi
}

test_case "Hello World!\n Welcome foo world!" "22\n" "foo" 0
test_case "foo, foo bar, foo bar baz" "0\n5\n14\n" "foo" 0
test_case "foo bar baz" "" "" 1

rm "$input" "$test_out" "$expected" "$diff"
