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


/* 
Convert Windows wide string (UTF-16) to UTF-8 string 

Inputs:
    s: [^]u16 - Pointer to UTF-16 encoded wide string (null-terminated). Must be deleted after use.

Outputs:
    string - UTF-8 encoded string. Must be deleted after use.
*/

