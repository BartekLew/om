#!/bin/sh

if [[ -n "$1" ]]; then
    program=$1
else
    program="/usr/bin/hexdump"
fi
commands="/tmp/wc.gdb"

run() {
    echo $@ | gdb "$program"
}

range=$(run "info files" | grep '.text' | awk '{print $1 ", " $3;}')
run "disassemble $range" | grep -P 'callq.*plt' \
    | sed -e 's/^.*</break /' \
          -e 's/>,*$/\ncommands\ncontinue\nend/' > "$commands"

echo run -C conscious.s+ >> "$commands"

gdb -x "$commands" -batch "$program"
