#!/usr/bin/env python3
"""FIRST, FOLLOW e tabela LL(1) para a gramática Racket."""

from collections import defaultdict

EPSILON = 'ε'
EOF     = '$'

grammar: dict[str, list[list[str]]] = {
    'Program': [
        ['Expr', 'Program'],
        [EPSILON],
    ],
    'Expr': [
        ['BOOL'],
        ['INT'],
        ['FLOAT'],
        ['STRING'],
        ['SYMBOL'],
        ['QUOTE',            'Expr'],
        ['QUASIQUOTE',       'Expr'],
        ['UNQUOTE',          'Expr'],
        ['UNQUOTE_SPLICING', 'Expr'],
        ['LPAREN', 'Form'],
    ],
    'Form': [
        ['RPAREN'],
        ['KW_DEFINE',  'DefineForm'],
        ['KW_LAMBDA',  'LambdaForm'],
        ['KW_IF',      'IfForm'],
        ['KW_COND',    'CondClauses'],
        ['KW_AND',     'ExprList'],
        ['KW_OR',      'ExprList'],
        ['KW_BEGIN',   'ExprList'],
        ['KW_LET',     'LetForm'],
        ['KW_LETSTAR', 'LetForm'],
        ['KW_QUOTE',   'Expr', 'RPAREN'],
        ['Expr',       'ExprList'],
    ],
    'DefineForm': [
        ['LPAREN', 'SYMBOL', 'SymList', 'ExprList'],
        ['SYMBOL', 'Expr', 'RPAREN'],
    ],
    'LambdaForm': [
        ['LPAREN', 'SymList', 'ExprList'],
    ],
    # CONFLITO LL(1) esperado: ambas começam com Expr Expr
    # O parser recursivo resolve verificando o token após as 2 expressões.
    'IfForm': [
        ['Expr', 'Expr', 'RPAREN'],
        ['Expr', 'Expr', 'Expr', 'RPAREN'],
    ],
    'CondClauses': [
        ['RPAREN'],
        ['LPAREN', 'CondClause', 'CondClauses'],
    ],
    'CondClause': [
        ['Expr', 'ExprList'],
    ],
    'LetForm': [
        ['LPAREN', 'Bindings', 'ExprList'],
    ],
    'Bindings': [
        ['RPAREN'],
        ['LPAREN', 'SYMBOL', 'Expr', 'RPAREN', 'Bindings'],
    ],
    'ExprList': [
        ['RPAREN'],
        ['Expr', 'ExprList'],
    ],
    'SymList': [
        ['RPAREN'],
        ['SYMBOL', 'SymList'],
    ],
}

def is_terminal(sym: str, nts: set[str]) -> bool:
    return sym not in nts and sym != EPSILON


# =============================================================================
# FIRST
# =============================================================================

def compute_first(g: dict) -> dict[str, set[str]]:
    nts = set(g.keys())
    first: dict[str, set[str]] = defaultdict(set)

    changed = True
    while changed:
        changed = False
        for nt, prods in g.items():
            for prod in prods:
                if prod == [EPSILON]:
                    if EPSILON not in first[nt]:
                        first[nt].add(EPSILON)
                        changed = True
                    continue
                for sym in prod:
                    if is_terminal(sym, nts):
                        if sym not in first[nt]:
                            first[nt].add(sym)
                            changed = True
                        break
                    else:
                        before = len(first[nt])
                        first[nt] |= (first[sym] - {EPSILON})
                        if len(first[nt]) > before:
                            changed = True
                        if EPSILON not in first[sym]:
                            break
                else:
                    if EPSILON not in first[nt]:
                        first[nt].add(EPSILON)
                        changed = True

    return first


def first_of_sequence(seq: list[str], first: dict) -> set[str]:
    result: set[str] = set()
    for sym in seq:
        if sym == EPSILON:
            result.add(EPSILON)
            break
        if sym not in first:
            result.add(sym)
            break
        result |= (first[sym] - {EPSILON})
        if EPSILON not in first[sym]:
            break
    else:
        result.add(EPSILON)
    return result


# =============================================================================
# FOLLOW
# =============================================================================

def compute_follow(g: dict, first: dict, start: str = 'Program') -> dict[str, set[str]]:
    nts = set(g.keys())
    follow: dict[str, set[str]] = defaultdict(set)
    follow[start].add(EOF)

    changed = True
    while changed:
        changed = False
        for nt, prods in g.items():
            for prod in prods:
                if prod == [EPSILON]:
                    continue
                for i, sym in enumerate(prod):
                    if is_terminal(sym, nts):
                        continue
                    after = prod[i + 1:]
                    first_after = first_of_sequence(after, first) if after else {EPSILON}
                    before = len(follow[sym])
                    follow[sym] |= (first_after - {EPSILON})
                    if EPSILON in first_after:
                        follow[sym] |= follow[nt]
                    if len(follow[sym]) > before:
                        changed = True

    return follow


# =============================================================================
# Tabela LL(1)
# =============================================================================

def build_ll1_table(g: dict, first: dict, follow: dict):
    table: dict[str, dict[str, list]] = defaultdict(dict)
    conflicts: list[tuple] = []

    for nt, prods in g.items():
        for prod in prods:
            fp = {EPSILON} if prod == [EPSILON] else first_of_sequence(prod, first)

            for terminal in fp - {EPSILON}:
                if terminal in table[nt] and table[nt][terminal] != prod:
                    conflicts.append((nt, terminal, table[nt][terminal], prod))
                else:
                    table[nt][terminal] = prod

            if EPSILON in fp:
                for terminal in follow[nt]:
                    if terminal in table[nt] and table[nt][terminal] != prod:
                        conflicts.append((nt, terminal, table[nt][terminal], prod))
                    else:
                        table[nt][terminal] = prod

    return table, conflicts


# =============================================================================
# Formatação e saída
# =============================================================================

def fmt_prod(prod: list[str]) -> str:
    return ' '.join(prod) if prod != [EPSILON] else EPSILON


def fmt_set(s: set[str]) -> str:
    items = sorted(s, key=lambda x: (x == EPSILON, x == EOF, x))
    return '{ ' + ', '.join(items) + ' }'


def print_section(title: str) -> None:
    print()
    print('=' * 66)
    print(f'  {title}')
    print('=' * 66)


def main() -> None:
    first  = compute_first(grammar)
    follow = compute_follow(grammar, first)
    table, conflicts = build_ll1_table(grammar, first, follow)

    # ── FIRST ────────────────────────────────────────────────────────────────
    print_section('CONJUNTOS FIRST')
    for nt in sorted(grammar):
        print(f'  FIRST({nt:<15}) = {fmt_set(first[nt])}')

    # ── FOLLOW ───────────────────────────────────────────────────────────────
    print_section('CONJUNTOS FOLLOW')
    for nt in sorted(grammar):
        print(f'  FOLLOW({nt:<14}) = {fmt_set(follow[nt])}')

    # ── TABELA LL(1) ─────────────────────────────────────────────────────────
    print_section('TABELA LL(1)')
    for nt in sorted(table):
        print(f'\n  {nt}:')
        for terminal in sorted(table[nt], key=lambda x: (x == EOF, x)):
            print(f'    [{terminal:>20}]  →  {fmt_prod(table[nt][terminal])}')

    # ── CONFLITOS ────────────────────────────────────────────────────────────
    print_section('VERIFICAÇÃO LL(1)')
    if not conflicts:
        print('  ✓ Gramática é LL(1) — nenhum conflito encontrado.')
    else:
        print(f'  ✗ {len(conflicts)} conflito(s) encontrado(s):\n')
        for nt, terminal, prod1, prod2 in conflicts:
            print(f'  Não-terminal : {nt}')
            print(f'  Terminal     : {terminal}')
            print(f'  Produção 1   : {nt} → {fmt_prod(prod1)}')
            print(f'  Produção 2   : {nt} → {fmt_prod(prod2)}')
            print()

        print('  Explicação:')
        print('    O conflito em IfForm é esperado e intencional.')
        print('    (if cond então) vs (if cond então senão) têm o mesmo FIRST.')
        print('    O parser de descida recursiva resolve com lookahead:')
        print('    após parsear 2 expressões, verifica se o próximo token é')
        print("    RPAREN (sem ramo else) ou outra expressão (com ramo else).")
        print()
        print('    Isso não é uma falha — é uma gramática LL(2) nesse ponto,')
        print('    mas o parser recursivo já trata corretamente.')


if __name__ == '__main__':
    main()
