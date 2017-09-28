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

function par_addr( val, name, register ) {
    check_par( val, name );

    if( val != register ) {
        if( val ~ /\(.+\)/ ) 
            put( "leaq " val ", " register );
        else if( val == "$0" )
            put( "xorq " val ", " val );
        else
            put( "movq " val ", " register );
    }
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

function get_quote( string, idx ) {
    if( substr( string, idx, 1 ) == "\"" ) {
        start = idx + 1;
        rest = substr( string, start );
        quot = match( rest, /[^\\]"/ );
        if( quot <= 0 ) {
            warn( "quote mismatch" );
            return "";
        }
        return substr( rest, 1, quot );
    }

    return "";
}

/^\s*open\s/ {
    put( "#" NR ": " $0 );
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
    put( "#" NR ": " $0 );
    par( $2, "file descriptor", "%rdi" );
    syscall( 3 );
    next;
}

/^\s*stat\s/ {
    put( "#" NR ": " $0 );
    par( $2, "file descriptor", "%rdi" );
    par( $3, "stat buffer", "%rsi" );
    syscall( 5 );
    action( $4, "stat error", "jne", "$0" );

    next
}

/^\s*read\s/ {
    put( "#" NR ": " $0 );
    par( $2, "file descriptor", "%rdi" );
    par_addr( $3, "read buffer", "%rsi");
    par( $4, "buffer size", "%rdx" );
    syscall( 0 );
    action( $5, "read error", "jl", "$0" );

    next
}

/^\s*read\+\s/ {
    put( "#" NR ": " $0 );
    par( $2, "file descriptor", "%rdi" );
    par_addr( $3, "read buffer", "%rsi" );
    par( $4, "buffer size", "%rdx" );
    syscall( 0 );
    action( $5, "read error", "jle", "$0" );

    next
}

/^\s*write\??\s/ {
    put( "#" NR ": " $0 );
    par( $2, "file descriptor", "%rdi" );

    quoted = get_quote( $0, index( $0, $3 ));
    if( length( quoted ) > 0 ) {
        escapes = 0;
        remaining = quoted;
        while( ( pos = match( remaining, /\\/ ) ) > 0 ) {
            escapes++;
            remaining = substr( remaining, pos+1 );
        }

        label = "str_" NR;
        print label ": .ascii \"" quoted "\"" > "/tmp/asmp.tmp"
        put( "movq $" label ", %rsi" );
        put( "movq $" length(quoted) - escapes ", %rdx" );
    }
    else {
        par_addr( $3, "write buffer", "%rsi" );
        par( $4, "write length", "%rdx" );
    }

    syscall( 1 );
    if( $1 == "write" )
        action( $5, "write error", jne, $4 );

    next;
}

/^\s*pipe\s/ {
    put( "#" NR ": " $0 );
    check_par( $2, "pipe descriptors int[2]" );
    put( "leaq " $2 ", %rdi" );
    syscall( 22 );
    
    next;
}

/^\s*fork\s/ {
    put( "#" NR ": " $0 );

    check_par( $2, "child code entry" );
    syscall( 57 );

    put( "test %rax, %rax" );
    put( "jz " $2 "\n" );

    next;
}
    
/^\s*cpfd\s/ {
    put( "#" NR ": " $0 );
    par( $2, "descriptor to copy", "%rdi" );
    par( $3, "copy to descriptor no.", "%rsi" );
    syscall( 33 );

    next;
}

/^\s*exec\s/ {
    put( "#" NR ": " $0 );
    check_par( $2, "program to execute" );

    remaining = substr( $0, index( $0, $2 ) );
    arg_c = 0;
    while( 1 ){
        quot = get_quote( remaining, 1 );
        if( length( quot ) > 0 ) {
            arg_c++;
            
            label = "exec_" NR "_" arg_c;
            print label ": .asciz \"" quot "\"" > "/tmp/asmp.tmp"
    
            remaining = substr(remaining, length(quot) + 3);
            remaining = substr(remaining, match( remaining, /[^[:space:]]/ ) );

            continue
        }
        if( substr( remaining, 1, 1 ) == "&" ) {
            arg_c++;

            name_end = match( remaining, /[[:space:]]/ );
            src = substr( remaining, 2, name_end - 2 );

            label = "exec_" NR "_" arg_c;
            printf label ": .asciz \"" > "/tmp/asmp.tmp"
            while( (getline line < src ) > 0 ) {
                gsub( /"/, "\\\"", line );
                printf line "\\n" > "/tmp/asmp.tmp"
            }
            print "\"" > "/tmp/asmp.tmp"

            remaining = substr( remaining, name_end );
            remaining = substr(remaining, match( remaining, /[^[:space:]]/ ) );

            continue
        }
        else break;

    }

    par_offset = (arg_c+1) * 8;
    for( i = 1; i <= arg_c; i++ ) {
        label = "exec_" NR "_" i;
        put( "movq $" label ", -" par_offset "(%rsp)" );
        par_offset -= 8;
    }

    put( "movq $0, -" par_offset "(%rsp)" );

    put( "movq $exec_" NR "_1, %rdi" );
    put( "leaq -" (arg_c+1)*8 "(%rsp), %rsi" );
    put( "leaq -" par_offset "(%rsp), %rdx" );
    syscall( 59 );

    next;
}


/^\s*int2str\s/ {
    put( "#" NR ": " $0 );
    par( $2, "number to convert", "%rdi" );
    par( $3, "buffer", "%rsi" );
    put( "call int_to_str\n" );
    next
}

/^\s*quit\s/ {
    put( "#" NR ": " $0 );
    if( length( $2 ) == 0 || $2 == 0 ) 
        put( "xorq %rdi, %rdi" );
    else
        put( "movq $" $2 ", %rdi" );

    syscall( 60 );
    next
}
    
{ print $0; }
