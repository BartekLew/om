#include <stdio.h>
#include <string.h>
#include "text.h"


void work( Txt txt, Ctx ctx ) {
    char line[85];
    while( fgets( line, 84, stdin ) != NULL ) {
        if( strcmp( line, "*\n" ) == 0 )
            fwrite( txt.text, txt.len, 1, stdout );
        else
            fprintf( stderr, "!!ERR wrong command: %s", line );
    }
}

void fail( Txt txt, Ctx ctx ) {
    fprintf( stderr, "!!ERR %.*s / %s.\n", txt.len, txt.text, ctx.file );
}


int main( int argc, char **args ) {
    if( argc != 2 ) {
        printf( "USAGE: om [file]\n" );
        return 1;
    }

    on_text_file( args[1],
        (Handlers) { .txt = &work, .err = &fail }
    );

    return 0;
}
