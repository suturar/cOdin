package codin
import "core:strings"
import "core:fmt"

codegen_generate :: proc(lexer: ^Lexer) -> (stream: strings.Builder, ok: bool)
{
    codegen_preamble(&stream)
    codegen_statements(lexer, &stream) or_return
    codegen_postamble(&stream)
    return stream, true
}

codegen_printin :: proc(stream: ^strings.Builder, reg: int)
{
    fmt.sbprintfln(stream, "    ; Printint routine")
    fmt.sbprintfln(stream, "    mov rdi, %s", reg_list[reg].name)
    fmt.sbprintfln(stream, "    call printint")   
}

codegen_statements :: proc(lexer: ^Lexer, stream: ^strings.Builder) -> bool
{
    stmt_loop: for {
	token := lexer_next_token(lexer) or_return
	#partial switch token.kind {
	    case .Print:
	    codegen_print_statement(lexer, stream) or_return
	    case .EOF:
	    break stmt_loop
	    case:
	    error_unexpected_token(token)
	    return false
	}
	lexer_expect_token(lexer, .Semicolon)
    }
    return true
}

codegen_print_statement :: proc(lexer: ^Lexer, stream: ^strings.Builder) -> bool
{
    root := parse_binexpr(lexer) or_return
    result_reg := codegen_ast(stream, root)
    codegen_printin(stream, result_reg)
    reg_freeall()
    return true
}
codegen_preamble :: proc(stream: ^strings.Builder)
{
    preamble :: #load("ambles/preamble.fasm", string)
    fmt.sbprint(stream, preamble)
}

codegen_postamble :: proc(stream: ^strings.Builder)
{
    postamble :: #load("ambles/postamble.fasm", string)
    fmt.sbprint(stream, postamble)
}
codegen_ast :: proc(stream: ^strings.Builder, node: ^AST_Node) -> int
{
    left_reg, right_reg: int
    if node.left != nil do left_reg = codegen_ast(stream, node.left)
    if node.right != nil do right_reg = codegen_ast(stream, node.right)

    switch node.kind {
    case .Add:
	return codegen_add(stream, left_reg, right_reg)
    case .Multiply:
	return codegen_mul(stream, left_reg, right_reg)
    case .Divide:
	return codegen_div(stream, left_reg, right_reg)
    case .Substract:
	return codegen_sub(stream, left_reg, right_reg)
    case .Int_Literal:
	return codegen_load(stream, node.int_val)
    case :
	panic(fmt.tprintf("Unkown AST operator %v\n", node.kind))
        }
    return 0
}

codegen_add :: proc(stream: ^strings.Builder, left_reg, right_reg: int) -> int
{
    fmt.sbprintf(stream, "    ; Add\n")
    fmt.sbprintf(stream, "    add %s, %s\n", reg_list[left_reg].name, reg_list[right_reg].name)
    reg_free(right_reg)
    return left_reg
}
codegen_mul :: proc(stream: ^strings.Builder, left_reg, right_reg: int) -> int
{
    fmt.sbprintf(stream, "    ; Multiply\n")
    fmt.sbprintf(stream, "    imul %s, %s\n", reg_list[left_reg].name, reg_list[right_reg].name)
    reg_free(right_reg)
    return left_reg
}
codegen_div :: proc(stream: ^strings.Builder, left_reg, right_reg: int) -> int
{
    fmt.sbprintfln(stream, "    ; Divide")
    fmt.sbprintfln(stream, "    mov rax, %s", reg_list[left_reg].name)
    fmt.sbprintfln(stream, "    cqo")
    fmt.sbprintfln(stream, "    idiv %s", reg_list[right_reg].name)
    fmt.sbprintfln(stream, "    mov  %s, rax", reg_list[left_reg].name)
    reg_free(right_reg)
    return left_reg
}
codegen_sub :: proc(stream: ^strings.Builder, left_reg, right_reg: int) -> int
{
    fmt.sbprintf(stream, "    ; Substract\n")
    fmt.sbprintf(stream, "    sub %s, %s\n", reg_list[left_reg].name, reg_list[right_reg].name)
    reg_free(right_reg)
    return left_reg
}

codegen_load :: proc(stream: ^strings.Builder, val: C_int) -> int
{
    reg := reg_alloc()
    fmt.sbprintf(stream, "    ; Load integer literal\n")
    fmt.sbprintf(stream, "    mov %s, %i\n", reg_list[reg].name, val)
    return reg
}

Register :: struct
{
    name: string,
    is_free: bool
}

reg_list := [?]Register{
    {"r8", true},
    {"r9", true},
    {"r10", true},
    {"r11", true},
}

reg_free :: proc(i: int)
{
    reg_list[i].is_free = true
}

reg_alloc :: proc() -> int
{
    for &reg, i in reg_list {
	if reg.is_free == true {
	    reg.is_free = false
	    return i
	}
    }
    panic("Ran out of registers")
}

reg_freeall :: proc()
{
    for &reg in reg_list do reg.is_free = true
}
