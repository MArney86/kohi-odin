package asserts

import "base:runtime"
import "base:intrinsics"
import "core:c/libc"
import SC "core:strconv"
import logger "../logger"

// Assertion configuration
KASSERTIONS_ENABLED :: true

// Platform-agnostic debug break using Odin intrinsics
debug_break :: proc() {
    intrinsics.debug_trap()
}

report_assertion_failure :: proc(expression: string, message: string, file: string, line: i32) {
    logger.FATAL("Assertion Failure: %s, message: '%s', in file: %s, line: %d\n", expression, message, file, line)
}

ASSERT :: proc(expr: string, loc := #caller_location) {
    when KASSERTIONS_ENABLED {
        // Parse the expression string into a bool, ignore any parse error
        ok, _ := SC.parse_bool(expr)
        if !ok {
            report_assertion_failure(expr, "", loc.file_path, i32(loc.line))
            debug_break()
        }
    }
    else {
        // does nothing
    }
}

ASSERT_MSG :: proc(expr: string, message: string, loc := #caller_location) {
    when KASSERTIONS_ENABLED {
        ok, _ := SC.parse_bool(expr)
        if !ok {
            report_assertion_failure("expression", message, loc.file_path, i32(loc.line))
            debug_break()
        }
    } else {
        // does nothing
    }
}
ASSERT_DEBUG :: proc(expr: string, loc := #caller_location) {
    when KASSERTIONS_ENABLED && ODIN_DEBUG {
        ok, _ := SC.parse_bool(expr)
            if !ok {
                report_assertion_failure("expression", "", loc.file_path, i32(loc.line))
                debug_break()
            }
    } else {
        // does nothing
    }
}    

