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
/* Tree-drawing printer                                                 */

static void build_label(Node *node, char *buf, size_t size) {
    switch (node->type) {
        case NODE_PROGRAM:    snprintf(buf, size, "Program"); break;
        case NODE_DEFINE_VAR: snprintf(buf, size, "define %s", node->sval); break;
        case NODE_DEFINE_FUN: {
            char params[256] = "";
            for (Node *p = node->child1; p; p = p->next) {
                if (params[0]) strncat(params, " ", sizeof(params)-strlen(params)-1);
                strncat(params, p->sval, sizeof(params)-strlen(params)-1);
            }
            snprintf(buf, size, "define (%s %s)", node->sval, params);
            break;
        }
        case NODE_INT:        snprintf(buf, size, "%d", node->ival); break;
        case NODE_BOOL:       snprintf(buf, size, "%s", node->ival ? "#t" : "#f"); break;
        case NODE_ID:         snprintf(buf, size, "%s", node->sval); break;
        case NODE_IF:         snprintf(buf, size, "if"); break;
        case NODE_LET:        snprintf(buf, size, "let"); break;
        case NODE_SET:        snprintf(buf, size, "set! %s", node->sval); break;
        case NODE_BINOP:      snprintf(buf, size, "%s", node->sval); break;
        case NODE_UNOP:       snprintf(buf, size, "%s", node->sval); break;
        case NODE_CALL:       snprintf(buf, size, "(%s ...)", node->sval); break;
        case NODE_BINDING:    snprintf(buf, size, "bind %s", node->sval); break;
        default:              snprintf(buf, size, "?(%d)", node->type); break;
    }
}

static int list_len(Node *n) {
    int c = 0; for (; n; n = n->next) c++; return c;
}

static void print_child(Node *node, const char *prefix, int is_last);

static void print_children_of(Node *node, const char *prefix) {
    switch (node->type) {
        case NODE_PROGRAM: {
            int n = list_len(node->child1), i = 0;
            for (Node *f = node->child1; f; f = f->next, i++)
                print_child(f, prefix, i == n - 1);
            break;
        }
        case NODE_DEFINE_VAR:
            print_child(node->child1, prefix, 1);
            break;
        case NODE_DEFINE_FUN:
            print_child(node->child2, prefix, 1);
            break;
        case NODE_IF:
            print_child(node->child1, prefix, 0);
            print_child(node->child2, prefix, 0);
            print_child(node->child3, prefix, 1);
            break;
        case NODE_LET: {
            int nb = list_len(node->child1), i = 0;
            for (Node *b = node->child1; b; b = b->next, i++)
                print_child(b, prefix, (i == nb - 1) && !node->child2);
            if (node->child2)
                print_child(node->child2, prefix, 1);
            break;
        }
        case NODE_BINDING:
            print_child(node->child1, prefix, 1);
            break;
        case NODE_SET:
            print_child(node->child1, prefix, 1);
            break;
        case NODE_BINOP:
            print_child(node->child1, prefix, 0);
            print_child(node->child2, prefix, 1);
            break;
        case NODE_UNOP:
            print_child(node->child1, prefix, 1);
            break;
        case NODE_CALL: {
            int n = list_len(node->child1), i = 0;
            for (Node *a = node->child1; a; a = a->next, i++)
                print_child(a, prefix, i == n - 1);
            break;
        }
        default: break;
    }
}

static void print_child(Node *node, const char *prefix, int is_last) {
    if (!node) return;
    char label[256];
    build_label(node, label, sizeof(label));
    printf("%s%s %s\n", prefix, is_last ? "\xe2\x94\x94\xe2\x94\x80\xe2\x94\x80" : "\xe2\x94\x9c\xe2\x94\x80\xe2\x94\x80", label);
    char new_prefix[512];
    snprintf(new_prefix, sizeof(new_prefix), "%s%s", prefix, is_last ? "    " : "\xe2\x94\x82   ");
    print_children_of(node, new_prefix);
}

void print_ast(Node *node, int indent) {
    (void)indent;
    if (!node) return;
    char label[256];
    build_label(node, label, sizeof(label));
    printf("%s\n", label);
    print_children_of(node, "");
}
