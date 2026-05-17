#ifndef SEMANTIC_H
#define SEMANTIC_H

#include "ast.h"

typedef enum {
    TYPE_INT,
    TYPE_BOOL,
    TYPE_FUN,
    TYPE_UNKNOWN,  /* parameter or unresolved */
    TYPE_ERROR     /* sentinel: propagate silently */
} Type;

/* Run type + context checks. Returns number of errors found. */
int check_program(Node *program);

#endif
