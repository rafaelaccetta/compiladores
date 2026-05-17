CC    = gcc
FLEX  = flex
BISON = bison

all: compilador

compilador: lex.yy.c parser.tab.c ast.c
	$(CC) -o compilador lex.yy.c parser.tab.c ast.c

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

clean:
	rm -f compilador scanner lex.yy.c parser.tab.c parser.tab.h
