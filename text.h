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

typedef void (*Handler)( Txt, Ctx );
typedef struct handler_set{
    Handler txt, err;
} Handlers;


void on_text_file( c_Str name, Handlers handlers );


extern const char Doesnt_exist_text[];

#endif
