CC    = gcc
FLEX  = flex
BISON = bison

all: compilador

compilador: lex.yy.c parser.tab.c ast.c semantic.c codegen.c
	$(CC) -o compilador lex.yy.c parser.tab.c ast.c semantic.c codegen.c

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d parser.y

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

clean:
	rm -f compilador scanner lex.yy.c parser.tab.c parser.tab.h
