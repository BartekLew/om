#include<stdio.h>
#include<stdbool.h>
#include<string.h>

#include "text.h"

#define N_Test_files 3
const char *Test_files[N_Test_files] = { "test.c", "text.c", "text.h" };

#define N_Non_existent_files 2
const char *Non_existent_files[N_Non_existent_files] = { "foo.bar.baz", "bebe231232sczx" };

bool fail = false;

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

#define assert( CONDITION ) \
    if( !(CONDITION) ) { \
        printf( "om-test: assert fail: '%s' @ %s:%u.\n", \
            #CONDITION, __FILE__, __LINE__ \
        ); \
        fail = true; \
    }

#define assert_string( A, B ) \
    if( (A).len != (B).len \
        || strncmp( (A).text, (B).text, (B).len ) != 0 ) { \
        printf( "om-test: assert '%.*s' != '%.*s'. (line %d)\n", \
                (A).len, (A).text, (B).len, (B).text, \
                __LINE__\
        ); \
        fail = true; \
    }

#define assert_source( SELECTION, TXT ) \
    if( (SELECTION).source.text == NULL \
        || (SELECTION).source.text < (TXT).text \
        || (SELECTION).source.text >= (TXT).text + (TXT).len \
        || (SELECTION).source.text + (SELECTION).source.len > (TXT).text + (TXT).len ) { \
        printf( "om-test: assert source failed: %p/%u !~= %p/%u.\n", \
            (SELECTION).source.text, (SELECTION).source.len, (TXT).text, (TXT).len \
        ); \
        fail = true; \
    }


Selection selection_test_case( Txt input, Txt pattern, bool found ) {
    Selection s = selection( input, pattern );
    if( found ) {
        assert_source( s, input );
        assert_string( selection_text(s), pattern );
    } else {
        assert( s.source.text == NULL )
    }

    return s;
}

void compare_to_txt( Txt txt, Ctx ctx ) {
    assert( txt.text != NULL );

    Txt *user = (Txt*)ctx.user;
    assert( user != NULL );
    
    assert_string( txt, *user );
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

    Txt input;
    Selection s = selection_test_case(
        input = _Txt( "I want you to get only word 'fooo!' and nothing else, even 'fooo!'…" ),
        _Txt( "fooo!" ), true
    );
    selection_test_case( before(s), _Txt( "fooo!" ), false );
    s = selection_test_case( after(s), _Txt( "fooo!" ), true );
    
    Selection s2 = selection_test_case( input, _Txt( "even 'fooo!'"), true );
    assert( s2.source.text + s2.start == s.source.text + s.start - 6 );
    assert( s2.len == s.len + 7 );

    selection_test_case( _Txt( "" ), _Txt( "anything" ), false );
    selection_test_case( _Txt( "anything you would like" ), _Txt( "" ), false );

    Txt expected = _Txt( "Hello world!" );
    s = selection_test_case( _Txt( "Hello what?!" ), _Txt( "what?" ), true );
    with_subst( s, _Txt( "world" ),
        (Handlers) { .txt = &compare_to_txt,
                     .err=&no_error,
                     .user_data =  &expected }
    );

    input = _Txt( "Foo\nBar baz 000\nbazooo" );
    s = line( input, 6 );
    assert_source( s, input );
    assert_string( selection_text(s), _Txt( "Bar baz 000" ) );

    s = word( input, 5 );
    assert_source( s, input );
    assert_string( selection_text(s), _Txt( "Bar" ) );

    if( fail ) {
        printf( "\n" );
        return 1;
    }

    return 0;
}

