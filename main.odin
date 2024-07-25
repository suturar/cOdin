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

_main :: proc() -> bool
{
    if len(os.args) < 2 {
	fmt.println("ERROR: No input file")
	usage()
	return false
    }
    filename := os.args[1]
    output_filename := "output"
    if len(os.args) >= 3 {
	output_filename = os.args[2]
    }

    // Load file data and transform it into a slice of runes
    u8_data, ok := os.read_entire_file(filename)
    defer delete(u8_data)
    if !ok {
	fmt.printfln("Could not load file '%s'", filename)
	return false
    }
    data := utf8.string_to_runes(string(u8_data))
    defer delete(data)

    code := generate_assembly(data, filename) or_return
    defer strings.builder_destroy(&code)
    
    output_asm := fmt.tprintf("%s.fasm", output_filename)    
    fmt.printfln("INFO: Dumping assembly  to '%s'...", output_asm)
    os.write_entire_file(output_asm, code.buf[:])
    
    execute_command(fmt.ctprintf("fasm %s %s.o", output_asm, output_filename)) or_return
    execute_command(fmt.ctprintf("ld -o %s %s.o lib/lib.o" , output_filename, output_filename)) or_return

    fmt.printfln("INFO: Succesfully compiled '%s' into '%s'", filename, output_filename)
    
    delete(ast_node_pool)
    free_all(context.temp_allocator)
    return true
}

generate_assembly :: proc(data: []rune, filename: string) -> (code: strings.Builder, ok: bool)
{
    lexer := Lexer{data = data, pos = {filename = filename}}
    code = codegen_generate(&lexer)
    return code, true
}

execute_command :: proc(command: cstring) -> bool
{
    fmt.printfln("INFO: Executing command '%s'", command)
    return libc.system(command) == 0
}

main :: proc()
{
    if !_main() do os.exit(1)
}
