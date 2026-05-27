%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "parser.tab.h"

int line_no = 1;
%}

%option noyywrap

INT        -?[0-9]+
ID         [a-zA-Z_][a-zA-Z0-9_?!-]*
WS         [ \t\r]+
COMMENT    ;[^\n]*

%%

"("                 { return LPAREN; }
")"                 { return RPAREN; }

"define"            { return DEFINE; }
"if"                { return IF; }
"let"               { return LET; }
"set!"              { return SET; }
"list"              { return LIST_KW; }
"car"               { return CAR; }
"cdr"               { return CDR; }
"cons"              { return CONS; }
"null?"             { return NULLQ; }

"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return MUL; }
"/"                 { return DIV; }

"<"                 { return LT; }
">"                 { return GT; }
"="                 { return EQ; }

"and"               { return AND; }
"or"                { return OR; }
"not"               { return NOT; }

"#t"                { yylval.ival = 1; return BOOL; }
"#f"                { yylval.ival = 0; return BOOL; }
{INT}               { yylval.ival = atoi(yytext); return INT; }
{ID}                { yylval.sval = strdup(yytext); return ID; }

{WS}                { /* ignore whitespace */ }
{COMMENT}           { /* ignore comment */ }
\n                  { line_no++; }

.                   {
                      fprintf(stderr, "Lexical error at line %d: unexpected character '%s'\n", line_no, yytext);
                      exit(1);
                    }

%%
