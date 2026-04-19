# compiladores
Trabalho prático da disciplina de Compiladores, da UFF.

Scanner + parser top-down para a linguagem Racket.

## Compilar

```
cabal build
```

## Executar

### Passando um arquivo

```
cabal run compiladores -v0 -- examples/valid/08_programa_completo.rkt
```

### Passando código direto pelo terminal

```
echo "(define x 42)" | cabal run compiladores -v0
```

### Saída esperada (código válido)

```
(define x 42)
```

### Saída esperada (código inválido)

```
Erro: Fim de arquivo inesperado
```

---

## Exemplos incluídos

| Arquivo | Descrição |
|---|---|
| `examples/valid/01_basico.rkt` | Literais: inteiro, float, bool, string, símbolo |
| `examples/valid/02_define.rkt` | `define` variável, função e lambda |
| `examples/valid/03_if.rkt` | `if` com e sem `else`, fatorial recursivo |
| `examples/valid/04_cond.rkt` | `cond` com cláusula `else` |
| `examples/valid/05_let.rkt` | `let` e `let*` |
| `examples/valid/06_and_or_begin.rkt` | `and`, `or`, `begin` |
| `examples/valid/07_quote.rkt` | `quote` e `'` |
| `examples/valid/08_programa_completo.rkt` | Programa completo com múltiplas definições |
| `examples/invalid/01_paren_aberto.rkt` | Parêntese não fechado |
| `examples/invalid/02_paren_extra.rkt` | Parêntese a mais |
| `examples/invalid/03_define_incompleto.rkt` | `define` sem valor |
| `examples/invalid/04_string_aberta.rkt` | String sem fechar |

### Rodar todos os exemplos de uma vez

**PowerShell:**
```
foreach ($f in Get-ChildItem examples/valid/*.rkt) {
    Write-Host "=== $($f.Name) ==="
    cabal run compiladores -v0 -- $f.FullName
}
```

**Linux / macOS:**
```
for f in examples/valid/*.rkt; do
    echo "=== $f ==="
    cabal run compiladores -v0 -- $f
done
```

---

## Análise FIRST/FOLLOW (Python)

```
python first_follow.py
```

Testes unitários do algoritmo:

```
python -m unittest test_first_follow -v
```
