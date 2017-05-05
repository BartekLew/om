#include <stdio.h>
#include <stdlib.h>
#include "text.h"

const char Doesnt_exist_text[] = "can't open file";
#define _Txt(CONST_STR) (Txt) { \
    .text = CONST_STR, .len = sizeof(CONST_STR) \
}

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

