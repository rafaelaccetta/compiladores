#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "semantic.h"

/* ------------------------------------------------------------------ */
/* Symbol table                                                        */
/* ------------------------------------------------------------------ */

typedef struct FunInfo {
    int    arity;
    char **param_names;
    Type  *param_types;  /* TYPE_UNKNOWN until body is analysed */
    Type   ret_type;
} FunInfo;

typedef struct Entry {
    char        *name;
    Type         type;   /* TYPE_FUN if function */
    FunInfo     *fun;    /* non-NULL iff type == TYPE_FUN */
    struct Entry *next;
} Entry;

typedef struct Scope {
    Entry        *entries;
    struct Scope *parent;
} Scope;

static Scope *scope_new(Scope *parent) {
    Scope *s = calloc(1, sizeof(Scope));
    s->parent = parent;
    return s;
}

static void scope_define(Scope *s, const char *name, Type type, FunInfo *fun) {
    Entry *e = calloc(1, sizeof(Entry));
    e->name = strdup(name);
    e->type = type;
    e->fun  = fun;
    e->next = s->entries;
    s->entries = e;
}

/* Search current scope and all parents */
static Entry *scope_lookup(Scope *s, const char *name) {
    for (Scope *sc = s; sc; sc = sc->parent)
        for (Entry *e = sc->entries; e; e = e->next)
            if (strcmp(e->name, name) == 0)
                return e;
    return NULL;
}

/* Search only the innermost scope (for redeclaration detection) */
static Entry *scope_lookup_local(Scope *s, const char *name) {
    for (Entry *e = s->entries; e; e = e->next)
        if (strcmp(e->name, name) == 0)
            return e;
    return NULL;
}

/* ------------------------------------------------------------------ */
/* Error reporting                                                     */
/* ------------------------------------------------------------------ */

static int error_count = 0;

static void sem_error(const char *msg) {
    fprintf(stderr, "Semantic error: %s\n", msg);
    error_count++;
}

static const char *type_name(Type t) {
    switch (t) {
        case TYPE_INT:     return "int";
        case TYPE_BOOL:    return "bool";
        case TYPE_FUN:     return "fun";
        case TYPE_UNKNOWN: return "unknown";
        case TYPE_ERROR:   return "error";
        default:           return "?";
    }
}

/* ------------------------------------------------------------------ */
/* Type checking                                                       */
/* ------------------------------------------------------------------ */

static Type check_expr(Node *node, Scope *scope);

static Type check_binop(Node *node, Scope *scope) {
    const char *op = node->sval;
    Type lt = check_expr(node->child1, scope);
    Type rt = check_expr(node->child2, scope);
    char msg[200];

    if (lt == TYPE_ERROR || rt == TYPE_ERROR) return TYPE_ERROR;

    /* arithmetic: int x int -> int */
    if (strcmp(op, "+") == 0 || strcmp(op, "-") == 0 ||
        strcmp(op, "*") == 0 || strcmp(op, "/") == 0) {
        if (lt != TYPE_INT && lt != TYPE_UNKNOWN) {
            snprintf(msg, sizeof(msg),
                     "operator '%s' requires int, left operand is %s", op, type_name(lt));
            sem_error(msg);
            return TYPE_ERROR;
        }
        if (rt != TYPE_INT && rt != TYPE_UNKNOWN) {
            snprintf(msg, sizeof(msg),
                     "operator '%s' requires int, right operand is %s", op, type_name(rt));
            sem_error(msg);
            return TYPE_ERROR;
        }
        return TYPE_INT;
    }

    /* comparison: int x int -> bool */
    if (strcmp(op, "<") == 0 || strcmp(op, ">") == 0 || strcmp(op, "=") == 0) {
        if (lt != TYPE_INT && lt != TYPE_UNKNOWN) {
            snprintf(msg, sizeof(msg),
                     "operator '%s' requires int, left operand is %s", op, type_name(lt));
            sem_error(msg);
            return TYPE_ERROR;
        }
        if (rt != TYPE_INT && rt != TYPE_UNKNOWN) {
            snprintf(msg, sizeof(msg),
                     "operator '%s' requires int, right operand is %s", op, type_name(rt));
            sem_error(msg);
            return TYPE_ERROR;
        }
        return TYPE_BOOL;
    }

    /* boolean: bool x bool -> bool */
    if (strcmp(op, "and") == 0 || strcmp(op, "or") == 0) {
        if (lt != TYPE_BOOL && lt != TYPE_UNKNOWN) {
            snprintf(msg, sizeof(msg),
                     "operator '%s' requires bool, left operand is %s", op, type_name(lt));
            sem_error(msg);
            return TYPE_ERROR;
        }
        if (rt != TYPE_BOOL && rt != TYPE_UNKNOWN) {
            snprintf(msg, sizeof(msg),
                     "operator '%s' requires bool, right operand is %s", op, type_name(rt));
            sem_error(msg);
            return TYPE_ERROR;
        }
        return TYPE_BOOL;
    }

    return TYPE_UNKNOWN;
}

static Type check_expr(Node *node, Scope *scope) {
    if (!node) return TYPE_ERROR;
    char msg[300];

    switch (node->type) {

        case NODE_INT:  return TYPE_INT;
        case NODE_BOOL: return TYPE_BOOL;

        case NODE_ID: {
            Entry *e = scope_lookup(scope, node->sval);
            if (!e) {
                snprintf(msg, sizeof(msg), "undeclared identifier '%s'", node->sval);
                sem_error(msg);
                return TYPE_ERROR;
            }
            return e->type;
        }

        case NODE_BINOP:
            return check_binop(node, scope);

        case NODE_UNOP: {
            /* only 'not' */
            Type t = check_expr(node->child1, scope);
            if (t == TYPE_ERROR) return TYPE_ERROR;
            if (t != TYPE_BOOL && t != TYPE_UNKNOWN) {
                snprintf(msg, sizeof(msg),
                         "operator 'not' requires bool, got %s", type_name(t));
                sem_error(msg);
                return TYPE_ERROR;
            }
            return TYPE_BOOL;
        }

        case NODE_IF: {
            Type ct = check_expr(node->child1, scope);
            Type tt = check_expr(node->child2, scope);
            Type et = check_expr(node->child3, scope);

            if (ct == TYPE_ERROR || tt == TYPE_ERROR || et == TYPE_ERROR)
                return TYPE_ERROR;

            if (ct != TYPE_BOOL && ct != TYPE_UNKNOWN) {
                snprintf(msg, sizeof(msg),
                         "if condition must be bool, got %s", type_name(ct));
                sem_error(msg);
                return TYPE_ERROR;
            }

            /* both branches must have the same type when known */
            if (tt != TYPE_UNKNOWN && et != TYPE_UNKNOWN && tt != et) {
                snprintf(msg, sizeof(msg),
                         "if branches have incompatible types: %s vs %s",
                         type_name(tt), type_name(et));
                sem_error(msg);
                return TYPE_ERROR;
            }

            return (tt != TYPE_UNKNOWN) ? tt : et;
        }

        case NODE_LET: {
            /* Evaluate all binding expressions in the OUTER scope (standard let) */
            int count = 0;
            for (Node *b = node->child1; b; b = b->next) count++;

            char **names = calloc(count, sizeof(char *));
            Type  *types = calloc(count, sizeof(Type));
            int i = 0;
            for (Node *b = node->child1; b; b = b->next, i++) {
                names[i] = b->sval;
                types[i] = check_expr(b->child1, scope);
            }

            /* New scope with bound names */
            Scope *ls = scope_new(scope);
            for (int j = 0; j < count; j++) {
                if (scope_lookup_local(ls, names[j])) {
                    snprintf(msg, sizeof(msg),
                             "duplicate binding '%s' in let", names[j]);
                    sem_error(msg);
                } else {
                    scope_define(ls, names[j], types[j], NULL);
                }
            }

            Type bt = check_expr(node->child2, ls);
            free(names);
            free(types);
            return bt;
        }

        case NODE_SET: {
            Entry *e = scope_lookup(scope, node->sval);
            if (!e) {
                snprintf(msg, sizeof(msg),
                         "set! on undeclared identifier '%s'", node->sval);
                sem_error(msg);
                return TYPE_ERROR;
            }
            Type t = check_expr(node->child1, scope);
            if (t != TYPE_ERROR &&
                e->type != TYPE_UNKNOWN && t != TYPE_UNKNOWN &&
                t != e->type) {
                snprintf(msg, sizeof(msg),
                         "set! type mismatch: '%s' is %s, assigned %s",
                         node->sval, type_name(e->type), type_name(t));
                sem_error(msg);
                return TYPE_ERROR;
            }
            return (t != TYPE_UNKNOWN) ? t : e->type;
        }

        case NODE_CALL: {
            Entry *e = scope_lookup(scope, node->sval);
            if (!e) {
                snprintf(msg, sizeof(msg),
                         "call to undeclared function '%s'", node->sval);
                sem_error(msg);
                return TYPE_ERROR;
            }
            if (e->type != TYPE_FUN) {
                snprintf(msg, sizeof(msg),
                         "'%s' is not a function", node->sval);
                sem_error(msg);
                return TYPE_ERROR;
            }

            /* Check arity */
            int argc = 0;
            for (Node *a = node->child1; a; a = a->next) argc++;
            if (argc != e->fun->arity) {
                snprintf(msg, sizeof(msg),
                         "function '%s' expects %d arg(s), got %d",
                         node->sval, e->fun->arity, argc);
                sem_error(msg);
                return TYPE_ERROR;
            }

            /* Check argument types */
            int j = 0;
            for (Node *a = node->child1; a; a = a->next, j++) {
                Type at = check_expr(a, scope);
                Type pt = e->fun->param_types[j];
                if (at != TYPE_ERROR && pt != TYPE_UNKNOWN &&
                    at != TYPE_UNKNOWN && at != pt) {
                    snprintf(msg, sizeof(msg),
                             "argument %d of '%s': expected %s, got %s",
                             j + 1, node->sval, type_name(pt), type_name(at));
                    sem_error(msg);
                }
            }

            return e->fun->ret_type;
        }

        default:
            return TYPE_ERROR;
    }
}

/* ------------------------------------------------------------------ */
/* Form checking (top-level)                                           */
/* ------------------------------------------------------------------ */

static void check_form(Node *node, Scope *scope) {
    char msg[300];

    switch (node->type) {

        case NODE_DEFINE_VAR: {
            if (scope_lookup_local(scope, node->sval)) {
                snprintf(msg, sizeof(msg),
                         "redeclaration of '%s' in same scope", node->sval);
                sem_error(msg);
                return;
            }
            Type t = check_expr(node->child1, scope);
            scope_define(scope, node->sval, t, NULL);
            break;
        }

        case NODE_DEFINE_FUN: {
            if (scope_lookup_local(scope, node->sval)) {
                snprintf(msg, sizeof(msg),
                         "redeclaration of '%s' in same scope", node->sval);
                sem_error(msg);
                return;
            }

            /* Count and collect params */
            int arity = 0;
            for (Node *p = node->child1; p; p = p->next) arity++;

            FunInfo *fun      = calloc(1, sizeof(FunInfo));
            fun->arity        = arity;
            fun->param_names  = calloc(arity, sizeof(char *));
            fun->param_types  = calloc(arity, sizeof(Type));
            fun->ret_type     = TYPE_UNKNOWN;

            int i = 0;
            for (Node *p = node->child1; p; p = p->next, i++) {
                fun->param_names[i] = p->sval;
                fun->param_types[i] = TYPE_UNKNOWN;
            }

            /* Register BEFORE checking body to support self-recursion */
            scope_define(scope, node->sval, TYPE_FUN, fun);

            /* Build function scope with params */
            Scope *fs = scope_new(scope);
            for (int j = 0; j < arity; j++) {
                if (scope_lookup_local(fs, fun->param_names[j])) {
                    snprintf(msg, sizeof(msg),
                             "duplicate parameter '%s' in function '%s'",
                             fun->param_names[j], node->sval);
                    sem_error(msg);
                } else {
                    scope_define(fs, fun->param_names[j], TYPE_UNKNOWN, NULL);
                }
            }

            /* Check body; update return type */
            fun->ret_type = check_expr(node->child2, fs);
            break;
        }

        default:
            /* Standalone expression (including set!) */
            check_expr(node, scope);
            break;
    }
}

/* ------------------------------------------------------------------ */
/* Entry point                                                         */
/* ------------------------------------------------------------------ */

int check_program(Node *program) {
    error_count = 0;
    Scope *global = scope_new(NULL);
    for (Node *f = program->child1; f; f = f->next)
        check_form(f, global);
    return error_count;
}
