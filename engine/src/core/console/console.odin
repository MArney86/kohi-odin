package console

import "core:fmt"
import "core:os"

// Simple console output functions that don't depend on platform
// This breaks the circular dependency between logger and platform

// FATAL,ERROR,WARN,INFO,DEBUG,TRACE
colour_strings := [6]string{"0;41", "1;31", "1;33", "1;32", "1;34", "1;30"}

write :: proc(message: string, colour: u8) {
    
    if colour < len(colour_strings) {
        fmt.printf("\033[%sm%s\033[0m", colour_strings[colour], message)
        os.flush(os.stdout)
    } else {
        fmt.printf(message)
        os.flush(os.stdout)
    }
}

write_error :: proc(message: string, colour: u8) {
    temp := colour
    
    if colour < len(colour_strings) {
        fmt.eprintf("\033[%sm%s\033[0m", colour_strings[colour], message)
        os.flush(os.stderr)
    } else {
        fmt.eprintf(message)
        os.flush(os.stderr)
    }
}