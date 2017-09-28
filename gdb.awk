/Entry point/ {
    print "break *" $3; 
    print "run < conscious";
    system("");
} 

/Breakpoint [[:digit:]]+, 0x/ {
    print "x/i " $3;
    print "stepi";
    system("");
}

/0x[[:xdigit:]]+ in/ {
    gsub( /^.*0x/, "0x" );
    print "x/i " $1;
    print "stepi";
    system("");
}

/=>/ {
    gsub( /^.*=/, "=" );
    print $0;
    system("");
}

/^.*0x[[:xdigit:]]+:/ {
    gsub( /^/, "=> " );
    print $0;
    system("");
}

{
    print $0 > "/tmp/conscious.log"
    system("");
}
