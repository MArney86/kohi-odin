package Engine

import "core:fmt"
import "base:runtime"

// KAPI equivalent - exported procedure with C calling convention
when KEXPORT {
    @(export)
    print_int :: proc "c" (i: I32) {
        context = runtime.default_context()
        fmt.printf("The number is: %i\n", i)
    }
} else {
    // When not exporting, this would be imported from external library
    // For now, we'll just define it normally for internal use
    print_int :: proc "c" (i: I32) {
        context = runtime.default_context()
        fmt.printf("The number is: %i\n", i)
    }
}
