#ifndef AST_H
#define AST_H

typedef enum {
    NODE_PROGRAM,
    NODE_DEFINE_VAR,
    NODE_DEFINE_FUN,
    NODE_INT,
    NODE_BOOL,
    NODE_ID,
    NODE_IF,
    NODE_LET,
    NODE_SET,
    NODE_BINOP,
    NODE_UNOP,
    NODE_CALL,
    NODE_PARAM,
    NODE_BINDING
} NodeType;

typedef struct Node {
    NodeType     type;
    int          ival;   /* INT value or BOOL (1/#t, 0/#f) */
    char        *sval;   /* ID name, op string, or function name */
    struct Node *child1;
    struct Node *child2;
    struct Node *child3; /* used by NODE_IF for else branch */
    struct Node *next;   /* links siblings in lists (forms, args, params, bindings) */
} Node;

/* constructors */
Node *make_program(Node *forms);
Node *make_define_var(char *name, Node *expr);
Node *make_define_fun(char *name, Node *params, Node *body);
Node *make_int(int val);
Node *make_bool(int val);
Node *make_id(char *name);
Node *make_if(Node *cond, Node *then_br, Node *else_br);
Node *make_let(Node *bindings, Node *body);
Node *make_set(char *name, Node *expr);
Node *make_binop(const char *op, Node *left, Node *right);
Node *make_unop(const char *op, Node *operand);
Node *make_call(char *name, Node *args);
Node *make_param(char *name, Node *next_param);
Node *make_binding(char *name, Node *expr);

/* pretty-print the AST to stdout */
void print_ast(Node *node, int indent);

#endif
