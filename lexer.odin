package codin
import "core:fmt"
import "core:unicode"
import "core:unicode/utf8"

Position :: struct {
    ind: int,
    line_n: int,
    line_ind: int,
    filename: string
}

position_tprint :: proc(using pos: Position) -> string
{
    return fmt.tprintf("%s:%i:%i:",filename, line_n + 1, ind - line_ind)
}

Token_Kind :: enum {
    Invalid,
    Int_Literal, // i32
    Star,
    Plus,
    Minus,
    Slash,
    Integer,
    Newline,
    Open_Paren,
    Close_Paren,
    Print,
    EOF,
    Semicolon
}

Token :: struct {
    kind: Token_Kind,
    int_val: C_int,
    pos: Position
}

Lexer :: struct {
    data: []rune,
    pos: Position,
    putback: rune,
    last_token: Token
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
	c := lexer_next(lexer)
	if !is_whitespace(c) {
	    lexer.putback = c
	    return 
	}
	if c == '\n' {
	    pos.line_ind = pos.ind - 1
	    pos.line_n += 1
	}	  
    }
}

lexer_next :: proc(using lexer: ^Lexer) -> rune
{
    if lexer_reached_eof(lexer^) do return 0
    if putback != 0 {
	char := putback
	putback = 0
	return char
    }
    pos.ind += 1
    return data[pos.ind - 1]
}

lexer_reached_eof :: proc(using lexer: Lexer) -> bool
{
    return !(pos.ind < len(data))
}

lexer_expect_token :: proc(lexer: ^Lexer, kind: Token_Kind) -> bool
{
    if tok, ok := lexer_next_token(lexer); ok {
	if tok.kind != kind {
	    fmt.printfln("ERROR: %s Expected token %v, found %v", position_tprint(tok.pos), kind, tok.kind)
	    return false
	} else {
	    return true
	}
    } else {
	return false
    }
}

lexer_peek_token :: proc(using lexer: ^Lexer) -> (tok: Token, ok: bool)
{
    tok = lexer_next_token(lexer) or_return
    lexer.pos = tok.pos
    return tok, true
}

lexer_next_token :: proc(using lexer: ^Lexer) -> (tok: Token, ok: bool)
{
    lexer_skip_whitespaces(lexer)
    char := lexer_next(lexer)
    tok.pos = pos
    switch char {
    case 0:
	tok.kind = .EOF
    case '(':
	tok.kind = .Open_Paren
    case ')':
	tok.kind = .Close_Paren
    case '+':
	tok.kind = .Plus
    case '-':
	tok.kind = .Minus
    case '*':
	tok.kind = .Star
    case '/':
	tok.kind = .Slash
    case ';':
	tok.kind = .Semicolon
    case '0'..<'9':
	tok.kind = .Int_Literal
	putback = char
	tok.int_val = lexer_scan_int(lexer)
    case :
	if unicode.is_alpha(char) {
	    putback = char
	    symbol := lexer_scan_symbol(lexer) or_return
	    if kind, ok := keyword_from_symbol(symbol); ok {
		tok.kind = kind
	    } else {
		tok.kind = .Invalid
		fmt.println("ERROR: %s Unrecognized symbol '%s'", position_tprint(pos), symbol)
		return 
	    }
	} else {
	    tok.kind = .Invalid
	    fmt.printfln("ERROR: %s Unexpected char '%c'", position_tprint(pos), char)
	    return 
	}
    }
    last_token = tok
    return tok, true
}

keyword_from_symbol :: proc(symbol: string) -> (Token_Kind, bool)
{
    switch symbol {
    case "print":
	return .Print, true
    }
    return .Invalid, true
}
lexer_scan_symbol :: proc(using lexer: ^Lexer) -> (symbol: string, ok: bool)
{
    // We know that len of text will be at least one since putback must be alpha
    BUFF_LEN :: 512
    @static buff : [BUFF_LEN]u8
    index := 0
    // We need to iter until we hit a non-alphanumeric character
    
    for {
	char := lexer_next(lexer)
	if !(unicode.is_digit(char) || unicode.is_alpha(char)) {
	    putback = char
	    break
	}
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
	char := lexer_next(lexer)
	digit, unfinished := int_from_digit(char)
	if !unfinished {
	    lexer.putback = char
	    break
	}
	num = num * 10 + digit
    }

    return
}
