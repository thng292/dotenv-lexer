const std = @import("std");

const Lexer = @This();

input: []const u8,
current_pos: u32 = 0,
line: u32 = 1,
char_in_line: u32 = 1,
last_token_kind: Token.Kind = .WhiteSpace,
last_quote: ?enum { Single, Double } = null,

pub const Token = extern struct {
    pub const Kind = enum(u8) {
        Error_InvalidCharacter,
        Value,
        UnterminatedValue,
        UnterminatedDoubleQuotedValue,
        SingleQuotedValue,
        DoubleQuotedValue,
        EOF,
        WhiteSpace,
        Assign,
        Comment,
    };
    start: u32 = 0,
    end: u32 = 0,
    line: u32 = 0,
    last_char_pos: u32 = 0,
    kind: Kind = .EOF,
};

const State = enum {
    AssignmentList,
    Comment,
    AssignmentName,
    AssignmentValue,
    AssignmentValueEscape,
    SingleQuoted,
    DoubleQuoted,
    DoubleQuotedEscape,
    Whitespace,
};

pub fn next(self: *Lexer) Token {
    var start = self.current_pos;
    var kind: Token.Kind = .EOF;
    var token_end_offset: u32 = 0; // Use for the multi-line value case, will get subtracted from the token.end

    var state: State = switch (self.last_token_kind) {
        .UnterminatedDoubleQuotedValue => .DoubleQuotedEscape, // new line with
        .UnterminatedValue => if (self.last_quote) |last_quote|
            switch (last_quote) {
                .Single => .SingleQuoted,
                .Double => .DoubleQuotedEscape,
            }
        else
            .AssignmentValueEscape,
        .SingleQuotedValue => .AssignmentValue,
        .DoubleQuotedValue => .AssignmentValue,
        .Assign => .AssignmentValue,
        else => .AssignmentList,
    };
    defer self.last_token_kind = kind;

    while (self.current_pos < self.input.len) : ({
        self.current_pos += 1;
        self.char_in_line += 1;
    }) {
        const c = self.input[self.current_pos];
        switch (state) {
            .Whitespace => switch (c) {
                ' ', '\t' => {},
                '\n' => {
                    self.line += 1;
                    self.char_in_line = 1;
                },
                else => {
                    kind = .WhiteSpace;
                    state = .AssignmentList;
                    break;
                },
            },
            .AssignmentList => switch (c) {
                ' ', '\t' => {
                    state = .Whitespace;
                },
                '\n' => {
                    state = .Whitespace;
                    self.line += 1;
                    self.char_in_line = 0;
                },
                '#' => state = .Comment,
                'a'...'z', 'A'...'Z', '_' => state = .AssignmentName,
                else => {
                    kind = .Error_InvalidCharacter;
                    break;
                },
            },
            .Comment => switch (c) {
                '\n' => {
                    kind = .Comment;
                    break;
                },
                else => {},
            },
            .AssignmentName => switch (c) {
                'a'...'z', 'A'...'Z', '_' => {},
                '=' => {
                    kind = .Assign;
                    state = .AssignmentValue;
                    self.current_pos += 1;
                    token_end_offset = 1;
                    break;
                },
                else => {
                    kind = .Error_InvalidCharacter;
                    break;
                },
            },
            .AssignmentValue => switch (c) {
                '\\' => {
                    // Skip the \
                    self.current_pos += 1;
                    token_end_offset = 1;

                    kind = .UnterminatedValue;
                    break;
                },
                '\'' => {
                    // Skip the '
                    self.current_pos += 1;
                    token_end_offset = 1;

                    self.last_quote = .Single;
                    kind = .UnterminatedValue;
                    break;
                },
                '"' => {
                    // Skip the "
                    self.current_pos += 1;
                    token_end_offset = 1;

                    self.last_quote = .Double;
                    kind = .UnterminatedValue;
                    break;
                },
                ' ', '\t', '\n' => {
                    // End of value if un-escaped
                    kind = .Value;
                    state = .AssignmentList;
                    break;
                },
                else => {},
            },
            .AssignmentValueEscape => switch (c) {
                // Read an \ => if new line then multiline value
                '\n' => {
                    self.line += 1;
                    self.char_in_line = 0;
                    start += 1;
                    state = .AssignmentValue;
                },
                else => {
                    state = .AssignmentValue;
                },
            },
            .SingleQuoted => switch (c) {
                '\'' => {
                    // Skip the '
                    self.current_pos += 1;
                    token_end_offset = 1;

                    self.last_quote = null;
                    kind = .SingleQuotedValue;
                    break;
                },
                '\n' => {
                    self.line += 1;
                    self.char_in_line = 1;
                },
                else => {},
            },
            .DoubleQuoted => switch (c) {
                '"' => {
                    // Skip the "
                    self.current_pos += 1;
                    token_end_offset = 1;

                    self.last_quote = null;
                    kind = .DoubleQuotedValue;
                    break;
                },
                '\\' => {
                    // Skip the \
                    self.current_pos += 1;
                    token_end_offset = 1;

                    kind = .UnterminatedDoubleQuotedValue;
                    break;
                },
                else => {},
            },
            .DoubleQuotedEscape => switch (c) {
                '\n' => {
                    kind = .UnterminatedValue;
                    self.line += 1;
                    self.char_in_line = 0;
                    start += 1;
                },
                else => state = .DoubleQuoted,
            },
        }
    } else if (self.current_pos >= self.input.len) {
        switch (state) {
            .AssignmentName => kind = .Error_InvalidCharacter,
            .AssignmentValue => kind = .Value,
            .SingleQuoted => kind = .UnterminatedValue,
            .DoubleQuoted => kind = .UnterminatedValue,
            .DoubleQuotedEscape => kind = .UnterminatedValue,
            .Whitespace => kind = .WhiteSpace,
            .AssignmentList => kind = .EOF,
            .AssignmentValueEscape => kind = .Value,
            .Comment => kind = .Comment,
        }
    }
    const end = self.current_pos - token_end_offset;
    return .{
        .start = start,
        .end = end,
        .kind = kind,
        .line = self.line,
        .last_char_pos = self.char_in_line,
    };
}

test {
    // const str =
    //     \\# This is a comment
    //     \\KEY=VALUE # another comment
    //     \\KEY=VALUE\
    //     \\\ VALUE
    //     \\
    //     \\KEY="VALUE\
    //     \\value"
    //     \\KEY='value
    //     \\value'
    // ;

    // const str =
    //     \\A=foo\
    //     \\bar
    //     \\B="foo\
    //     \\bar"
    // ;
    const str =
        \\FOO='foo'\''bar'
        \\FOO='foo'"'"'bar'
    ;
    var tokenizer = Lexer{ .input = str };
    for (1..30) |_| {
        const token = tokenizer.next();
        if (token.kind == .EOF) break;
        if (token.kind == .WhiteSpace) {
            std.debug.print("{:0>2}:-{:0>2} {} {any}\n", .{
                token.line,
                token.last_char_pos,
                token.kind,
                str[token.start..token.end],
            });
        } else {
            std.debug.print("{:0>2}:-{:0>2} {} {s}\n", .{
                token.line,
                token.last_char_pos,
                token.kind,
                str[token.start..token.end],
            });
        }
    }
}
