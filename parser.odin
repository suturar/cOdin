package codin

parse_terminal :: proc(tok: Token) -> (^AST_Node, bool)
{
    #partial switch tok.kind {
    case .Int_Literal :
	return ast_leaf_make(.Int_Literal, tok.int_val), true
    case :
	error_unexpected_token(tok)
	return nil, false
    }
}

operator_precedence :: proc(tok: Token) -> (prec: int, ok: bool)
{
    ok = true
    
    #partial switch tok.kind {
	case .Plus, .Minus:
	prec = 10
	case .Star, .Slash:
	prec = 20
	case:
	ok = false
    }
    return
}

parse_binexpr :: proc(lexer: ^Lexer, prev_prec: int = -1) -> (node: ^AST_Node, ok: bool)
{
    // Assume the next one is a int_literal
    left := parse_terminal(lexer_next_token(lexer) or_return) or_return
    
    op_token := lexer_peek_token(lexer) or_return
    if op_token.kind == .Semicolon do return left, true
    // The next one ought to be an operator
    prec := operator_precedence(op_token) or_return
    for (prev_prec < prec) {
	lexer_next_token(lexer)
	right := parse_binexpr(lexer, prec) or_return
	left = ast_node_make(ast_kind_from_token(op_token) or_return, left, right, 0)
	if (lexer_peek_token(lexer) or_return).kind == .Semicolon do return left, true
	op_token = lexer_peek_token(lexer) or_return
	prec = operator_precedence(op_token) or_return
    }
    
    return left, true
}

