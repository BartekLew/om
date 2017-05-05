#include <stdio.h>
#include <stdlib.h>
#include "text.h"

const char Doesnt_exist_text[] = "can't open file: %s.\n";

void on_text_file( c_Str name, TxtHandler handler ) {
    FILE *handle = fopen( name, "r" );
    if( handle == NULL ) {
        fprintf( stderr, Doesnt_exist_text, name );
        return;
    }

    fseek( handle, 0, SEEK_END );
    size_t size = ftell(handle);
    fseek( handle, 0, SEEK_SET );

    char buffer[size];
    if( fread( buffer, size, 1, handle ) != 1 ) 
        fprintf( stderr, "error reading file %s.\n", name );
    else
        handler( (Txt){ .len = size, .text = buffer },
                 (Ctx){ .file = name, .pos = 0 } );
    
    fclose(handle);
}

