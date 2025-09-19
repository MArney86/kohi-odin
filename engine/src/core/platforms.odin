package core

import utf16 "core:unicode/utf16"
import mem "core:mem"
import time "core:time"

@(private)
// Platform state structure
platform_state :: struct {
    internal_state: rawptr,
}

@(private)
cstring_to_utf16 :: proc(str: cstring) -> ^u16 {
    str_odin := string(str)
    utf16_slice := make([]u16, len(str_odin) * 2)
    utf16.encode_string(utf16_slice, str_odin) // Use encode_string to fill the buffer
    return &utf16_slice[0]
}

@(private)
string_to_utf16 :: proc(str: string) -> ^u16 {
    utf16_slice := make([]u16, len(str) * 2)
    utf16.encode_string(utf16_slice, str)
    return &utf16_slice[0]
}

@(private)
platform_allocate :: proc(size: u64, aligned: b8) -> rawptr {
    new_mem, _ := mem.alloc(cast(int)size)
    return new_mem
}

@(private)
platform_free :: proc(block: rawptr, aligned: b8) {
    mem.free(block)
}

@(private)
platform_zero_memory :: proc(block: rawptr, size: u64) -> rawptr {
    return mem.zero(block, cast(int)size)
}

@(private)
platform_copy_memory :: proc(dest: rawptr, source: rawptr, size: u64) -> rawptr {
    return mem.copy(dest, source, cast(int)size)
}

@(private)
platform_set_memory :: proc(dest: rawptr, value: i32, size: u64) -> rawptr {
    return mem.set(dest, cast(byte)value, cast(int)size)
}

@(private)
platform_sleep :: proc(ms: u64) {
    time.sleep(time.Duration(ms * cast(u64)time.Millisecond))
}
