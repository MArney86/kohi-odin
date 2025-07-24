package Testbed

import "base:runtime"

// Import the engine library
foreign import engine "../../bin/engine.lib"

@(default_calling_convention="c")
foreign engine {
    print_int :: proc(i: i32) ---
}

main :: proc() {
    context = runtime.default_context()
    
    // Example usage of the print_int procedure from the engine DLL
    print_int(42)
}