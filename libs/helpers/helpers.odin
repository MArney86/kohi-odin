package helpers

import utf16 "core:unicode/utf16"

cstring_to_utf16 :: proc(str: cstring) -> ^u16 {
    str_odin := string(str)
    utf16_slice := make([]u16, len(str_odin) * 2)
    defer delete(utf16_slice)
    utf16.encode_string(utf16_slice, str_odin) // Use encode_string to fill the buffer
    return &utf16_slice[0]
}

string_to_utf16 :: proc(str: string) -> ^u16 {
    utf16_slice := make([]u16, len(str) * 2)
    defer delete(utf16_slice)
    utf16.encode_string(utf16_slice, str)
    return &utf16_slice[0]
}