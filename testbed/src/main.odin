package Testbed

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
    @(link_name="KASSERT")
    KASSERT_raw :: proc(expr: bool, file: cstring, line: i32) ---
    @(link_name="KASSERT_MSG")
    KASSERT_MSG_raw :: proc(expr: bool, message: cstring, file: cstring, line: i32) ---
    @(link_name="KASSERT_DEBUG")
    KASSERT_DEBUG_raw :: proc(expr: bool, file: cstring, line: i32) ---
}

// Wrapper procedures to handle caller location automatically
KASSERT :: proc(expr: bool, loc := #caller_location) {
    KASSERT_raw(expr, cstring(raw_data(loc.file_path)), i32(loc.line))
}

KASSERT_MSG :: proc(expr: bool, message: string, loc := #caller_location) {
    KASSERT_MSG_raw(expr, cstring(raw_data(message)), cstring(raw_data(loc.file_path)), i32(loc.line))
}

KASSERT_DEBUG :: proc(expr: bool, loc := #caller_location) {
    KASSERT_DEBUG_raw(expr, cstring(raw_data(loc.file_path)), i32(loc.line))
}

main :: proc() {
    KFATAL("A test message: FATAL")
    KERROR("A test message: ERROR")
    KWARN("A test message: WARN")
    KINFO("A test message: INFO") 
    KDEBUG("A test message: DEBUG")
    KTRACE("A test message: TRACE")
    
    // Test assertion - now works like the original C macro
    KASSERT(1 == 0)
}