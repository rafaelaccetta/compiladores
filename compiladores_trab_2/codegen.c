#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "codegen.h"

/*
 * Mapping (from DEFINICAO_LINGUAGEM.md):
 *   (define x e)         ->  x = <e>
 *   (define (f a b) e)   ->  def f(a, b):\n    return <e>
 *   (if c t e)           ->  (<t> if <c> else <e>)
 *   (let ((x a)(y b)) e) ->  (lambda x, y: <e>)(<a>, <b>)
 *   (set! x e)           ->  x = <e>
 *   (+ a b)              ->  (a + b)   [analogous for - * //]
 *   (< a b)              ->  (a < b)   [analogous for > ==>]
 *   (= a b)              ->  (a == b)
 *   (and a b)            ->  (a and b)
 *   (or a b)             ->  (a or b)
 *   (not a)              ->  (not a)
 *   (f a b)              ->  f(a, b)
 *   #t / #f              ->  True / False
 */

static void gen_expr(Node *node, FILE *out);

static void gen_expr(Node *node, FILE *out) {
    if (!node) return;

    switch (node->type) {

        case NODE_INT:
            fprintf(out, "%d", node->ival);
            break;

        case NODE_BOOL:
            fprintf(out, "%s", node->ival ? "True" : "False");
            break;

        case NODE_ID:
            fprintf(out, "%s", node->sval);
            break;

        case NODE_BINOP: {
            const char *op = node->sval;
            const char *py;
            if      (strcmp(op, "+")   == 0) py = "+";
            else if (strcmp(op, "-")   == 0) py = "-";
            else if (strcmp(op, "*")   == 0) py = "*";
            else if (strcmp(op, "/")   == 0) py = "//";   /* integer division */
            else if (strcmp(op, "<")   == 0) py = "<";
            else if (strcmp(op, ">")   == 0) py = ">";
            else if (strcmp(op, "=")   == 0) py = "==";
            else if (strcmp(op, "and") == 0) py = "and";
            else if (strcmp(op, "or")  == 0) py = "or";
            else py = op;
            fprintf(out, "(");
            gen_expr(node->child1, out);
            fprintf(out, " %s ", py);
            gen_expr(node->child2, out);
            fprintf(out, ")");
            break;
        }

        case NODE_UNOP:
            fprintf(out, "(not ");
            gen_expr(node->child1, out);
            fprintf(out, ")");
            break;

        case NODE_IF:
            /* Python ternary: (then if cond else else) */
            fprintf(out, "(");
            gen_expr(node->child2, out);   /* then */
            fprintf(out, " if ");
            gen_expr(node->child1, out);   /* cond */
            fprintf(out, " else ");
            gen_expr(node->child3, out);   /* else */
            fprintf(out, ")");
            break;

        case NODE_LET: {
            /* (lambda params: body)(args) */
            fprintf(out, "(lambda");
            int first = 1;
            for (Node *b = node->child1; b; b = b->next) {
                fprintf(out, "%s%s", first ? " " : ", ", b->sval);
                first = 0;
            }
            fprintf(out, ": ");
            gen_expr(node->child2, out);
            fprintf(out, ")(");
            first = 1;
            for (Node *b = node->child1; b; b = b->next) {
                if (!first) fprintf(out, ", ");
                gen_expr(b->child1, out);
                first = 0;
            }
            fprintf(out, ")");
            break;
        }

        case NODE_CALL: {
            fprintf(out, "%s(", node->sval);
            int first = 1;
            for (Node *a = node->child1; a; a = a->next) {
                if (!first) fprintf(out, ", ");
                gen_expr(a, out);
                first = 0;
            }
            fprintf(out, ")");
            break;
        }

        default:
            break;
    }
}

static void gen_form(Node *node, FILE *out) {
    switch (node->type) {

        case NODE_DEFINE_VAR:
            fprintf(out, "%s = ", node->sval);
            gen_expr(node->child1, out);
            fprintf(out, "\n");
            break;

        case NODE_DEFINE_FUN: {
            fprintf(out, "def %s(", node->sval);
            int first = 1;
            for (Node *p = node->child1; p; p = p->next) {
                if (!first) fprintf(out, ", ");
                fprintf(out, "%s", p->sval);
                first = 0;
            }
            fprintf(out, "):\n    return ");
            gen_expr(node->child2, out);
            fprintf(out, "\n");
            break;
        }

        case NODE_SET:
            fprintf(out, "%s = ", node->sval);
            gen_expr(node->child1, out);
            fprintf(out, "\n");
            break;

        default:
            /* Standalone expression: emit as a statement */
            gen_expr(node, out);
            fprintf(out, "\n");
            break;
    }
}

void gen_program(Node *program, FILE *out) {
    for (Node *f = program->child1; f; f = f->next)
        gen_form(f, out);
}
