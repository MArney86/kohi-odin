package Testbed

import Kcore "../../engine/src/core"
import "core:fmt"
import "core:c/libc"

// Boolean constants
TRUE :: true
FALSE :: false

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
    // Core KAPI logging function
    log_output :: proc(level: i32, message: cstring) --- 
    
    // Logger convenience functions exported from engine
    KFATAL :: proc(message: cstring) ---
    KERROR :: proc(message: cstring) ---
    KWARN :: proc(message: cstring) ---
    KINFO :: proc(message: cstring) ---
    KDEBUG :: proc(message: cstring) ---
    KTRACE :: proc(message: cstring) ---
    
    // Assertion functions with file/line parameters
    KASSERT :: proc(expr: bool, file: cstring, line: i32) ---
    KASSERT_MSG :: proc(expr: bool, message: cstring, file: cstring, line: i32) ---
    KASSERT_DEBUG :: proc(expr: bool, file: cstring, line: i32) ---

    // Platform state management
    platform_startup :: proc(plat_state: ^Kcore.platform_state, application_name: cstring, x: i32, y: i32, width: i32, height: i32) -> b8 ---
    platform_shutdown :: proc(plat_state: ^Kcore.platform_state) ---
    platform_pump_messages :: proc(plat_state: ^Kcore.platform_state) -> b8 ---
}

// Wrapper procedures to handle caller location automatically
KASSERT_O :: proc(expr: bool, loc := #caller_location) {
    KASSERT(expr, cstring(raw_data(loc.file_path)), i32(loc.line))
}

KASSERT_MSG_O :: proc(expr: bool, message: string, loc := #caller_location) {
    KASSERT_MSG(expr, cstring(raw_data(message)), cstring(raw_data(loc.file_path)), i32(loc.line))
}

KASSERT_DEBUG_O :: proc(expr: bool, loc := #caller_location) {
    KASSERT_DEBUG(expr, cstring(raw_data(loc.file_path)), i32(loc.line))
}

main :: proc() {
    fmt.println("Starting testbed...")

    // Test logging functions
    KFATAL("A test message: FATAL")
    KERROR("A test message: ERROR")
    KWARN("A test message: WARN")
    KINFO("A test message: INFO") 
    KDEBUG("A test message: DEBUG")
    KTRACE("A test message: TRACE")

    KINFO("Creating platform state...")
    state := Kcore.platform_state{}
    
    KINFO("About to call platform_startup...")
    
    if (platform_startup(&state, "kohi Engine Testbed", 100, 100, 1280, 720)) {
        KINFO("Platform startup successful, entering message loop...")
        for (TRUE) {
            if !platform_pump_messages(&state) {
                KINFO("Received quit message, breaking...")
                break
            }
        }
    } else {
        KERROR("Platform startup failed!")
    }

    KINFO("Test completed without platform calls")
    
    KINFO("Shutting down platform...")
    platform_shutdown(&state)
    KINFO("Platform shutdown complete.")

    fmt.println("Test completed")
    
    // Force immediate exit to avoid cleanup segfault
    libc.exit(0)
}