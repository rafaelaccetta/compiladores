# Instrucoes da etapa 1 (Scanner com Flex)

## Arquivos criados

- scanner.l
- Makefile
- examples_ok.scm
- examples_lex_error.scm

## Ferramentas necessarias

- flex
- gcc
- make (opcional, mas recomendado)

## Windows: opcoes praticas

### Opcao A: MSYS2 (recomendado)

No terminal MSYS2 UCRT64:

1. Instalar pacotes:
   pacman -S mingw-w64-ucrt-x86_64-flex mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-make
2. Entrar na pasta do projeto.
3. Executar:
   make
   make run-ok
   make run-err

### Opcao B: WSL Ubuntu

No Ubuntu (WSL):

1. Instalar pacotes:
   sudo apt update
   sudo apt install -y flex bison build-essential make
2. Entrar na pasta do projeto.
3. Executar:
   make
   make run-ok
   make run-err

## Sem Makefile

Tambem funciona com comandos diretos:

flex scanner.l
gcc -o scanner lex.yy.c
./scanner < examples_ok.scm
