package Testbed

import "base:runtime"
import "core:fmt"
import "core:c/libc"

// Platform-specific import for the engine library
when ODIN_OS == .Windows {
    foreign import Engine "../../bin/engine.lib"
} else when ODIN_OS == .Linux {
    foreign import Engine "../../bin/libengine.so"
} else {
    #panic("Unsupported platform")
}

@(default_calling_convention="c")
foreign Engine {
    print_int :: proc(i: i32) ---
}

main :: proc() {
    fmt.println("Starting testbed...")
    
    // Example usage of the print_int procedure from the engine DLL
    print_int(42)
    
    fmt.println("About to exit...")
    
    // Force immediate exit to avoid cleanup issues
    libc.exit(0)
}