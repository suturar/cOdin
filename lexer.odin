package codin
import "core:fmt"

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
    EOF,
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

lexer_next_token :: proc(using lexer: ^Lexer) -> (Token, bool)
{
    tok: Token
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
    case '0'..<'9':
	tok.kind = .Int_Literal
	putback = char
	tok.int_val = lexer_scan_int(lexer)
    case :
	tok.kind = .Invalid
	fmt.printfln("ERROR: %s Unexpected char '%c'", position_tprint(pos), char)
	return tok, false
    }
    last_token = tok
    return tok, true
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
