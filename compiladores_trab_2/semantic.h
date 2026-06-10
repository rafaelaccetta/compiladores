#ifndef SEMANTIC_H
#define SEMANTIC_H

#include "ast.h"

typedef enum {
    TYPE_INT,
    TYPE_BOOL,
    TYPE_LIST,
    TYPE_FUN,
    TYPE_UNKNOWN,
    TYPE_ERROR
} Type;

int check_program(Node *program);

#endif
