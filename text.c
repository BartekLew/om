#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "text.h"

const char Doesnt_exist_text[] = "can't open file";

void on_text_file( c_Str name, Handlers handlers ) {
    FILE *handle = fopen( name, "r" );
    if( handle == NULL ) {
        handlers.err(
           _Txt(Doesnt_exist_text),
           (Ctx){ .file = name,
                  .user = handlers.user_data }
        );
        return;
    }

    fseek( handle, 0, SEEK_END );
    size_t size = ftell(handle);
    fseek( handle, 0, SEEK_SET );

    char buffer[size];
    if( fread( buffer, size, 1, handle ) != 1 ) 
        handlers.err(
            _Txt( "error reading file.\n" ),
           (Ctx){ .file =  name,
                  .user = handlers.user_data }
        );
    else
        handlers.txt(
            (Txt){ .len = size, .text = buffer },
            (Ctx){ .file = name, .pos = 0,
                   .user = handlers.user_data }
        );
    
    fclose(handle);
}

Selection selection( Txt src, Txt pattern ) {
    if( src.len < pattern.len || pattern.len == 0 )
        return No_selection;

    uint i = 0;
    for( ; i < src.len - pattern.len; i++ ) {
        if( strncmp( 
                src.text + i, pattern.text,
                pattern.len ) == 0 )
            return (Selection){
                .source = src,
                .start = i, .len = pattern.len
            };
    }

    return No_selection;
}

Txt selection_text( Selection s ) {
    if( s.source.text == NULL )
        return (Txt){ .text = NULL };

    return (Txt) {
        .text = s.source.text + s.start,
        .len = s.len
    };
}

Txt before( Selection s ) {
    if( s.source.text == NULL
        || s.start+s.len > s.source.len )
        return (Txt) { .text=NULL };

    return (Txt) {
        .text = s.source.text,
        .len = s.start
    };
}

Txt after( Selection s ) {
    if( s.source.text == NULL
        || s.start+s.len > s.source.len )
        return (Txt) { .text=NULL };

    return (Txt) {
        .text = s.source.text + s.start + s.len,
        .len = s.source.len - s.start - s.len
    };
}

#define rchar register char

Selection line( Txt txt, uint pos ) {
    rchar c = txt.text[pos];
    Selection w = (Selection) {
        .source = txt, .start = pos
    };

    if( c == '\n' ) return w;
    w.len = 1;

    for( uint i = pos+1; i < txt.len
                         && txt.text[i] != '\n' ; i++ )
        w.len++;

    for( int i = pos-1; i >= 0
                         && txt.text[i] != '\n' ; i-- ) {
        w.start--;
        w.len++;
    }

    return w;
}

Selection word( Txt txt, uint pos ) {
    rchar c = txt.text[pos];
    Selection w = (Selection) {
        .source = txt, .start=pos
    };

    if( !isdigit(c) && !isalpha(c) ) return w;
    w.len = 1;

    for( uint i = pos+1; i < txt.len
                         && ( isdigit( c=txt.text[i] )
                           || isalpha(c) ) ; i++ )
        w.len++;
         
    for( int i = pos-1; i >= 0
                         && ( isdigit( c=txt.text[i] )
                           || isalpha(c) ) ; i-- ) {
        w.start--;
        w.len++;
    }

    return w;
}

void with_subst( Selection s, Txt txt, Handlers handlers ) {
    if( s.source.text == NULL )
        handlers.err(
            _Txt( "substiton on invalid selection" ),
            (Ctx) { .file = "##", .user = handlers.user_data }
        );

    char buffer[ s.source.len - s.len + txt.len ];
    strncpy( buffer, s.source.text, s.start );
    strncpy( buffer + s.start, txt.text, txt.len );
    strncpy( buffer + s.start + txt.len,
             s.source.text + s.start + s.len,
             s.source.len - s.start - s.len
    );

    handlers.txt(
        txt_of( buffer, sizeof(buffer) ),
        (Ctx){ .user = handlers.user_data }
    );
}

