package codin
import "core:unicode"
import "core:unicode/utf8"
import "core:fmt"

Position :: struct {
    ind: int,
    line_n: int,
    line_ind: int,
    filename: string
}

Token_Kind :: enum {
    Invalid = 0,

    Int_Literal, // i32
    Int, // int keyword
    
    Identifier,

    Star,
    Plus,
    Minus,
    Slash,
    Equal,
    Integer,
    Newline,
    Open_Paren,
    Close_Paren,
    Print,
    Semicolon,
    EOF
}

Token :: struct {
    kind: Token_Kind,
    int_val: C_int,
    pos: Position,
    text: string
}

Lexer :: struct {
    data: []rune,
    pos: Position,
}


lexer_skip_whitespaces :: proc(using lexer: ^Lexer)
{
    is_whitespace :: proc(char: rune) -> bool
    {
	whitespaces :: [?]rune{' ', '\t', '\n', '\r', '\f'}
	for ws in whitespaces {
	    if char == ws {
		return true
	    }
	}
	return false
    }

    for {
	if lexer_reached_eof(lexer^) do return
	c := lexer_peek(lexer)
	if !is_whitespace(c) {
	    return 
	}
	lexer_next(lexer)
	if c == '\n' {
	    pos.line_ind = pos.ind - 1
	    pos.line_n += 1
	}
    }
}

lexer_peek :: proc(using lexer: ^Lexer) -> rune
{
    if lexer_reached_eof(lexer^) do return 0
    return data[pos.ind]
}

lexer_next :: proc(using lexer: ^Lexer) -> rune
{
    if lexer_reached_eof(lexer^) do return 0
    pos.ind += 1
    return data[pos.ind - 1]
}

lexer_reached_eof :: proc(using lexer: Lexer) -> bool
{
    return !(pos.ind < len(data))
}

lexer_expect_token :: proc(lexer: ^Lexer, kind: Token_Kind) -> (Token, bool)
{
    if tok, ok := lexer_next_token(lexer); ok {
	if tok.kind != kind {
	    logf_pos(.Error, tok.pos, "Expected token %v, found %v\n", kind, tok.kind)
	    return tok, false
	} else {
	    return tok, true
	}
    } else {
	return tok, false
    }
}

lexer_peek_token :: proc(using lexer: ^Lexer) -> (tok: Token, ok: bool)
{
    tok = lexer_next_token(lexer) or_return
    lexer.pos = tok.pos
    return tok, true
}

//
// WARNING: Token.text survives only until the next keyword_from_symbol call, this may be bad
//
lexer_next_token :: proc(using lexer: ^Lexer) -> (tok: Token, ok: bool)
{
    lexer_skip_whitespaces(lexer)
    tok.pos = pos
    char := lexer_peek(lexer)
    switch char {
    case 0:
	tok.kind = .EOF
	lexer_next(lexer)
    case '(':
	tok.kind = .Open_Paren
	lexer_next(lexer)
    case ')':
	tok.kind = .Close_Paren
	lexer_next(lexer)
    case '+':
	tok.kind = .Plus
	lexer_next(lexer)
    case '-':
	tok.kind = .Minus
	lexer_next(lexer)
    case '*':
	tok.kind = .Star
	lexer_next(lexer)
    case '/':
	tok.kind = .Slash
	lexer_next(lexer)
    case ';':
	tok.kind = .Semicolon
	lexer_next(lexer)
    case '=':
	tok.kind = .Equal
	lexer_next(lexer)
    case '0'..<'9':
	tok.kind = .Int_Literal
	tok.int_val = lexer_scan_int(lexer)
    case :
	if unicode.is_alpha(char) {
	    symbol := lexer_scan_symbol(lexer) or_return
	    if kind, ok := keyword_from_symbol(symbol); ok {
		tok.kind = kind
	    } else {
		tok.kind = .Identifier
		tok.text = symbol
	    }
	} else {
	    tok.kind = .Invalid
	    logf_pos(.Error, pos, "Unexpected char '%c'x", char)
	    return 
	}
    }
    return tok, true
}

keyword_from_symbol :: proc(symbol: string) -> (Token_Kind, bool)
{
    switch symbol {
    case "print":
	return .Print, true
    case "int":
	return .Int, true
    }
    return .Invalid, false
}

lexer_scan_symbol :: proc(using lexer: ^Lexer) -> (symbol: string, ok: bool)
{
    // We know that len of text will be at least one since putback must be alpha
    BUFF_LEN :: 512
    @static buff : [BUFF_LEN]u8
    index := 0
    // We need to iter until we hit a non-alphanumeric character
    
    for {
	char := lexer_peek(lexer)
	if !(unicode.is_digit(char) || unicode.is_alpha(char)) {
	    break
	}
	lexer_next(lexer)
	b, n := utf8.encode_rune(char)
	copy(buff[index:(index + n)], b[:n])
	index += n
    }
    return string(buff[0:index]), true
}

lexer_scan_int :: proc(using lexer: ^Lexer) -> (num: C_int)
{
    int_from_digit :: proc(char: rune) -> (C_int, bool)
    {
	digits := [?]rune{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
	for d, i in digits {
	    if char == d do return C_int(i), true
	}
	return 0, false
    }

    for {
	char := lexer_peek(lexer)
	digit, keep_on := int_from_digit(char)
	if !keep_on {
	    break
	}
	lexer_next(lexer)
	num = num * 10 + digit
    }
    return
}
