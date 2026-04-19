#!/usr/bin/env python3
"""
Testes unitários para compute_first, compute_follow e build_ll1_table.

Usamos três gramáticas clássicas com resultados conhecidos da literatura,
mais um teste direto sobre a gramática Racket.

Gramáticas de referência:
  G1 — gramática linear simples (sem ε)
  G2 — gramática com produções ε e propagação de FOLLOW
  G3 — gramática de expressões aritméticas LL(1) clássica
  G4 — gramática com conflito LL(1) (não-LL(1))
  G5 — gramática Racket (subset) — testa propriedades estruturais
"""

import unittest
from first_follow import (
    compute_first,
    compute_follow,
    build_ll1_table,
    first_of_sequence,
    EPSILON,
    EOF,
)


# =============================================================================
# G1 — Gramática linear, sem ε, sem recursão
#
#   S → a B
#   B → b C
#   C → c
#
# FIRST(S) = {a}     FOLLOW(S) = {$}
# FIRST(B) = {b}     FOLLOW(B) = {$}   (S → a B, nada após B)
# FIRST(C) = {c}     FOLLOW(C) = {$}   (B → b C, nada após C)
# =============================================================================
G1 = {
    'S': [['a', 'B']],
    'B': [['b', 'C']],
    'C': [['c']],
}

# =============================================================================
# G2 — Gramática com ε e propagação de FOLLOW
#
#   S → A B C
#   A → a | ε
#   B → b | ε
#   C → c
#
# FIRST(A) = {a, ε}
# FIRST(B) = {b, ε}
# FIRST(C) = {c}
# FIRST(S) = {a, b, c}      (A pode ser ε, B pode ser ε, chega em C)
#
# FOLLOW(S) = {$}
# FOLLOW(A) = {b, c}        (após A vem B; B pode ser ε, então c ∈ FOLLOW(A))
# FOLLOW(B) = {c}            (após B vem C, FIRST(C)={c})
# FOLLOW(C) = {$}            (fim de S)
# =============================================================================
G2 = {
    'S': [['A', 'B', 'C']],
    'A': [['a'], [EPSILON]],
    'B': [['b'], [EPSILON]],
    'C': [['c']],
}

# =============================================================================
# G3 — Gramática clássica de expressões aritméticas (LL(1))
#   Retirada de: Aho, Lam, Sethi, Ullman — "Compilers" (Dragon Book) 4.4
#
#   E  → T  E'
#   E' → '+' T E' | ε
#   T  → F  T'
#   T' → '*' F T' | ε
#   F  → '(' E ')' | id
#
# FIRST(E)  = FIRST(T)  = FIRST(F)  = {'(', id}
# FIRST(E') = {'+', ε}
# FIRST(T') = {'*', ε}
#
# FOLLOW(E)  = {')', $}
# FOLLOW(E') = {')', $}         (mesmos de E)
# FOLLOW(T)  = {'+', ')', $}
# FOLLOW(T') = {'+', ')', $}   (mesmos de T)
# FOLLOW(F)  = {'*', '+', ')', $}
# =============================================================================
G3 = {
    'E':  [['T', "E'"]],
    "E'": [['+', 'T', "E'"], [EPSILON]],
    'T':  [['F', "T'"]],
    "T'": [['*', 'F', "T'"], [EPSILON]],
    'F':  [['(', 'E', ')'], ['id']],
}

# =============================================================================
# G4 — Gramática com conflito LL(1)
#
#   S → a A | a B
#   A → b
#   B → c
#
# FIRST(a A) = {a}  e  FIRST(a B) = {a}  → conflito em S para terminal 'a'
# =============================================================================
G4 = {
    'S': [['a', 'A'], ['a', 'B']],
    'A': [['b']],
    'B': [['c']],
}

# =============================================================================
# G5 — Subset da gramática Racket (apenas Program / Expr / ExprList)
#   Para testar que ε propaga corretamente em gramáticas recursivas.
#
#   Program  → Expr Program | ε
#   Expr     → ATOM | LPAREN ExprList
#   ExprList → Expr ExprList | RPAREN
#
# FIRST(Program)  = {ATOM, LPAREN, ε}
# FIRST(Expr)     = {ATOM, LPAREN}
# FIRST(ExprList) = {ATOM, LPAREN, RPAREN}
#
# FOLLOW(Program)  = {$}
# FOLLOW(Expr)     = {ATOM, LPAREN, RPAREN, $}
# FOLLOW(ExprList) = {ATOM, LPAREN, RPAREN, $}
# =============================================================================
G5 = {
    'Program':  [['Expr', 'Program'], [EPSILON]],
    'Expr':     [['ATOM'], ['LPAREN', 'ExprList']],
    'ExprList': [['Expr', 'ExprList'], ['RPAREN']],
}


# =============================================================================
# Testes
# =============================================================================

class TestFirstG1(unittest.TestCase):
    def setUp(self):
        self.first = compute_first(G1)

    def test_first_S(self):
        self.assertEqual(self.first['S'], {'a'})

    def test_first_B(self):
        self.assertEqual(self.first['B'], {'b'})

    def test_first_C(self):
        self.assertEqual(self.first['C'], {'c'})

    def test_no_epsilon_anywhere(self):
        for nt in G1:
            self.assertNotIn(EPSILON, self.first[nt])


class TestFollowG1(unittest.TestCase):
    def setUp(self):
        self.first  = compute_first(G1)
        self.follow = compute_follow(G1, self.first, start='S')

    def test_follow_S(self):
        self.assertEqual(self.follow['S'], {EOF})

    def test_follow_B(self):
        self.assertEqual(self.follow['B'], {EOF})

    def test_follow_C(self):
        self.assertEqual(self.follow['C'], {EOF})


class TestFirstG2(unittest.TestCase):
    def setUp(self):
        self.first = compute_first(G2)

    def test_first_A_has_epsilon(self):
        self.assertIn(EPSILON, self.first['A'])

    def test_first_A_has_a(self):
        self.assertIn('a', self.first['A'])

    def test_first_B_has_epsilon(self):
        self.assertIn(EPSILON, self.first['B'])

    def test_first_S_has_a(self):
        self.assertIn('a', self.first['S'])

    def test_first_S_has_b(self):
        self.assertIn('b', self.first['S'])

    def test_first_S_has_c(self):
        self.assertIn('c', self.first['S'])

    def test_first_S_no_epsilon(self):
        # S → A B C; C não deriva ε, então S não deriva ε
        self.assertNotIn(EPSILON, self.first['S'])


class TestFollowG2(unittest.TestCase):
    def setUp(self):
        self.first  = compute_first(G2)
        self.follow = compute_follow(G2, self.first, start='S')

    def test_follow_A_has_b(self):
        self.assertIn('b', self.follow['A'])

    def test_follow_A_has_c(self):
        # B pode ser ε, então c (de C) entra no FOLLOW(A)
        self.assertIn('c', self.follow['A'])

    def test_follow_A_no_dollar(self):
        # C nunca é ε, então $ não entra em FOLLOW(A)
        self.assertNotIn(EOF, self.follow['A'])

    def test_follow_B_has_c(self):
        self.assertIn('c', self.follow['B'])

    def test_follow_B_no_dollar(self):
        self.assertNotIn(EOF, self.follow['B'])

    def test_follow_C_has_dollar(self):
        self.assertIn(EOF, self.follow['C'])


class TestFirstG3(unittest.TestCase):
    def setUp(self):
        self.first = compute_first(G3)

    def test_first_E(self):
        self.assertEqual(self.first['E'], {'(', 'id'})

    def test_first_Eprime_has_plus_and_epsilon(self):
        self.assertEqual(self.first["E'"], {'+', EPSILON})

    def test_first_T(self):
        self.assertEqual(self.first['T'], {'(', 'id'})

    def test_first_Tprime_has_star_and_epsilon(self):
        self.assertEqual(self.first["T'"], {'*', EPSILON})

    def test_first_F(self):
        self.assertEqual(self.first['F'], {'(', 'id'})


class TestFollowG3(unittest.TestCase):
    def setUp(self):
        self.first  = compute_first(G3)
        self.follow = compute_follow(G3, self.first, start='E')

    def test_follow_E(self):
        self.assertEqual(self.follow['E'], {')', EOF})

    def test_follow_Eprime(self):
        # E' sempre aparece no final de E, então FOLLOW(E') = FOLLOW(E)
        self.assertEqual(self.follow["E'"], {')', EOF})

    def test_follow_T(self):
        self.assertEqual(self.follow['T'], {'+', ')', EOF})

    def test_follow_Tprime(self):
        self.assertEqual(self.follow["T'"], {'+', ')', EOF})

    def test_follow_F(self):
        self.assertEqual(self.follow['F'], {'*', '+', ')', EOF})


class TestLL1TableG3(unittest.TestCase):
    def setUp(self):
        first        = compute_first(G3)
        follow       = compute_follow(G3, first, start='E')
        self.table, self.conflicts = build_ll1_table(G3, first, follow)

    def test_no_conflicts(self):
        self.assertEqual(self.conflicts, [])

    def test_E_on_lparen(self):
        self.assertEqual(self.table['E']['('], ['T', "E'"])

    def test_E_on_id(self):
        self.assertEqual(self.table['E']['id'], ['T', "E'"])

    def test_Eprime_on_plus(self):
        self.assertEqual(self.table["E'"]['+'], ['+', 'T', "E'"])

    def test_Eprime_on_rparen(self):
        self.assertEqual(self.table["E'"][')'], [EPSILON])

    def test_Eprime_on_eof(self):
        self.assertEqual(self.table["E'"][EOF], [EPSILON])

    def test_F_on_lparen(self):
        self.assertEqual(self.table['F']['('], ['(', 'E', ')'])

    def test_F_on_id(self):
        self.assertEqual(self.table['F']['id'], ['id'])


class TestLL1ConflictG4(unittest.TestCase):
    def setUp(self):
        first        = compute_first(G4)
        follow       = compute_follow(G4, first, start='S')
        _, self.conflicts = build_ll1_table(G4, first, follow)

    def test_has_conflict(self):
        self.assertGreater(len(self.conflicts), 0)

    def test_conflict_is_on_S_and_a(self):
        nts      = {nt      for nt, t, *_ in self.conflicts}
        terminals = {t      for nt, t, *_ in self.conflicts}
        self.assertIn('S', nts)
        self.assertIn('a', terminals)


class TestFirstOfSequence(unittest.TestCase):
    def setUp(self):
        self.first = compute_first(G3)

    def test_empty_sequence_gives_epsilon(self):
        result = first_of_sequence([], self.first)
        self.assertIn(EPSILON, result)

    def test_terminal_at_start(self):
        result = first_of_sequence(['+', 'T', "E'"], self.first)
        self.assertEqual(result, {'+'})

    def test_nullable_prefix_propagates(self):
        # E' é nullable; sequência [E', T] → FIRST(T) ∪ (FIRST(E')-{ε})
        result = first_of_sequence(["E'", 'T'], self.first)
        self.assertIn('+', result)       # de E'
        self.assertIn('(', result)       # de T (quando E' = ε)
        self.assertIn('id', result)      # de T
        self.assertNotIn(EPSILON, result)  # T não é nullable


class TestFirstG5(unittest.TestCase):
    """Subset Racket: verifica propagação correta de ε em gramática recursiva."""

    def setUp(self):
        self.first = compute_first(G5)

    def test_program_has_epsilon(self):
        self.assertIn(EPSILON, self.first['Program'])

    def test_program_has_atom(self):
        self.assertIn('ATOM', self.first['Program'])

    def test_program_has_lparen(self):
        self.assertIn('LPAREN', self.first['Program'])

    def test_expr_no_epsilon(self):
        self.assertNotIn(EPSILON, self.first['Expr'])

    def test_exprlist_has_rparen(self):
        self.assertIn('RPAREN', self.first['ExprList'])


class TestFollowG5(unittest.TestCase):
    def setUp(self):
        first       = compute_first(G5)
        self.follow = compute_follow(G5, first, start='Program')

    def test_program_follow_is_eof(self):
        self.assertEqual(self.follow['Program'], {EOF})

    def test_expr_follow_has_rparen(self):
        self.assertIn('RPAREN', self.follow['Expr'])

    def test_expr_follow_has_eof(self):
        self.assertIn(EOF, self.follow['Expr'])

    def test_exprlist_follow_has_eof(self):
        self.assertIn(EOF, self.follow['ExprList'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
