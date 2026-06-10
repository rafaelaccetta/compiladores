#ifndef CODEGEN_H
#define CODEGEN_H

#include <stdio.h>
#include "ast.h"

void gen_program(Node *program, FILE *out);

#endif
