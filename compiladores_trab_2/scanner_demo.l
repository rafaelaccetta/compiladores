%{
#include <stdio.h>
#include <stdlib.h>

int line_no = 1;
%}

%option noyywrap

INT        -?[0-9]+
ID         [a-zA-Z_][a-zA-Z0-9_?!-]*
WS         [ \t\r]+
COMMENT    ;[^\n]*

%%

"("                 { printf("LPAREN       %s\n", yytext); }
")"                 { printf("RPAREN       %s\n", yytext); }

"define"            { printf("DEFINE       %s\n", yytext); }
"if"                { printf("IF           %s\n", yytext); }
"let"               { printf("LET          %s\n", yytext); }
"set!"              { printf("SET          %s\n", yytext); }

"+"                 { printf("PLUS         %s\n", yytext); }
"-"                 { printf("MINUS        %s\n", yytext); }
"*"                 { printf("MUL          %s\n", yytext); }
"/"                 { printf("DIV          %s\n", yytext); }

"<"                 { printf("LT           %s\n", yytext); }
">"                 { printf("GT           %s\n", yytext); }
"="                 { printf("EQ           %s\n", yytext); }

"and"               { printf("AND          %s\n", yytext); }
"or"                { printf("OR           %s\n", yytext); }
"not"               { printf("NOT          %s\n", yytext); }

"#t"                { printf("BOOL         #t\n"); }
"#f"                { printf("BOOL         #f\n"); }
{INT}               { printf("INT          %s\n", yytext); }
{ID}                { printf("ID           %s\n", yytext); }

{WS}                { /* ignora espacos */ }
{COMMENT}           { /* ignora comentario */ }
\n                  { line_no++; }

.                   {
                      fprintf(stderr, "Erro lexico na linha %d: caractere inesperado '%s'\n", line_no, yytext);
                      exit(1);
                    }

%%

int main(void) {
    printf("%-12s %s\n", "TOKEN", "LEXEMA");
    printf("%-12s %s\n", "------------", "------");
    yylex();
    return 0;
}
