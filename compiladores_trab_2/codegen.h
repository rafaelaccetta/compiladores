#ifndef CODEGEN_H
#define CODEGEN_H

#include <stdio.h>
#include "ast.h"

/* Translate the whole program AST to Python, writing to `out`. */
void gen_program(Node *program, FILE *out);

#endif
