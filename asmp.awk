BEGIN {
    print "\n# asmp footer:" > "/tmp/asmp.tmp";
}

function put( text ) {
    print "    " text
}

function warn( text ) {
    print "asmp.awk: " text " @ " FILENAME ":" NR > "/dev/stderr"
}

function check_par( val, name ) {
    if( length( val ) == 0 )
        warn( "missing parameter " name );
}

function par( val, name, register ) {
    check_par( val, name );

    if( val != register ) {
        if( val == "$0" )
            put( "xorq " register ", " register )
        else put( "movq " val ", " register )
    }
}

function action( label, name, test, testval ) {
    if( length( testval ) == 0 )
        testval = "$0";

    if( test == "je" && testval == "$0" ) {
        put( "test %rax, %rax" );
        put( "jz " label "\n" );
    }
    else if( test == "jne" && testval == "$0" ) {
        put( "test %rax, %rax" );
        put( "jnz " label "\n" );
    }
    else {
        put( "cmpq " testval ", %rax" );
        put( test " " label "\n" );
    }
}

function syscall( number ) {
    if( number == 0 )
         put( "xorq %rax, %rax" );
    else put( "movq $" number ", %rax" );

    put( "syscall\n" );
}

function result( destination ) {
    if( length( destination ) > 0 )
        put( "movq %rax, " destination );
}

/^\s*open\s/ {
    put( "#" $0 );
    switch( $2 ) {
        case "ro":
            put( "xorq %rsi, %rsi # ro" );
            break
        case "rw":
            put( "movq $2, %rsi # rw" );
            break
        default:
            put( "xorq %rsi, %rsi # ro" );
            warn( "wrong open mode: " $2 ", assuming ro" );
    }

    par( $3, "open file name", "%rdi" );
    par( "$0", "mode", "%rdx" );
    syscall( 2 );
    action( $4, "open error", "jng", "$2" );
    result( $5 );
    
    next
}

/^\s*close\s/ {
    put( "#" $0 );
    par( $2, "file descriptor", "%rdi" );
    syscall( 3 );
    next;
}

/^\s*stat\s/ {
    put( "#" $0 );
    par( $2, "file descriptor", "%rdi" );
    par( $3, "stat buffer", "%rsi" );
    syscall( 5 );
    action( $4, "stat error", "jne", "$0" );

    next
}

/^\s*read\s/ {
    put( "#" $0 );
    par( $2, "file descriptor", "%rdi" );
    par( $3, "read buffer", "%rsi" );
    par( $4, "buffer size", "%rdx" );
    syscall( 0 );
    action( $5, "read error", "jl", "$0" );

    next
}

/^\s*read\+\s/ {
    put( "#" $0 );
    par( $2, "file descriptor", "%rdi" );
    par( $3, "read buffer", "%rsi" );
    par( $4, "buffer size", "%rdx" );
    syscall( 0 );
    action( $5, "read error", "jle", "$0" );

    next
}

/^\s*write\??\s/ {
    put( "#" $0 );
    par( $2, "file descriptor", "%rdi" );

    if( substr( $3, 1, 1 ) == "\"" ) {
        str_start = index( $0, $3 ) + 1;
        rest=substr($0, str_start);
        string=substr(rest,1, index(rest, "\"") - 1);

        escapes = 0;
        remaining = string;
        while( ( pos = match( remaining, /\\/ ) ) > 0 ) {
            escapes++;
            remaining = substr( remaining, pos+1 );
        }

        label = "str_" NR;
        print label ": .ascii \"" string "\"" > "/tmp/asmp.tmp"
        put( "movq $" label ", %rsi" );
        put( "movq $" length(string) - escapes ", %rdx" );
    }
    else {
        par( $3, "write buffer", "%rsi" );
        par( $4, "write length", "%rdx" );
    }

    syscall( 1 );
    if( $1 == "write" )
        action( $5, "write error", jne, $4 );

    next;
}

/^\s*pipe\s/ {
    put( "#" $0 );
    par( $2, "pipe descriptors int[2]", "%rdi" );
    syscall( 22 );
    
    next;
}

/^\s*fork\s/ {
    put( "#" $0 );

    check_par( $2, "child code entry" );
    syscall( 57 );

    put( "cmpq $0, %rax" );
    put( "jg " $2 "\n" );

    next;
}
    
/^\s*cpfd\s/ {
    put( "#" $0 );
    par( $2, "descriptor to copy", "%rdi" );
    par( $3, "copy to descriptor no.", "%rsi" );
    syscall( 33 );

    next;
}

/^\s*exec\s/ {
    put( "#" $0 );
    check_par( $2, "program to execute" );

    par_offset = NF * 8;
    for( i = 2; i <= NF ; i++ ) {
        label = "exec_" NR "_" i;
        print label ":\n    .asciz " $i > "/tmp/asmp.tmp"
        put( "movq $" label ", -" par_offset "(%rsp)" );
        par_offset -= 8;
    }
    put( "movq $0, -" par_offset " (%rsp)" );

    put( "movq $exec_" NR "_2, %rdi" );
    put( "leaq -" NF*8 "(%rsp), %rsi" );
    put( "leaq -" par_offset "(%rsi), %rdx" );
    syscall( 59 );

    next;
}


/^\s*int2str\s/ {
    put( "#" $0 );
    par( $2, "number to convert", "%rdi" );
    par( $3, "buffer", "%rsi" );
    put( "call int_to_str\n" );
    next
}

/^\s*quit\s/ {
    put( "#" $0 );
    if( length( $2 ) == 0 || $2 == 0 ) 
        put( "xorq %rdi, %rdi" );
    else
        put( "movq $" $2 ", %rdi" );

    syscall( 60 );
    next
}
    
{ print $0; }
