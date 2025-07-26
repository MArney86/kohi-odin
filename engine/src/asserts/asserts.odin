package Asserts

import Kdefines "../defines"
import Kcore "../core"
import "base:runtime"
import "base:intrinsics"

// Assertion configuration
KASSERTIONS_ENABLED :: true

// Platform-specific debug break
when ODIN_OS == .Windows {
    foreign import kernel32 "system:kernel32.lib"
    @(default_calling_convention="stdcall")
    foreign kernel32 {
        DebugBreak :: proc() ---
    }
    debug_break :: proc() {
        DebugBreak()
    }
} else {
    debug_break :: proc() {
        intrinsics.trap()
    }
}

// KAPI export for report_assertion_failure
when Kdefines.KEXPORT {
    @(export, link_name="report_assertion_failure")
    report_assertion_failure_kapi :: proc "c" (expression: cstring, message: cstring, file: cstring, line: i32) {
        context = runtime.default_context()
        report_assertion_failure(string(expression), string(message), string(file), line)
    }
}

report_assertion_failure :: proc(expression: string, message: string, file: string, line: i32) {
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_FATAL, "Assertion Failure: %s, message: '%s', in file: %s, line: %d\n", expression, message, file, line)
}

when KASSERTIONS_ENABLED {
    KASSERT :: proc(expr: bool, loc := #caller_location) {
        if !expr {
            report_assertion_failure("expression", "", loc.file_path, i32(loc.line))
            debug_break()
        }
    }
    
    KASSERT_MSG :: proc(expr: bool, message: string, loc := #caller_location) {
        if !expr {
            report_assertion_failure("expression", message, loc.file_path, i32(loc.line))
            debug_break()
        }
    }
    
    when ODIN_DEBUG {
        KASSERT_DEBUG :: proc(expr: bool, loc := #caller_location) {
            if !expr {
                report_assertion_failure("expression", "", loc.file_path, i32(loc.line))
                debug_break()
            }
        }
    } else {
        KASSERT_DEBUG :: proc(expr: bool, loc := #caller_location) {
            // does nothing
        }
    }
    
    // KAPI exports for assertions
    when Kdefines.KEXPORT {
        @(export, link_name="KASSERT")
        KASSERT_kapi :: proc "c" (expr: bool, file: cstring, line: i32) {
            context = runtime.default_context()
            if !expr {
                report_assertion_failure("expression", "", string(file), line)
                debug_break()
            }
        }
        
        @(export, link_name="KASSERT_MSG")
        KASSERT_MSG_kapi :: proc "c" (expr: bool, message: cstring, file: cstring, line: i32) {
            context = runtime.default_context()
            if !expr {
                report_assertion_failure("expression", string(message), string(file), line)
                debug_break()
            }
        }
        
        when ODIN_DEBUG {
            @(export, link_name="KASSERT_DEBUG")
            KASSERT_DEBUG_kapi :: proc "c" (expr: bool, file: cstring, line: i32) {
                context = runtime.default_context()
                if !expr {
                    report_assertion_failure("expression", "", string(file), line)
                    debug_break()
                }
            }
        } else {
            @(export, link_name="KASSERT_DEBUG")
            KASSERT_DEBUG_kapi :: proc "c" (expr: bool, file: cstring, line: i32) {
                // does nothing
            }
        }
    }
} else {
    KASSERT :: proc(expr: bool, loc := #caller_location) {
        // does nothing
    }
    
    KASSERT_MSG :: proc(expr: bool, message: string, loc := #caller_location) {
        // does nothing
    }
    
    KASSERT_DEBUG :: proc(expr: bool, loc := #caller_location) {
        // does nothing
    }
    
    // KAPI exports for disabled assertions (no-ops)
    when Kdefines.KEXPORT {
        @(export, link_name="KASSERT")
        KASSERT_kapi :: proc "c" (expr: bool, file: cstring, line: i32) {
            // does nothing
        }
        
        @(export, link_name="KASSERT_MSG")
        KASSERT_MSG_kapi :: proc "c" (expr: bool, message: cstring, file: cstring, line: i32) {
            // does nothing
        }
        
        @(export, link_name="KASSERT_DEBUG")
        KASSERT_DEBUG_kapi :: proc "c" (expr: bool, file: cstring, line: i32) {
            // does nothing
        }
    }
}

