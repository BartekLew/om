function put( text ) {
    print "    " text
}

function warn( text ) {
    print "asmp.awk: " text " @ " FILENAME ":" NR > "/dev/stderr"
}

function par( val, name, register ) {
    if( length( val ) == 0 )
        warn( "missing parameter " name );

    if( val != register ) {
        if( val == "$0" )
            put( "xorq " register ", " register )
        else put( "movq " val ", " register )
    }
}

function action( label, name, test, testval ) {
    if( length( label ) == 0 )
        warn( "missing action " name );

    if( length( testval ) == 0 )
        testval = "$0";

    if( test == "je" && testval == "$0" ) {
        put( "test %rax, %rax" );
        put( "jz " label );
    }
    else if( test == "jne" && testval == "$0" ) {
        put( "test %rax, %rax" );
        put( "jnz " label );
    }
    else {
        put( "cmpq " testval ", %rax" );
        put( test " " label );
    }
}

function syscall( number ) {
    if( number == 0 )
         put( "xorq %rax, %rax" );
    else put( "movq $" number ", %rax" );

    put( "syscall\n" );
}

/^\s*open\s/ {
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
    
    next
}

/^\s*stat\s/ {
    par( $2, "file descriptor", "%rdi" );
    par( $3, "stat buffer", "%rsi" );
    syscall( 5 );
    action( $4, "stat error", "jne", "$0" );

    next
}

/^\s*read\s/ {
    par( $2, "file descriptor", "%rdi" );
    par( $3, "read buffer", "%rsi" );
    par( $4, "buffer size", "%rdx" );
    syscall( 0 );
    action( $5, "read error", "jl", "$0" );

    next
}

{ print $0; }
