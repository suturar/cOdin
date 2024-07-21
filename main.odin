package codin
import "core:fmt"
import "core:os"
import "core:unicode/utf8"
import "core:unicode"
import "core:strings"
import "core:c/libc"

C_int :: i32

usage :: proc()
{
    usage_msg ::
`usage: codin <source> [output]`
    fmt.println(usage_msg)
}

_main :: proc() -> int
{
    if len(os.args) < 2 {
	fmt.println("ERROR: No input file")
	usage()
	return 1
    }
    filename := os.args[1]
    output_filename := "output"
    if len(os.args) >= 3 {
	output_filename = os.args[2]
    }
    u8_data, ok := os.read_entire_file(filename)
    defer delete(u8_data)
    
    if !ok {
	fmt.printfln("Could not load file '%s'", filename)
	return 1
    }
    
    data := utf8.string_to_runes(string(u8_data))
    defer delete(data)
    lexer := Lexer{data = data, pos = {filename = filename}}
    
    fmt.println("INFO: Started parsing...")
    root, ok_parse := parse_binexpr(&lexer)
    if !ok_parse do return 1
    fmt.println("INFO: Finished parsing...")


    fmt.println("INFO: Generating assembly...")
    code_builder := strings.Builder{}
    defer strings.builder_destroy(&code_builder)
    codegen_preamble(&code_builder)
    result_reg := codegen_ast(&code_builder, root)
    fmt.sbprintf(&code_builder, "    mov rdi, %s\n", reg_list[result_reg].name)
    fmt.sbprintf(&code_builder, "    call printint\n")
    codegen_postamble(&code_builder)
    fmt.println("INFO: Dumping assembly to 'output.fasm'...")

    output_asm := fmt.tprintf("%s.fasm", output_filename)
    os.write_entire_file(output_asm, code_builder.buf[:])
    if !execute_command(fmt.ctprintf("fasm %s %s.o", output_asm, output_filename)) do return 1
    if !execute_command(fmt.ctprintf("ld -o %s %s.o lib.o" , output_filename, output_filename)) do return 1
    
    delete(ast_node_pool)
    free_all(context.temp_allocator)
    return 0
}

execute_command :: proc(command: cstring) -> bool
{
    fmt.printfln("INFO: Executing command '%s'", command)
    return libc.system(command) == 0
}

main :: proc()
{
    os.exit(_main())
}
