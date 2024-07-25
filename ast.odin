package codin
import "core:fmt"

AST_Node_Kind :: enum {
    Add,
    Multiply,
    Divide,
    Substract,
    Int_Literal
}

AST_Node :: struct {
    kind: AST_Node_Kind,
    left: ^AST_Node,
    right: ^AST_Node,
    int_val: C_int
}
ast_node_pool : [dynamic]AST_Node 

ast_kind_from_token :: proc(tok: Token) -> (astk: AST_Node_Kind, ok: bool)
{
    ok = true
    #partial switch tok.kind
    {
	case .Star:
	astk = .Multiply
	case .Slash:
	astk = .Divide
	case .Plus:
	astk = .Add
	case .Minus:
	astk = .Substract
	case:
	error_unexpected_token(tok)
	ok = false
    }
    return
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
	error_unexpected_token(tok)
	ok = false
    }
    return
}

error_unexpected_token :: proc(using tok: Token, loc := #caller_location)
{
    fmt.printfln("ERROR: %s Unexpected token %v", position_tprint(pos), tok.kind)
}

ast_node_make :: proc(kind: AST_Node_Kind, left: ^AST_Node, right: ^AST_Node, val: C_int) -> ^AST_Node
{
    append(&ast_node_pool, AST_Node{kind, left, right, val})
    return &ast_node_pool[len(ast_node_pool) - 1]
}
ast_leaf_make :: proc(kind: AST_Node_Kind, val: C_int) -> ^AST_Node
{
    return ast_node_make(kind, nil, nil, val)
}
ast_unitary_make :: proc(kind: AST_Node_Kind, left: ^AST_Node, val: C_int) -> ^AST_Node
{
    return ast_node_make(kind, left, nil, val)
}

ast_dump :: proc(root: ^AST_Node, indentation: int = 0)
{
    if indentation == 0 do fmt.println("===DUMPING AST===")
    for _ in 0..<indentation do fmt.print(" ")
    fmt.printfln("Node: kind = %s, val = %i", root.kind, root.int_val)
    if root.left != nil do ast_dump(root.left, indentation + 4)
    if root.right != nil do ast_dump(root.right, indentation + 4)
    if indentation == 0 do fmt.println("=================")
}


ast_interpret :: proc (using root: ^AST_Node) -> C_int
{
    switch kind {
    case .Int_Literal:
	return root.int_val
    case .Add:
	return ast_interpret(left) + ast_interpret(right)
    case .Substract:
	return ast_interpret(left) - ast_interpret(right)
    case .Multiply:
	return ast_interpret(left) * ast_interpret(right)
    case .Divide:
	return ast_interpret(left) / ast_interpret(right)
    }
    panic("Unexpected val in AST")
}
