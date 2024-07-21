package codin
import "core:fmt"
import "core:os"
import "core:unicode/utf8"
import "core:unicode"
import "core:strings"
import "core:c/libc"

C_int :: i32

_main :: proc() -> int
{
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

    fmt.println("INFO: Generating assembly...")
    code_builder := strings.Builder{}
    defer strings.builder_destroy(&code_builder)
    codegen_preamble(&code_builder)
    result_reg := codegen_ast(&code_builder, root)
    fmt.sbprintf(&code_builder, "    mov rdi, %s\n", reg_list[result_reg].name)
    fmt.sbprintf(&code_builder, "    call printint\n")
    codegen_postamble(&code_builder)
    fmt.println("INFO: Dumping assembly to 'output.fasm'...")
    os.write_entire_file("output.fasm", code_builder.buf[:])
    if !generate_executable() do return 1

    delete(ast_node_pool)
    free_all(context.temp_allocator)
    return 0
}

generate_executable :: proc() -> bool
{
    command :: "fasm output.fasm output.o"
    fmt.printfln("INFO: Calling fasm with '%s'", command)
    command_linker :: "ld -o output output.o lib.o"
    fmt.printfln("INFO: Calling ld with '%s'", command_linker)

    return libc.system(command) == 0 && libc.system(command_linker) == 0
}

main :: proc()
{
    os.exit(_main())
}
