package lib
import "core:sys/linux"


@export printint :: proc "c" (val: int)
{
    val := val
    negative := val < 0
    if negative do val *= -1
    STDOUT : int = 1
    @static buff: [64]u8 
    buff[len(buff) - 1] = '\n'
    index: int = 1

    for {
	digit := val % 10
	buff[len(buff) - 1 - index] = u8(digit) + '0'
	val /= 10
	index += 1
	if val == 0 do break
    }
    if negative {
	buff[len(buff) - 1 - index] = '-'
	index += 1
    }
    _ = linux.syscall(linux.SYS_write, STDOUT, &buff[len(buff) - index], index)
}
