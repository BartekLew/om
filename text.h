#ifndef __HEADER_TEXT
#define __HEADER_TEXT

typedef struct text{
    const char *text;
    size_t len;
} Text;

typedef const char *c_str;

typedef void (*TextHandler)( Text content, c_str file_name );
extern const char Doesnt_exist_text[];

void on_text_file( c_str name, TextHandler handler, c_str parameter );

#endif
