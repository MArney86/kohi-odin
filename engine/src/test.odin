package Engine

import "core:c/libc"

// KAPI equivalent - exported procedure with C calling convention
when KEXPORT {
    @(export)
    print_int :: proc "c" (i: i32) {
        // Use simple C printf - no Odin runtime dependencies
        libc.printf("The number is: %d\n", i)
        libc.fflush(nil) // Flush output immediately
    }
} else {
    // When not exporting, this would be imported from external library
    print_int :: proc "c" (i: i32) {
        libc.printf("The number is: %d\n", i)
        libc.fflush(nil)
    }
}
