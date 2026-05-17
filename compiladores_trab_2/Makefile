CC    = gcc
FLEX  = flex
BISON = bison

all: compilador scanner_demo

# ─── Demos para apresentacao ──────────────────────────────────────────────────

# Etapa 1 – Scanner: mostra tokens do arquivo de entrada
demo-scanner: scanner_demo
	@echo "=== ETAPA 1: SCANNER ==="
	@echo "Entrada: examples_ok.scm"
	@echo ""
	./scanner_demo < examples_ok.scm

# Etapa 2 – Parser: mostra AST e Python gerado
demo-parser: compilador
	@echo "=== ETAPA 2: PARSER ==="
	@echo "Entrada: tests/demo_parser.scm"
	@echo ""
	./compilador --ast < tests/demo_parser.scm

# Etapa 3 – Semantico: mostra erros de tipo e contexto
demo-sem-err: compilador
	@echo "=== ETAPA 3: VERIFICACAO SEMANTICA (erros esperados) ==="
	@echo "Entrada: tests/semantic_error.scm"
	@echo ""
	-./compilador < tests/semantic_error.scm 2>&1

demo-sem-ok: compilador
	@echo "=== ETAPA 3: VERIFICACAO SEMANTICA (sem erros) ==="
	@echo "Entrada: tests/semantic_ok.scm"
	@echo ""
	./compilador < tests/semantic_ok.scm

# Etapa 4 – Geracao de codigo Python
demo-codegen: compilador
	@echo "=== ETAPA 4: GERACAO DE CODIGO PYTHON ==="
	@echo "Entrada: tests/codegen_ok.scm"
	@echo ""
	./compilador < tests/codegen_ok.scm

# ─── Builds ───────────────────────────────────────────────────────────────────

compilador: lex.yy.c parser.tab.c ast.c semantic.c codegen.c
	$(CC) -o compilador lex.yy.c parser.tab.c ast.c semantic.c codegen.c

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d parser.y

scanner_demo: scanner_demo.l
	$(FLEX) -o scanner_demo.c scanner_demo.l
	$(CC) -o scanner_demo scanner_demo.c

lex.yy.c: scanner.l parser.tab.h
	$(FLEX) scanner.l

run-ok: compilador
	./compilador < examples_ok.scm

run-err: compilador
	./compilador < examples_lex_error.scm

run-parse-ok: compilador
	./compilador < tests/parse_ok.scm

run-parse-err: compilador
	./compilador < tests/parse_error.scm

run-sem-ok: compilador
	./compilador < tests/semantic_ok.scm

run-sem-err: compilador
	./compilador < tests/semantic_error.scm

run-codegen: compilador
	./compilador < tests/codegen_ok.scm

run-codegen-simple: compilador
	./compilador < tests/codegen_ok_simple.scm

clean:
	rm -f compilador scanner_demo scanner_demo.c lex.yy.c parser.tab.c parser.tab.h
