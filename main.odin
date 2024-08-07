package codin
import "core:fmt"
import "core:os"
import "core:unicode/utf8"
import "core:unicode"
import "core:strings"
import "core:c/libc"

C_int :: i64

usage :: proc()
{
    usage_msg ::
`usage: codin <source> [output]`
    fmt.println(usage_msg)
}

_main :: proc() -> bool
{
    if len(os.args) < 2 {
	logf(.Error, "No input file\n")
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
	logf(.Error, " Could not load file '%s'\n", filename)
	return false
    }
    data := utf8.string_to_runes(string(u8_data))
    defer delete(data)

    code := generate_assembly(data, filename) or_return
    defer strings.builder_destroy(&code)
    
    output_asm := fmt.tprintf("%s.fasm", output_filename)    
    logf(.Info, "Dumping assembly  to '%s'...", output_asm)
    os.write_entire_file(output_asm, code.buf[:])
    
    execute_command(fmt.ctprintf("fasm %s %s.o", output_asm, output_filename)) or_return
    execute_command(fmt.ctprintf("ld -o %s %s.o lib/lib.o" , output_filename, output_filename)) or_return

    logf(.Info, "Succesfully compiled '%s' into '%s'", filename, output_filename)
    
    delete(ast_node_pool)
    free_all(context.temp_allocator)
    return true
}

generate_assembly :: proc(data: []rune, filename: string) -> (code: strings.Builder, ok: bool)
{
    lexer := Lexer{data = data, pos = {filename = filename}}
    code = codegen_generate(&lexer) or_return
    return code, true
}

execute_command :: proc(command: cstring) -> bool
{
    logf(.Info, "Executing command '%s'", command)
    return libc.system(command) == 0
}

main :: proc()
{
    if !_main()
    {
	logf(.Error, " Could not compile program")
	os.exit(1)
    }
}
