#include<stdio.h>
#include<stdlib.h>
#include<stdbool.h>
#include<string.h>
#include<unistd.h>
#include<poll.h>

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

void doesnt_exist( Txt input, Ctx ctx ) {
    if( fopen( ctx.file, "r" ) != NULL ) {
        printf( "om-test: '%s' file exists, shouldn't!.\n", ctx.file );

    } else if( input.len != 0 ) {
        printf( "om-test: '%s' file shouldn't exist, but on_text_file give content!.\n", ctx.file );
    }
}

void get_no_exist( int fd, c_Str file_name ) {
    size_t text_len = strlen(Doesnt_exist_text) + strlen(file_name) - 1;
    char text[text_len];
    char pipe_content[text_len];

    sprintf( text, Doesnt_exist_text, file_name );
    size_t pipe_bytes = read( fd, pipe_content, text_len );
    if( pipe_bytes + 1 != text_len
        || strncmp( pipe_content, text, pipe_bytes ) != 0 ) 
        printf( "wrong error, should be no_exist, is:\n'%.*s'<<<<<<\n'%.*s'\n", pipe_bytes, pipe_content, text_len, text );
}

void test_file_content( int error_pipe ) {
    for( unsigned int i = 0; i < N_Test_files; i++ ) 
        on_text_file( Test_files[i], &compare );

    for( unsigned int i = 0; i < N_Non_existent_files; i++ ) {
        on_text_file( Non_existent_files[i], &doesnt_exist );
        get_no_exist( error_pipe, Non_existent_files[i] );
    }
    
    struct pollfd fds[] = { { .fd = error_pipe, .events = POLLIN } };
    if( poll( fds, 1, 0 ) > 0 ) {
        char remainder[1000];
        read( error_pipe, remainder, 1000 );
        printf( "om-test: excessive error text: %.*s...\n", 10, remainder );
    }
}

void redirect_stdout( void (*action)(int fd) ) {
    int fd[2];
    pipe(fd);
    dup2(fd[1], 2); // stderr to pipe

    action( fd[0] );

    close(fd[0]);
    close(fd[1]);
}

int main( int n_args, char **args ) {
    redirect_stdout( &test_file_content );

    return 0;
}
