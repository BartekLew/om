BEGIN {
    print ".text";
    stack_offset=0;
    code_footer = "/tmp/liberation_build.tmp";
}

NR == 1 {
    module_name = FILENAME;
    gsub( /\.s\+$/, "", module_name );

    print ".globl _start";
    print "start_" module_name ":";
}

{ 
    if( match( $0, /[^[:space:]]/ ) > 0 ) {
        if( $0 ~ /^\s*[[:alpha:][:digit:]_]+:\s*$/ )
            print $0;
        else
            print "\n# " NR ": " $0;
    }
}

function put( text ) {
    print "    " text
}

function local( size ) {
    stack_offset += size;
    return "-" stack_offset "(%rsp)";
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

function warn( text ) {
    print "liberation.awk: " text " @ " FILENAME ":" NR > "/dev/stderr"
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

function syscall( number ) {
    if( number == 0 )
         put( "xorq %rax, %rax" );
    else put( "movq $" number ", %rax" );

    put( "syscall" );
}

function closefd( descriptor ) {
    print "\n# close " descriptor;

    par( descriptor, "file descriptor", "%rdi" );
    syscall( 3 );
}

function cpfd( from, to ){
    print "\n# cpfd " from "  " to;

    par( from, "descriptor to copy", "%rdi" );
    par( to, "copy to descriptor no.", "%rsi" );
    syscall( 33 );
}

function write_to( descriptor ) {
    cpfd( descriptor, "$1" );
}

function read_from( descriptor ) {
    cpfd( descriptor, "$0" );
}

function pipe_out( pipe_name ) {
    return pipe[pipe_name];
}

function pipe_in( pipe_name ) {
    pos = match( pipe[pipe_name], /\(/ );
    if( pos < 0 )
        warn( "wrong pipe: " pipe[pipe_name] );
    else if( pos == 0 )
        return "-4" pipe[pipe_name];
    else{
        in_offset = substr( pipe[pipe_name], 2, pos-1 );
        base = substr( pipe[pipe_name], pos );

        return "-" (in_offset - 4) base;
    }
}

function exec( exec_string ) {
    remaining = exec_string;

    print "\n# exec " exec_string;
    delete exec_args;

    arg_c = 0;
    while( 1 ){
        quot = get_quote( remaining, 1 );
        if( length( quot ) > 0 ) {
            arg_c++;
            
            label = "exec_" NR "_" arg_c;
            print label ": .asciz \"" quot "\"" > code_footer
    
            exec_args[arg_c] = "$exec_" NR "_" arg_c;

            remaining = substr(remaining, length(quot) + 3);
            remaining = substr(remaining, match( remaining, /[^[:space:]]/ ) );

            continue
        }
        if( substr( remaining, 1, 1 ) == "&" ) {
            arg_c++;

            name_end = match( remaining, /[[:space:]]/ );
            src = substr( remaining, 2, name_end - 2 );

            label = "exec_" NR "_" arg_c;
            printf label ": .asciz \"" > code_footer
            while( (getline line < src ) > 0 ) {
                gsub( /"/, "\\\"", line );
                printf line "\\n" > code_footer
            }
            print "\"" > code_footer

            exec_args[arg_c] = "$exec_" RN "_" arg_c;

            remaining = substr( remaining, name_end );
            remaining = substr(remaining, match( remaining, /[^[:space:]]/ ) );

            continue
        } if( substr( remaining, 1, 1 ) == "$" ) {
            arg_c++;
            spos = match( remaining, /[[:space:]]/ );
            if( spos == 0 ) spos = length( remaining );
            var_name = substr( remaining, 2, spos-1 );
            if( var_name ~ /^[[:digit:]]+$/ ) {
                if( length( min_argc ) == 0 )
                    min_argc = 2;
                exec_args[arg_c] = var_name * 8 "(%rsp)";
            }

            remaining = substr( remaining, spos );
            remaining = substr( remaining, match( remaining, /[^[:space:]]/ ) );

            continue
        }
        else break;

    }

    par_offset = par_start = stack_offset + (arg_c+1) * 8;
    for( i = 1; i <= arg_c; i++ ) {
        x = exec_args[i];
        if( x ~ /(%[[:alpha:]]+)/ ) {
            put( "movq " x ", %rax" );
            x = "%rax";
        }

        put( "movq " x ", -" par_offset "(%rsp)" );
        par_offset -= 8;
    }

    put( "movq $0, -" par_offset "(%rsp)" );

    put( "movq " exec_args[1] ", %rdi" );
    put( "leaq -" par_start "(%rsp), %rsi" );
    put( "leaq -" par_offset "(%rsp), %rdx" );
    syscall( 59 );
}

function stat( descriptor, destination ) {
    print "\n# stat " descriptor " " destination;
    
    par( descriptor, "file descriptor", "%rdi" );
    par_addr( destination, "stat buffer", "%rsi" );
    syscall( 5 );
}

function read( descriptor, buffer, size ) {
    par( descriptor, "file descriptor", "%rdi" );
    par_addr( buffer, "read buffer", "%rsi");
    par( size, "buffer size", "%rdx" );

    if( (n = length( read_prompt )) > 0 ) {
        put( "movq %rsi, %r8" );

        print "read_" NR ":";
        syscall( 0 );
        put( "addq %rax, %rsi" );
        put( "subq %rax, %rdx" );
        put( "jl   read_buffer_too_small" );
        
        for( i = 0; i < n; i++ ) {
            put( "movb -" n - i "(%rsi), %al" );
            put( "cmpb $'" substr( read_prompt, i+1, 1)  ", %al" );
            put( "jne  read_" NR );
        }

        put( "movq %rsi, %rax" );
        put( "subq %r8, %rax" );
        put( "movq %r8, %rsi" );
    }
    else
        syscall( 0 );
}

function quit( exit_code ){
    print "\n# quit " exit_code;

    if( exit_code == 0 ) 
        put( "xorq %rdi, %rdi" );
    else
        put( "movq $" exit_code ", %rdi" );

    syscall( 60 );
}

/^\s*fork\s/ {
    fork_name = substr( $2, 1, length($1)-1 );

    pipe[ "for_" fork_name ] = x = local(8);
    print "\n# pipe for_" fork_name;
    put( "leaq " x ", %rdi" );
    syscall( 22 );

    pipe[ "from_" fork_name ] = x = local(8);
    print "\n# pipe from_" fork_name;
    put( "leaq " x ", %rdi" );
    syscall( 22 );

    print "\n# fork";
    syscall( 57 );

    print "";
    put( "test %rax, %rax" );
    put( "jnz parent_" NR );

    closefd( pipe_in( "for_" fork_name ) );
    read_from( pipe_out( "for_" fork_name ) );
    write_to( pipe_in( "from_" fork_name ) );
    closefd( pipe_out( "from_" fork_name ) );
    
    exec( substr( $0, index( $0, $3 ) ) );
    quit( 1 );

    print "\nparent_" NR ":";
    closefd( pipe_out( "for_" fork_name ) );
    closefd( pipe_in( "from_" fork_name ) );

    next;
}

/^\s*read_prompt\s/ {
    if( $2 == "off" )
        read_prompt="";
    else {
        quoted = get_quote( $0, index( $0, $2 ) );
        if( length( quoted ) > 0 ) {
            read_prompt = quoted;
        } else
            warn("wrong read_prompt statement: " $0 );
    }
}

/^\s*read\s/ {
    if( $2 ~ /^\$[[:digit:]]$/ )
        output = $2;
    else
        output = pipe_out("from_" $2);

    print ".comm read_buff_" NR ", 8192, 32" > code_footer
    read( output, "$read_buff_" NR, "$8192" );
}

/^\s*write\s/ {
    if( $2 ~ /^\$[[:digit:]]+$/ )
        output = $2;
    else
        output = pipe_in("for_" $2);

    par( output, "descriptor", "%rdi" );

    quoted = get_quote( $0, index( $0, $3 ));
    if( length( quoted ) > 0 ) {
        escapes = 0;
        remaining = quoted;
        while( ( pos = match( remaining, /\\/ ) ) > 0 ) {
            escapes++;
            remaining = substr( remaining, pos+1 );
        }

        label = "str_" NR;
        print label ": .ascii \"" quoted "\"" > code_footer
        put( "movq $" label ", %rsi" );
        put( "movq $" length(quoted) - escapes ", %rdx" );
    }
    else {
        par_addr( $3, "write buffer", "%rsi" );
        par( $4, "write length", "%rdx" );
    }

    syscall( 1 );
}

/^\s*close\s/ {
    check_par( pipe[ "for_" $2 ], "pipe to close" );
    check_par( pipe[ "from_" $2 ], "pipe to close" );

    input = pipe_in( "for_" $2 );
    output = pipe_out( "from_" $2 );
    
    closefd( input );
    closefd( output);

}

/^\s*quit\s/ {
    check_par( $2, "exit code" );
    quit( $2 );
}

END {
    close( code_footer );
    print "\n# footer:\n"

    print "main:\n_start:";
    if( length( min_argc ) > 0 ) {
        put( "cmpq $" var_name ", (%rsp)" );
        put( "jl  wrong_argv\n" );
    }

    put( "jmp start_" module_name );
                

    while( ( getline line < code_footer ) > 0 ) {
        print line;
    }
}
