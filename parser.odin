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

parse_binexpr :: proc(lexer: ^Lexer, prev_prec: int = -1) -> (node: ^AST_Node, ok: bool)
{

    // Assume the next one is a int_literal
    left := parse_terminal(lexer_next_token(lexer) or_return) or_return

    op_token := lexer_next_token(lexer) or_return
    if op_token.kind == .Semicolon do return left, true
    // The next one ought to be an operator
    prec := operator_precedence(op_token) or_return
    for (prev_prec < prec) {
	right := parse_binexpr(lexer, prec) or_return
	left = ast_node_make(ast_kind_from_token(op_token) or_return, left, right, 0)
	if lexer.last_token.kind == .Semicolon do return left, true
	prec = operator_precedence(lexer.last_token) or_return
	op_token = lexer.last_token
    } 
    return left, true
}
