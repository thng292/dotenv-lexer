pub const Lexer = @import("lexer.zig");
const std = @import("std");

const C_Lexer = extern struct {};

// Intended for C code use
pub export fn DotenvLexer_LexerStructSize() callconv(.c) usize {
    return @sizeOf(Lexer);
}

// Intended for C code use
pub export fn DotenvLexer_init(
    lexer: [*c]C_Lexer,
    input: [*]const u8,
    input_len: usize,
) callconv(.c) void {
    const res: *Lexer = @ptrCast(@alignCast(lexer));
    res.* = .{ .input = input[0..input_len] };
}

// Intended for C code use
pub export fn DotenvLexer_next(lexer: [*c]C_Lexer) callconv(.c) Lexer.Token {
    const _lexer: *Lexer = @ptrCast(@alignCast(lexer));
    return _lexer.next();
}

test {
    @import("std").testing.refAllDecls(Lexer);
}
