#ifndef __HEADER_TEXT
#define __HEADER_TEXT

typedef const char *c_Str;

typedef struct text{
    c_Str  text;
    size_t len;
} Txt;

#define _Txt(CONST_STR) (Txt) { \
    .text = CONST_STR, .len = sizeof(CONST_STR)-1 \
}


typedef struct context{
   c_Str file;
   int   pos;
} Ctx;

typedef void (*Handler)( Txt, Ctx );
typedef struct handler_set{
    Handler txt, err;
} Handlers;

void on_text_file( c_Str name, Handlers handlers );


typedef unsigned int uint;

typedef struct selection {
    Txt     source;
    uint   start;
    size_t  len;
} Selection;

#define No_selection (Selection) {.source.text=NULL}

Selection selection( Txt source, Txt pattern );
Txt selection_text( Selection s );
Txt before( Selection s );
Txt after( Selection s );

extern const char Doesnt_exist_text[];

#endif
