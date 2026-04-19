#!/usr/bin/env python3
"""
Calcula conjuntos FIRST e FOLLOW para a gramática Racket,
gera a tabela LL(1) e reporta conflitos.

Gramática derivada de RacketParser.hs (descida recursiva).

Convenções:
  - Não-terminais: TitleCase  (Program, Expr, Form, ...)
  - Terminais:     MAIÚSCULAS (BOOL, INT, LPAREN, ...)
  - Palavras-chave Racket tratadas como terminais distintos de SYMBOL
    (o lexer pode fazer esse split; ex.: TSymbol "define" → KW_DEFINE)
"""

from collections import defaultdict

EPSILON = 'ε'
EOF     = '$'

# =============================================================================
# Gramática do Racket
# =============================================================================
#
# Derivada diretamente de RacketParser.hs:
#
#   parseExpr   → cada caso do pattern matching
#   parseList   → Form
#   parseDefine → DefineForm
#   parseLambda → LambdaForm
#   parseIf     → IfForm          ← ÚNICO conflito LL(1) esperado
#   parseCond   → CondClauses / CondClause
#   parseLet    → LetForm / Bindings
#   parseExprs  → ExprList        (consome o ')' de fechamento)
#   parseSymList→ SymList
#
# Terminais do tipo Token (RacketLexer):
#   BOOL  INT  FLOAT  STRING  SYMBOL  LPAREN  RPAREN  DOT
#   QUOTE  QUASIQUOTE  UNQUOTE  UNQUOTE_SPLICING
#   KW_DEFINE  KW_LAMBDA  KW_IF  KW_COND  KW_AND  KW_OR
#   KW_BEGIN   KW_LET     KW_LETSTAR  KW_QUOTE
# =============================================================================

grammar: dict[str, list[list[str]]] = {

    # programa = zero ou mais expressões de nível superior
    'Program': [
        ['Expr', 'Program'],
        [EPSILON],
    ],

    # expressão atômica ou composta
    'Expr': [
        ['BOOL'],
        ['INT'],
        ['FLOAT'],
        ['STRING'],
        ['SYMBOL'],
        ['QUOTE',             'Expr'],
        ['QUASIQUOTE',        'Expr'],
        ['UNQUOTE',           'Expr'],
        ['UNQUOTE_SPLICING',  'Expr'],
        ['LPAREN', 'Form'],
    ],

    # interior de uma lista já com '(' consumido
    # cada alternativa é responsável por consumir o ')' de fechamento
    'Form': [
        ['RPAREN'],                               # ()  lista vazia
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
        ['Expr', 'ExprList'],                     # aplicação genérica
    ],

    # (define (f p...) corpo...)  ou  (define x expr)
    'DefineForm': [
        ['LPAREN', 'SYMBOL', 'SymList', 'ExprList'],   # função
        ['SYMBOL', 'Expr', 'RPAREN'],                  # variável
    ],

    # (lambda (p...) corpo...)
    'LambdaForm': [
        ['LPAREN', 'SymList', 'ExprList'],
    ],

    # (if cond então)  ou  (if cond então senão)
    # *** CONFLITO LL(1) ***: ambas começam com Expr Expr
    #     O parser resolve com lookahead após ler 2 expressões.
    'IfForm': [
        ['Expr', 'Expr', 'RPAREN'],
        ['Expr', 'Expr', 'Expr', 'RPAREN'],
    ],

    # zero ou mais cláusulas (teste corpo...) até ')'
    'CondClauses': [
        ['RPAREN'],
        ['LPAREN', 'CondClause', 'CondClauses'],
    ],

    # teste seguido de corpo, com ')' já consumido pelo CondClauses
    'CondClause': [
        ['Expr', 'ExprList'],
    ],

    # (let ((x v)...) corpo...)
    'LetForm': [
        ['LPAREN', 'Bindings', 'ExprList'],
    ],

    # lista de bindings até ')'
    'Bindings': [
        ['RPAREN'],
        ['LPAREN', 'SYMBOL', 'Expr', 'RPAREN', 'Bindings'],
    ],

    # zero ou mais expressões + ')' de fechamento
    'ExprList': [
        ['RPAREN'],
        ['Expr', 'ExprList'],
    ],

    # lista de símbolos (parâmetros) até ')'
    'SymList': [
        ['RPAREN'],
        ['SYMBOL', 'SymList'],
    ],
}

NON_TERMINALS: set[str] = set(grammar.keys())


def is_terminal(sym: str) -> bool:
    return sym not in NON_TERMINALS and sym != EPSILON


def _is_terminal_in(sym: str, nts: set[str]) -> bool:
    """Versão local: verifica se sym é terminal em relação ao conjunto nts."""
    return sym not in nts and sym != EPSILON


# =============================================================================
# Cálculo de FIRST
# =============================================================================

def compute_first(g: dict) -> dict[str, set[str]]:
    """
    FIRST(A) = conjunto de terminais que podem aparecer como primeiro símbolo
               de alguma cadeia derivada de A.
               Se A deriva ε, então ε ∈ FIRST(A).

    Algoritmo iterativo (ponto-fixo):
      Para cada produção A → X1 X2 ... Xk:
        - Adiciona FIRST(X1) - {ε} em FIRST(A)
        - Se ε ∈ FIRST(X1), adiciona FIRST(X2) - {ε}, etc.
        - Se todos derivam ε, adiciona ε em FIRST(A)
    """
    nts: set[str] = set(g.keys())   # não-terminais desta gramática
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
                    if _is_terminal_in(sym, nts):
                        # terminal: adiciona e para
                        if sym not in first[nt]:
                            first[nt].add(sym)
                            changed = True
                        break
                    else:
                        # não-terminal: propaga FIRST sem ε
                        before = len(first[nt])
                        first[nt] |= (first[sym] - {EPSILON})
                        if len(first[nt]) > before:
                            changed = True
                        if EPSILON not in first[sym]:
                            break  # não deriva ε: para aqui
                else:
                    # todos os símbolos derivam ε
                    if EPSILON not in first[nt]:
                        first[nt].add(EPSILON)
                        changed = True

    return first


def first_of_sequence(seq: list[str], first: dict) -> set[str]:
    """FIRST de uma sequência de símbolos.

    Um símbolo é tratado como não-terminal se estiver presente em `first`
    (i.e., foi calculado como não-terminal por compute_first).
    """
    result: set[str] = set()
    for sym in seq:
        if sym == EPSILON:
            result.add(EPSILON)
            break
        if sym not in first:   # terminal: não tem FIRST próprio
            result.add(sym)
            break
        result |= (first[sym] - {EPSILON})
        if EPSILON not in first[sym]:
            break
    else:
        result.add(EPSILON)
    return result


# =============================================================================
# Cálculo de FOLLOW
# =============================================================================

def compute_follow(g: dict, first: dict, start: str = 'Program') -> dict[str, set[str]]:
    """
    FOLLOW(A) = conjunto de terminais que podem aparecer imediatamente
                à direita de A em alguma forma sentencial.
                $ ∈ FOLLOW(símbolo inicial).

    Algoritmo iterativo:
      Para cada produção B → αAβ:
        - Adiciona FIRST(β) - {ε} em FOLLOW(A)
        - Se ε ∈ FIRST(β), adiciona FOLLOW(B) em FOLLOW(A)
    """
    nts: set[str] = set(g.keys())   # não-terminais desta gramática
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
                    if _is_terminal_in(sym, nts):
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
# Tabela LL(1) e verificação de conflitos
# =============================================================================

def build_ll1_table(g: dict, first: dict, follow: dict):
    """
    Para cada A → α:
      - Para cada a ∈ FIRST(α) - {ε}: table[A][a] = α
      - Se ε ∈ FIRST(α): para cada b ∈ FOLLOW(A): table[A][b] = α

    Conflito: table[A][a] já ocupado com produção diferente.
    """
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
