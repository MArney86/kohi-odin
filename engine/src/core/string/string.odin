package engine_string

import "core:log"
import strings "core:strings"
import utf16 "core:unicode/utf16"
import runtime "base:runtime"
import builtin "base:builtin"
import types "../../types"
import mem "../memory"
import logger "../logger"

@(export)
len_cstr ::proc(cstr: cstring) -> u64 {
    return cast(u64)runtime.cstring_len(cstr)
}

@(export)
len_cstr16 ::proc(cstr: cstring16) -> u64 {
    return cast(u64)runtime.cstring16_len(cstr)
}

@(export)
len_str :: proc(str: string) -> u64 {
    return cast(u64)len(str)
}

@(export)
len_str16 :: proc(str: string16) -> u64 {
    return cast(u64)len(str)
}

length :: proc{
    len_cstr,
    len_cstr16,
    len_str,
    len_str16,
}

@(export)
dp_cstr :: proc(cstr: cstring) -> cstring {
    str_length := runtime.cstring_len(cstr)
    c, err := make([]byte, str_length+1)
    if err != .None {
        return nil
    }
    mem.copy_memory(cast(rawptr)&c[0], cast(rawptr)cstr, cast(u64)str_length+1)
    mem.stats.total_allocated += cast(u64)(str_length+1)
    mem.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_STRING] += cast(u64)(str_length+1)
    return cast(cstring)&c[0]
}

@(export)
dp_cstr16 :: proc(cstr: cstring16) -> cstring16 {
    str_length := runtime.cstring16_len(cstr)
    c, err := make([]u16, str_length+1)
    if err != .None {
        return nil
    }
    mem.copy_memory(cast(rawptr)&c[0], cast(rawptr)cstr, cast(u64)(str_length+1)*2)
    mem.stats.total_allocated += cast(u64)(str_length+1)*2
    mem.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_STRING] += cast(u64)(str_length+1)*2
    return cast(cstring16)&c[0]
}

@(export)
dp_str :: proc(str: string) -> string {
    str_clone := strings.clone(str)
    size := length(str_clone)
    mem.stats.total_allocated += size
    mem.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_STRING] += size
    return str_clone
}

@(export)
dp_str16 :: proc(str: string16) -> string16 {
    c, err := make([]u16, len(str))
    if err != .None {
        return ""
    }
    copy(c, str)
    size := len_str16(str)
    mem.stats.total_allocated += size * 2
    mem.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_STRING] += size * 2
    return string16(c)
}

duplicate :: proc{
    dp_cstr,
    dp_cstr16,
    dp_str,
    dp_str16,
}

@(export)
eq_cstr :: proc(str_a, str_b: cstring) -> bool {
    return runtime.cstring_eq(str_a, str_b)
}

@(export)
eq_cstr16 :: proc(str_a, str_b: cstring16) -> bool {
    return runtime.cstring16_eq(str_a, str_b)
}

@(export)
eq_str :: proc(str_a, str_b: string) -> bool {
    return runtime.string_eq(str_a, str_b)
}

@(export)
eq_str16 :: proc(str_a, str_b: string16) -> bool {
    return runtime.string16_eq(str_a, str_b)
}

equals :: proc {
    eq_cstr,
    eq_cstr16,
    eq_str,
    eq_str16,
}

str_to_wstring :: proc(s: string) -> cstring16 {
    if len(s) == 0 {
        return nil
    }
    
    // Estimate buffer size (UTF-8 to UTF-16 can expand, especially for surrogate pairs)
    // Worst case: each UTF-8 rune could become 2 UTF-16 units (surrogate pair)
    estimated_size := (len(s) * 4) + 2 // +2 for null terminator
    buf := make([]u16, estimated_size)
    
    // Encode UTF-8 string to UTF-16
    utf16_count := utf16.encode_string(buf, s)
    if utf16_count == 0 && len(s) > 0 {
        delete(buf)
        return nil
    }
    
    // Resize buffer to actual size needed + null terminator
    final_buf := make([]u16, utf16_count + 1)
    copy(final_buf, buf[:utf16_count])
    final_buf[utf16_count] = 0 // Null terminate
    
    delete(buf) // Clean up temporary buffer


    return cast(cstring16)&final_buf[0]
}

wstring_to_str :: proc(s: cstring16) -> string {
    if s == nil {
        return ""
    }
    
    // Find length of wide string
    s_len := runtime.cstring16_len(s)
    
    // Convert cstring16 to []u16 slice for decoding
    ws_slice := ([^]u16)(s)[:s_len]
    
    // Allocate buffer for UTF-8 conversion
    // Worst case: each UTF-16 unit could become 4 UTF-8 bytes
    utf8_buf := make([]byte, s_len * 4)
    
    // Decode UTF-16 to UTF-8
    utf8_bytes := utf16.decode_to_utf8(utf8_buf, ws_slice)
    if utf8_bytes == 0 && s_len > 0 {
        delete(utf8_buf)
        return ""
    }
    
    // Resize buffer to actual UTF-8 bytes used
    final_buf := make([]byte, utf8_bytes)
    copy(final_buf, utf8_buf[:utf8_bytes])
    delete(utf8_buf) // Clean up temporary buffer
    
    return string(final_buf)
}

bytes_to_cstr :: proc(data: []u8, loc: runtime.Source_Code_Location = #caller_location) -> cstring {
    length: u64 = 0
    for b in data {
        if b == 0 {
            break
        }
        length += 1
    }
    
    if length == 0 {
        logger.ERROR("Input data is empty in bytes_to_cstr:\n%s, %s:%s = %s", loc.file_path, loc.line, loc.column, loc.procedure)
        return nil
    }

    c, err := make([]byte, length + 1)
    if err != .None {
        logger.ERROR("Failed to allocate memory in bytes_to_cstr:\n%s, %s:%s = %s", loc.file_path, loc.line, loc.column, loc.procedure)
        return nil
    }
    mem.copy_memory(cast(rawptr)&c[0], &data[0], length)
    c[length] = 0 // Null terminate
    mem.stats.total_allocated += length + 1
    mem.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_STRING] += length + 1
    return cast(cstring)&c[0]
}