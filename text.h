#ifndef __HEADER_TEXT
#define __HEADER_TEXT

typedef const char *c_Str;

typedef struct text{
    c_Str  text;
    size_t len;
} Txt;

typedef struct context{
   c_Str file;
   int   pos;
} Ctx;

typedef void (*TxtHandler)( Txt, Ctx );


void on_text_file( c_Str name, TxtHandler handler );


extern const char Doesnt_exist_text[];

#endif
