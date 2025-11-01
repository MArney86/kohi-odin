package helpers

import utf16 "core:unicode/utf16"
import runtime "base:runtime"

/* 
Convert UTF-8 string to Windows wide string (UTF-16)

Inputs: 
    s: string - UTF-8 encoded string

Outputs:
    [^]u16 - Pointer to UTF-16 encoded wide string (null-terminated). Must be deleted after use.
        Returns nil on failure or if input string is empty.
*/
utf8_to_wstring :: proc(s: string) -> [^]u16 {
    if len(s) == 0 {
        return nil
    }
    
    // Estimate buffer size (UTF-8 to UTF-16 can expand, especially for surrogate pairs)
    // Worst case: each UTF-8 rune could become 2 UTF-16 units (surrogate pair)
    estimated_size := (len(s) * 4) + 1 // +1 for null terminator
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


    return &final_buf[0]
}

/* 
Convert Windows wide string (UTF-16) to UTF-8 string 

Inputs:
    s: [^]u16 - Pointer to UTF-16 encoded wide string (null-terminated). Must be deleted after use.

Outputs:
    string - UTF-8 encoded string. Must be deleted after use.
*/

wstring_to_utf8 :: proc(s: [^]u16) -> string {
    if s == nil {
        return ""
    }
    
    // Find length of wide string
    len_ws := 0
    for s[len_ws] != 0 {
        len_ws += 1
    }
    
    if len_ws == 0 {
        return ""
    }
    
    // Convert to slice for decoding
    ws_slice := s[:len_ws]
    
    // Allocate buffer for UTF-8 conversion
    // Worst case: each UTF-16 unit could become 4 UTF-8 bytes
    utf8_buf := make([]byte, len_ws * 4)
    
    // Decode UTF-16 to UTF-8
    utf8_bytes := utf16.decode_to_utf8(utf8_buf, ws_slice)
    if utf8_bytes == 0 && len_ws > 0 {
        delete(utf8_buf)
        return ""
    }
    
    // Resize buffer to actual UTF-8 bytes used
    final_buf := make([]byte, utf8_bytes)
    copy(final_buf, utf8_buf[:utf8_bytes])
    delete(utf8_buf) // Clean up temporary buffer
    
    return string(final_buf)
}