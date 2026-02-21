#include "dotenv_lexer.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>

int main(void) {
  const char* input = "foo=bar bar=baz";
  Lexer* lexer = malloc(DotenvLexer_LexerStructSize());
  assert(lexer != NULL);
  DotenvLexer_init(lexer, input, strlen(input));
  printf("Hello world!\n");
  while (1) {
    const DotenvLexer_Token token = DotenvLexer_next(lexer);
    printf("%d\n", token.kind);
    if (token.kind == DotenvLexer_TokenKind_EOF) {
      break;
    }
  }
  return 0;
}
