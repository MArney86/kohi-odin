package Kcore

import "base:runtime"
import "base:intrinsics"
import "core:c/libc"
import SC "core:strconv"

// Assertion configuration
KASSERTIONS_ENABLED :: TRUE

// Platform-agnostic debug break using Odin intrinsics
@(private)
debug_break :: proc() {
    intrinsics.debug_trap()
}

@(private)
report_assertion_failure :: proc(expression: string, message: string, file: string, line: i32) {
    log_output(log_level.LOG_LEVEL_FATAL, "Assertion Failure: %s, message: '%s', in file: %s, line: %d\n", expression, message, file, line)
}

when KASSERTIONS_ENABLED {
    KASSERT :: proc(expr: string, loc := #caller_location) {
        // Parse the expression string into a bool, ignore any parse error
        ok, _ := SC.parse_bool(expr)
        if !ok {
            report_assertion_failure(expr, "", loc.file_path, i32(loc.line))
            debug_break()
        }
    }

    KASSERT_MSG :: proc(expr: string, message: string, loc := #caller_location) {
        ok, _ := SC.parse_bool(expr)
        if !ok {
            report_assertion_failure("expression", message, loc.file_path, i32(loc.line))
            debug_break()
        }
    }
    
    when ODIN_DEBUG {
        KASSERT_DEBUG :: proc(expr: string, loc := #caller_location) {
            ok, _ := SC.parse_bool(expr)
            if !ok {
                report_assertion_failure("expression", "", loc.file_path, i32(loc.line))
                debug_break()
            }
        }
    } else {
        KASSERT_DEBUG :: proc(expr: bool, loc := #caller_location) {
            // does nothing
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
}

