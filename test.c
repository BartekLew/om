#include<stdio.h>
#include<stdbool.h>
#include<string.h>

#include "text.h"

#define N_Test_files 3
const char *Test_files[N_Test_files] = { "test.c", "text.c", "text.h" };

#define N_Non_existent_files 2
const char *Non_existent_files[N_Non_existent_files] = { "foo.bar.baz", "bebe231232sczx" };


void compare( Txt txt, Ctx ctx ) {
    FILE *handle = fopen( ctx.file, "r" );
    if( handle == NULL ) return;

    fseek( handle, 0, SEEK_END );
    size_t size = ftell(handle);
    fseek( handle, 0, SEEK_SET );

    bool success = false;

    if( size == txt.len ){
        char buffer[size];
        if( fread( buffer, size, 1, handle ) == 1
            && strncmp( buffer, txt.text, size ) == 0 )
            success = true;
    }

    if( !success )
        printf( "om-test: file '%s' read failed.\n", ctx.file );

    fclose( handle );
}

void no_error( Txt txt, Ctx ctx ) {
    printf( "om-test: no error expected, but caught %s/%d.\n",
            ctx.file, ctx.pos
    );
}

void doesnt_exist( Txt txt, Ctx ctx ) {
    if( txt.text != Doesnt_exist_text )
        printf(
            "om-test: expected file that doesn't exist, but other error found: '%.*s'.\n",
            txt.len, txt.text
        );
}

void shouldnt_exist( Txt input, Ctx ctx ) {
    FILE *f;
    if( ( f = fopen( ctx.file, "r" ) ) != NULL ) {
        printf( "om-test: '%s' file exists, shouldn't!.\n", ctx.file );
        fclose( f );

    } else if( input.len != 0 ) {
        printf( "om-test: '%s' file shouldn't exist, but on_text_file give content!.\n", ctx.file );
    }
}

int main( void ) {
    for( unsigned int i = 0; i < N_Test_files; i++ ) 
        on_text_file( Test_files[i],
            (Handlers){ .txt = &compare, .err = &no_error }
        );

    for( unsigned int i = 0; i < N_Non_existent_files; i++ )
        on_text_file( Non_existent_files[i],
            (Handlers){ .txt = &shouldnt_exist, .err=&doesnt_exist }
        );

    return 0;
}

