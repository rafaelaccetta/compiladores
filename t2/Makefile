CC = gcc
FLEX = flex

all: scanner

scanner: lex.yy.c
	$(CC) -o scanner lex.yy.c

lex.yy.c: scanner.l
	$(FLEX) scanner.l

run-ok: scanner
	./scanner < examples_ok.scm

run-err: scanner
	./scanner < examples_lex_error.scm

clean:
	rm -f scanner lex.yy.c
