#include <stddef.h>
#include <stdint.h>

typedef struct Lexer Lexer;

size_t DotenvLexer_LexerStructSize();

void DotenvLexer_init(Lexer* lexer, const char* input, size_t input_size);

typedef enum DotenvLexer_TokenKind {
    DotenvLexer_TokenKind_Error_InvalidCharacter,
    DotenvLexer_TokenKind_Value,
    DotenvLexer_TokenKind_UnterminatedValue,
    DotenvLexer_TokenKind_UnterminatedDoubleQuotedValue,
    DotenvLexer_TokenKind_SingleQuotedValue,
    DotenvLexer_TokenKind_DoubleQuotedValue,
    DotenvLexer_TokenKind_EOF,
    DotenvLexer_TokenKind_WhiteSpace,
    DotenvLexer_TokenKind_Assign,
    DotenvLexer_TokenKind_Comment,
} DotenvLexer_TokenKind;

typedef struct DotenvLexer_Token {
    uint32_t start;
    uint32_t end;
    uint32_t line;
    uint32_t last_char_pos;
    DotenvLexer_TokenKind kind;
} DotenvLexer_Token;

DotenvLexer_Token DotenvLexer_next(Lexer* lexer);
