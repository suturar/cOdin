package codin
import "core:fmt"

LOG_CALLER_LOCATION :: false
LogType :: enum{Warning, Error, Info}
LogHeaders := [LogType]string{
	.Warning = "WARNING",
	.Error = "ERROR",
	.Info = "INFO"
}

position_tprint :: proc(using pos: Position) -> string
{
    return fmt.tprintf("%s:%i:%i",filename, line_n + 1, ind - line_ind)
}

logf_pos :: proc(lt: LogType, pos: Position, fmt_str: string, args: ..any, loc := #caller_location)
{
    header := LogHeaders[lt]
    fmt.printf("%s: %s %s\n", header, position_tprint(pos), fmt.tprintf(fmt_str, ..args))
    when LOG_CALLER_LOCATION do fmt.printf("from: %v \n", loc)
}

logf :: proc(lt: LogType, fmt_str: string, args: ..any, loc := #caller_location)
{
    header := LogHeaders[lt]
    fmt.printf("%s: %s\n", header, fmt.tprintf(fmt_str, ..args))
    when LOG_CALLER_LOCATION do	fmt.printf("from: %v \n", loc)
}
