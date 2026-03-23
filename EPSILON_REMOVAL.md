# Remoção de Transições Epsilon (ε-NFA → NFA)

## O problema

Um **ε-NFA** (EpsilonNFA) é um autômato que permite transições "de graça" — sem consumir nenhum símbolo da entrada. Essas transições são chamadas de **transições epsilon (ε)**.

Embora sejam convenientes para construir autômatos (por exemplo, a partir de expressões regulares), elas complicam a simulação. O objetivo é converter um ε-NFA em um **NFA equivalente sem nenhuma transição ε**, preservando exatamente a linguagem reconhecida.

---

## O autômato de exemplo

O teste usa um ε-NFA para a linguagem $(ab)^*$ — zero ou mais repetições da sequência `ab`.

```
Estado 0 --a--> Estado 1
Estado 1 --b--> Estado 2
Estado 2 --ε--> Estado 0   (volta para repetir)
Estado 2 --ε--> Estado 3   (aceita aqui)

Inicial: 0
Final:   {3}
```

Visualmente:

```
        a           b           ε
  →[0] ---> [1] ---> [2] -----> [3] (final)
    ↑                 |
    └─────────ε───────┘
```

O estado 3 só é alcançado via ε a partir do estado 2. Isso significa que, para aceitar `"ab"`, o autômato precisa:
1. Ler `a`: vai de 0 para 1
2. Ler `b`: vai de 1 para 2
3. Fazer ε: vai de 2 para 3 (estado final) — **sem consumir mais nada**

---

## O algoritmo: `epsilonClosure`

Antes de eliminar as ε-transições, precisamos calcular o **ε-fecho** de um estado — o conjunto de todos os estados alcançáveis usando **apenas** transições ε (incluindo o próprio estado).

```haskell
epsilonClosure :: EpsilonNFA -> [Int] -> [Int]
```

Funciona como uma **busca em largura (BFS)**:
- começa com os estados iniciais
- para cada estado na fila, segue todas as transições `Nothing` (ε)
- acumula os novos estados e continua até não haver mais para explorar

### Resultado para o exemplo

| Estado | ε-fecho |
|--------|---------|
| 0      | {0}     |
| 1      | {1}     |
| 2      | {0, 2, 3} ← segue 2→0 e 2→3 via ε |
| 3      | {3}     |

O estado 2 tem ε-fecho `{0, 2, 3}` porque de 2 dá para ir, via ε, até 0 e 3. De 0 e 3 não saem mais ε-transições, então para por aí.

---

## O algoritmo principal: `removeEpsilon`

```haskell
removeEpsilon :: EpsilonNFA -> NFA
```

O NFA resultante tem os mesmos estados e o mesmo estado inicial. O que muda são as **transições** e os **estados finais**.

### Nova função de transição

Para calcular `δ'(q, a)` (onde o estado `q` vai ao ler o símbolo `a`):

```
δ'(q, a) = ε-fecho( ⋃{ δ(r, a) | r ∈ ε-fecho(q) } )
```

Em português:
1. Calcula o ε-fecho de `q` — todos os estados "gratuitos" a partir de `q`
2. De cada um desses estados, aplica a transição com o símbolo `a`
3. Calcula o ε-fecho do resultado — todos os estados gratuitos após a transição

**Exemplo:** `δ'(0, 'a')` no autômato original:
1. ε-fecho(0) = {0}
2. δ(0, 'a') = {1}
3. ε-fecho({1}) = {1}
→ `δ'(0, 'a') = {1}`

**Exemplo:** `δ'(1, 'b')`:
1. ε-fecho(1) = {1}
2. δ(1, 'b') = {2}
3. ε-fecho({2}) = {0, 2, 3}
→ `δ'(1, 'b') = {0, 2, 3}`

Isso captura o loop: ao ler `b` a partir do estado 1, o NFA vai para {0, 2, 3} — já está simultaneamente no início (pronto para repetir `ab`) e no estado final (pronto para aceitar).

### Novos estados finais

Um estado `q` passa a ser final no NFA se **algum estado no seu ε-fecho era final no ε-NFA**:

```
q ∈ F'  sse  ε-fecho(q) ∩ F ≠ ∅
```

Verificando cada estado:

| Estado | ε-fecho    | Intersecta {3}? | Final? |
|--------|------------|-----------------|--------|
| 0      | {0}        | Não             | Não    |
| 1      | {1}        | Não             | Não    |
| 2      | {0, 2, 3}  | **Sim** (tem 3) | **Sim** |
| 3      | {3}        | **Sim**         | **Sim** |

Resultado: estados finais do NFA = `{2, 3}`.

Isso faz sentido: o estado 2 no NFA original "equivale" a estar em {0,2,3}, que inclui o estado final 3.

---

## Antes e depois

### ε-NFA (entrada)

| Estado | `'a'` | `'b'` | `ε`    | Final? |
|--------|-------|-------|--------|--------|
| →0     | {1}   | {}    | {}     | Não    |
| 1      | {}    | {2}   | {}     | Não    |
| 2      | {}    | {}    | {0, 3} | Não    |
| 3      | {}    | {}    | {}     | **Sim** |

```
         a           b           ε
  →[0] -----> [1] -----> [2] -------> [3]* (final)
    ↑                     |
    └──────────ε───────────┘
```

### NFA sem ε (saída do `removeEpsilon`)

| Estado | `'a'` | `'b'`     | Final? |
|--------|-------|-----------|--------|
| →0     | {1}   | {}        | Não    |
| 1      | {}    | {0, 2, 3} | Não    |
| **2**  | {1}   | {}        | **Sim** |
| **3**  | {}    | {}        | **Sim** |

```
         a               b
  →[0] -----> [1] -----------------> [0], [2]*, [3]*
                          [2]* --a--> [1]
                          [3]*  (sem transições)
```

O que mudou:
- As transições `ε` **sumiram**
- `1 --b-->` expandiu de `{2}` para `{0, 2, 3}` (absorveu o ε-fecho de 2)
- `2 --a--> {1}` é uma transição **nova** (surgiu porque ε-fecho(2) contém o estado 0, que tem `0 --a--> 1`)
- Estado **2 virou final** (seu ε-fecho alcançava o estado 3)

---

## Simulação do NFA resultante

A função `acceptsNFA` executa o NFA mantendo um **conjunto de estados ativos** e aplicando a nova transição a cada símbolo lido:

```haskell
acceptsNFA nfa "ab"
  = foldl step [0] "ab"
  -- passo 1: step [0] 'a' = δ'(0,'a') = [1]
  -- passo 2: step [1] 'b' = δ'(1,'b') = [0,2,3]
  -- estados finais ativos: {2,3} ∩ {0,2,3} = {2,3} ≠ ∅  → ACEITA
```

### Por que `""` é rejeitada?

O estado inicial é 0. O ε-fecho de 0 é {0}, que não contém nenhum estado final. Portanto a cadeia vazia não é aceita — o autômato modela $(ab)^+$ implicitamente (pelo menos um `ab`).

### Tabela completa de testes

| Entrada  | Estados ao final | Aceita? | Motivo |
|----------|-----------------|---------|--------|
| `""`     | {0}             | Não     | 0 não é final |
| `"ab"`   | {0,2,3}         | Sim     | 2 e 3 são finais |
| `"abab"` | {0,2,3}         | Sim     | repete o loop |
| `"a"`    | {1}             | Não     | 1 não é final |
| `"b"`    | {}              | Não     | δ'(0,'b') = ∅ |
| `"aba"`  | {1}             | Não     | last state 1 não é final |

---

## Resumo do fluxo

```
ε-NFA
  │
  ├─ epsilonClosure(q) para cada estado q
  │       │
  │       └─ BFS seguindo só transições ε
  │
  └─ removeEpsilon
          │
          ├─ nova transição: δ'(q,a) = ε-fecho(δ(ε-fecho(q), a))
          └─ novos finais:   q final se ε-fecho(q) ∩ F_original ≠ ∅
          │
          ▼
         NFA (sem ε) — mesma linguagem, mais simples de simular
```
