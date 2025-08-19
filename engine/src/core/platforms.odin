package Kcore

import utf16 "core:unicode/utf16"
import mem "core:mem"
import time "core:time"

// Platform state structure
platform_state :: struct {
    internal_state: rawptr,
}

cstring_to_utf16 :: proc(str: cstring) -> ^u16 {
    str_odin := string(str)
    utf16_slice := make([]u16, len(str_odin) * 2)
    utf16.encode_string(utf16_slice, str_odin) // Use encode_string to fill the buffer
    return &utf16_slice[0]
}

string_to_utf16 :: proc(str: string) -> ^u16 {
    utf16_slice := make([]u16, len(str) * 2)
    utf16.encode_string(utf16_slice, str)
    return &utf16_slice[0]
}

allocate :: proc(size: u64, aligned: b8) -> rawptr {
    new_mem, _ := mem.alloc(cast(int)size)
    return new_mem
}

free :: proc(block: rawptr, aligned: b8) {
    mem.free(block)
}

zero_memory :: proc(block: rawptr, size: u64) -> rawptr {
    return mem.zero(block, cast(int)size)
}

copy_memory :: proc(dest: rawptr, source: rawptr, size: u64) -> rawptr {
    return mem.copy(dest, source, cast(int)size)
}

set_memory :: proc(dest: rawptr, value: u8, size: u64) -> rawptr {
    return mem.set(dest, value, cast(int)size)
}

sleep :: proc(ms: u64) {
    time.sleep(time.Duration(ms * cast(u64)time.Millisecond))
}