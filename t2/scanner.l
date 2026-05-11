%{
#include <stdio.h>
#include <stdlib.h>

static int line_no = 1;
%}

%option noyywrap

INT        -?[0-9]+
ID         [a-zA-Z_][a-zA-Z0-9_?!-]*
WS         [ \t\r]+
COMMENT    ;[^\n]*

%%

"("                 { printf("LPAREN\n"); }
")"                 { printf("RPAREN\n"); }

"define"            { printf("DEFINE\n"); }
"if"                { printf("IF\n"); }
"let"               { printf("LET\n"); }
"set!"              { printf("SET\n"); }

"+"                 { printf("PLUS\n"); }
"-"                 { printf("MINUS\n"); }
"*"                 { printf("MUL\n"); }
"/"                 { printf("DIV\n"); }

"<"                 { printf("LT\n"); }
">"                 { printf("GT\n"); }
"="                 { printf("EQ\n"); }

"and"               { printf("AND\n"); }
"or"                { printf("OR\n"); }
"not"               { printf("NOT\n"); }

"#t"|"#f"          { printf("BOOL(%s)\n", yytext); }
{INT}               { printf("INT(%s)\n", yytext); }
{ID}                { printf("ID(%s)\n", yytext); }

{WS}                { /* ignore whitespace */ }
{COMMENT}           { /* ignore comment */ }
\n                  { line_no++; }

.                   {
                      fprintf(stderr, "Lexical error at line %d: unexpected character '%s'\n", line_no, yytext);
                      exit(1);
                    }

%%

int main(void) {
    yylex();
    return 0;
}
