package codin
import "core:fmt"
import "core:os"
import "core:unicode/utf8"
import "core:unicode"

C_int :: i32

_main :: proc() -> int {
    filename :: "example.c"
    u8_data, ok := os.read_entire_file(filename)
    defer delete(u8_data)
    if !ok {
	fmt.printfln("Could not load file '%s'", filename)
	return 1
    }
    data := utf8.string_to_runes(string(u8_data))
    defer delete(data)

    lexer := Lexer{data = data, pos = {filename = filename}}
    token_list : [dynamic]Token
    defer delete(token_list)
    fmt.println("INFO: Started parsing...")
    root, ok_parse := parse_binexpr(&lexer)
    fmt.println("INFO: Finished parsing...")
    if !ok_parse do return 1
    ast_dump(root)
    fmt.println("Result of interpreting AST: ", ast_interpret(root))

    delete(ast_node_pool)
    free_all(context.temp_allocator)
    return 0
}

main :: proc()
{
    os.exit(_main())
}
