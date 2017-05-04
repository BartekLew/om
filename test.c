#include<stdio.h>
#include<stdlib.h>
#include<stdbool.h>
#include<string.h>
#include<unistd.h>

#include "text.h"

#define N_Test_files 3
const char *Test_files[N_Test_files] = { "test.c", "text.c", "text.h" };

#define N_Non_existent_files 2
const char *Non_existent_files[N_Non_existent_files] = { "foo.bar.baz", "bebe231232sczx" };


void compare( Text input, c_str file_name ) {
    FILE *handle = fopen( file_name, "r" );
    if( handle == NULL ) return;

    fseek( handle, 0, SEEK_END );
    size_t size = ftell(handle);
    fseek( handle, 0, SEEK_SET );

    bool success = false;

    if( size == input.len ){
        char buffer[size];
        if( fread( buffer, size, 1, handle ) == 1
            && strncmp( buffer, input.text, size ) == 0 )
            success = true;
    }

    if( !success )
        printf( "om-test: file '%s' read failed.\n", file_name );

    fclose( handle );
}

void doesnt_exist( Text input, c_str file_name ) {
    if( fopen( file_name, "r" ) != NULL ) {
        printf( "om-test: '%s' file exists, shouldn't!.\n", file_name );

    } else if( input.len != 0 ) {
        printf( "om-test: '%s' file shouldn't exist, but on_text_file give content!.\n", file_name );
    }
}

void get_no_exist( int fd, c_str file_name ) {
    size_t text_len = strlen(Doesnt_exist_text) + strlen(file_name) - 1;
    char text[text_len];
    char pipe_content[text_len];

    sprintf( text, Doesnt_exist_text, file_name );
    size_t pipe_bytes = read( fd, pipe_content, text_len );
    if( pipe_bytes + 1 != text_len
        || strncmp( pipe_content, text, pipe_bytes ) != 0 ) 
        printf( "wrong error, should be no_exist, is:\n'%.*s'<<<<<<\n'%.*s'\n", pipe_bytes, pipe_content, text_len, text );
}

int main( int n_args, char **args ) {
    int fd[2];
    pipe(fd);
    dup2(fd[1], 2); // stderr to pipe

    for( unsigned int i = 0; i < N_Test_files; i++ ) 
        on_text_file( Test_files[i], &compare, Test_files[i] );

    for( unsigned int i = 0; i < N_Non_existent_files; i++ ) {
        on_text_file( Non_existent_files[i], &doesnt_exist, Non_existent_files[i] );
        get_no_exist( fd[0], Non_existent_files[i] );
    }
        
    close(fd[0]);
    close(fd[1]);

    return 0;
}
