package codin
import "core:strings"
Symbol :: struct {
    text: string
}

symbol_table : map[string]Symbol

symbol_table_add :: proc(s: string) -> bool
{
    // TODO: Using other rather than arena storage
    s := strings.clone(s, allocator = context.temp_allocator)
    if s in symbol_table do return false
    symbol_table[s] = {s}
    return true
}

