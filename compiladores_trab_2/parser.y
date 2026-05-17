%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "semantic.h"
#include "codegen.h"

extern int yylex(void);
extern int line_no;
void yyerror(const char *s);

Node *parse_result = NULL;
%}

%define parse.error verbose

%union {
    int   ival;
    char *sval;
    Node *node;
}

%token <ival> INT BOOL
%token <sval> ID
%token LPAREN RPAREN
%token DEFINE IF LET SET
%token PLUS MINUS MUL DIV
%token LT GT EQ
%token AND OR NOT

%type <node> program forms form expr
%type <node> if_expr let_expr set_expr call_expr
%type <node> params args bindings binding

%%

program
    : forms
        { parse_result = make_program($1); }
    ;

/*
 * forms -> form forms | empty
 * Builds a linked list via node->next (right-recursive, preserves order).
 */
forms
    : /* empty */
        { $$ = NULL; }
    | form forms
        { $1->next = $2; $$ = $1; }
    ;

form
    : LPAREN DEFINE ID expr RPAREN
        { $$ = make_define_var($3, $4); }
    | LPAREN DEFINE LPAREN ID params RPAREN expr RPAREN
        { $$ = make_define_fun($4, $5, $7); }
    | expr
        { $$ = $1; }
    ;

params
    : /* empty */
        { $$ = NULL; }
    | ID params
        { $$ = make_param($1, $2); }
    ;

expr
    : INT               { $$ = make_int($1); }
    | BOOL              { $$ = make_bool($1); }
    | ID                { $$ = make_id($1); }
    | if_expr           { $$ = $1; }
    | let_expr          { $$ = $1; }
    | set_expr          { $$ = $1; }
    | call_expr         { $$ = $1; }
    ;

if_expr
    : LPAREN IF expr expr expr RPAREN
        { $$ = make_if($3, $4, $5); }
    ;

let_expr
    : LPAREN LET LPAREN bindings RPAREN expr RPAREN
        { $$ = make_let($4, $6); }
    ;

bindings
    : /* empty */
        { $$ = NULL; }
    | binding bindings
        { $1->next = $2; $$ = $1; }
    ;

binding
    : LPAREN ID expr RPAREN
        { $$ = make_binding($2, $3); }
    ;

set_expr
    : LPAREN SET ID expr RPAREN
        { $$ = make_set($3, $4); }
    ;

/*
 * Operators are explicitly enumerated with fixed arity.
 * Binary: +  -  *  /  <  >  =  and  or
 * Unary:  not
 * Function calls: (id args...)
 */
call_expr
    : LPAREN PLUS  expr expr RPAREN   { $$ = make_binop("+",   $3, $4); }
    | LPAREN MINUS expr expr RPAREN   { $$ = make_binop("-",   $3, $4); }
    | LPAREN MUL   expr expr RPAREN   { $$ = make_binop("*",   $3, $4); }
    | LPAREN DIV   expr expr RPAREN   { $$ = make_binop("/",   $3, $4); }
    | LPAREN LT    expr expr RPAREN   { $$ = make_binop("<",   $3, $4); }
    | LPAREN GT    expr expr RPAREN   { $$ = make_binop(">",   $3, $4); }
    | LPAREN EQ    expr expr RPAREN   { $$ = make_binop("=",   $3, $4); }
    | LPAREN AND   expr expr RPAREN   { $$ = make_binop("and", $3, $4); }
    | LPAREN OR    expr expr RPAREN   { $$ = make_binop("or",  $3, $4); }
    | LPAREN NOT   expr RPAREN        { $$ = make_unop("not",  $3); }
    | LPAREN ID    args RPAREN        { $$ = make_call($2, $3); }
    ;

args
    : /* empty */
        { $$ = NULL; }
    | expr args
        { $1->next = $2; $$ = $1; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse error at line %d: %s\n", line_no, s);
}

int main(int argc, char *argv[]) {
    int show_ast = (argc > 1 && strcmp(argv[1], "--ast") == 0);

    if (yyparse() != 0)
        return 1;
    if (!parse_result)
        return 0;

    if (show_ast) {
        printf("=== AST ===\n");
        print_ast(parse_result, 0);
        printf("\n=== PYTHON ===\n");
    }

    int errors = check_program(parse_result);
    if (errors > 0) {
        fprintf(stderr, "%d semantic error(s) found.\n", errors);
        return 1;
    }

    gen_program(parse_result, stdout);
    return 0;
}
