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
           (Ctx){ .file = name }
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
           (Ctx){ .file =  name }
        );
    else
        handlers.txt(
            (Txt){ .len = size, .text = buffer },
            (Ctx){ .file = name, .pos = 0 }
        );
    
    fclose(handle);
}

Selection selection( Txt src, Txt pattern ) {
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

    return (Selection) {.source.text=NULL};
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
