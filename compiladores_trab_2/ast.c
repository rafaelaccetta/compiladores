#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

static Node *new_node(NodeType type) {
    Node *n = calloc(1, sizeof(Node));
    if (!n) { fprintf(stderr, "Out of memory\n"); exit(1); }
    n->type = type;
    return n;
}

Node *make_program(Node *forms) {
    Node *n = new_node(NODE_PROGRAM);
    n->child1 = forms;
    return n;
}

Node *make_define_var(char *name, Node *expr) {
    Node *n = new_node(NODE_DEFINE_VAR);
    n->sval   = name;
    n->child1 = expr;
    return n;
}

Node *make_define_fun(char *name, Node *params, Node *body) {
    Node *n = new_node(NODE_DEFINE_FUN);
    n->sval   = name;
    n->child1 = params;
    n->child2 = body;
    return n;
}

Node *make_int(int val) {
    Node *n = new_node(NODE_INT);
    n->ival = val;
    return n;
}

Node *make_bool(int val) {
    Node *n = new_node(NODE_BOOL);
    n->ival = val;
    return n;
}

Node *make_id(char *name) {
    Node *n = new_node(NODE_ID);
    n->sval = name;
    return n;
}

Node *make_if(Node *cond, Node *then_br, Node *else_br) {
    Node *n = new_node(NODE_IF);
    n->child1 = cond;
    n->child2 = then_br;
    n->child3 = else_br;
    return n;
}

Node *make_let(Node *bindings, Node *body) {
    Node *n = new_node(NODE_LET);
    n->child1 = bindings;
    n->child2 = body;
    return n;
}

Node *make_set(char *name, Node *expr) {
    Node *n = new_node(NODE_SET);
    n->sval   = name;
    n->child1 = expr;
    return n;
}

Node *make_binop(const char *op, Node *left, Node *right) {
    Node *n = new_node(NODE_BINOP);
    n->sval   = strdup(op);
    n->child1 = left;
    n->child2 = right;
    return n;
}

Node *make_unop(const char *op, Node *operand) {
    Node *n = new_node(NODE_UNOP);
    n->sval   = strdup(op);
    n->child1 = operand;
    return n;
}

Node *make_call(char *name, Node *args) {
    Node *n = new_node(NODE_CALL);
    n->sval   = name;
    n->child1 = args;
    return n;
}

Node *make_param(char *name, Node *next_param) {
    Node *n = new_node(NODE_PARAM);
    n->sval = name;
    n->next = next_param;
    return n;
}

Node *make_binding(char *name, Node *expr) {
    Node *n = new_node(NODE_BINDING);
    n->sval   = name;
    n->child1 = expr;
    return n;
}

/* ------------------------------------------------------------------ */

static void do_indent(int indent) {
    for (int i = 0; i < indent; i++) printf("  ");
}

/*
 * print_ast prints the single node `node` and its children.
 * It does NOT follow node->next; callers iterate lists explicitly.
 */
void print_ast(Node *node, int indent) {
    if (!node) return;
    do_indent(indent);

    switch (node->type) {
        case NODE_PROGRAM:
            printf("Program\n");
            for (Node *f = node->child1; f; f = f->next)
                print_ast(f, indent + 1);
            break;

        case NODE_DEFINE_VAR:
            printf("DefineVar(%s)\n", node->sval);
            print_ast(node->child1, indent + 1);
            break;

        case NODE_DEFINE_FUN:
            printf("DefineFun(%s) params:", node->sval);
            for (Node *p = node->child1; p; p = p->next)
                printf(" %s", p->sval);
            printf("\n");
            print_ast(node->child2, indent + 1);
            break;

        case NODE_INT:
            printf("Int(%d)\n", node->ival);
            break;

        case NODE_BOOL:
            printf("Bool(%s)\n", node->ival ? "#t" : "#f");
            break;

        case NODE_ID:
            printf("Id(%s)\n", node->sval);
            break;

        case NODE_IF:
            printf("If\n");
            print_ast(node->child1, indent + 1);
            print_ast(node->child2, indent + 1);
            print_ast(node->child3, indent + 1);
            break;

        case NODE_LET:
            printf("Let\n");
            for (Node *b = node->child1; b; b = b->next) {
                do_indent(indent + 1);
                printf("Binding(%s)\n", b->sval);
                print_ast(b->child1, indent + 2);
            }
            do_indent(indent + 1);
            printf("Body\n");
            print_ast(node->child2, indent + 2);
            break;

        case NODE_SET:
            printf("Set!(%s)\n", node->sval);
            print_ast(node->child1, indent + 1);
            break;

        case NODE_BINOP:
            printf("BinOp(%s)\n", node->sval);
            print_ast(node->child1, indent + 1);
            print_ast(node->child2, indent + 1);
            break;

        case NODE_UNOP:
            printf("UnOp(%s)\n", node->sval);
            print_ast(node->child1, indent + 1);
            break;

        case NODE_CALL:
            printf("Call(%s)\n", node->sval);
            for (Node *a = node->child1; a; a = a->next)
                print_ast(a, indent + 1);
            break;

        default:
            printf("Unknown(%d)\n", node->type);
            break;
    }
}
