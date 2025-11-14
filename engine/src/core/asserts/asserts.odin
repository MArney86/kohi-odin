package asserts

import "base:runtime"
import "base:intrinsics"
import "core:c/libc"
import SC "core:strconv"
import logger "../logger"


// Platform-agnostic debug break using Odin intrinsics
debug_break :: proc() {
    intrinsics.debug_trap()
}

report_assertion_failure :: proc(expression: string, message: string, file: string, line: i32) {
    logger.FATAL("Assertion Failure: %s, message: '%s', in file: %s, line: %d\n", expression, message, file, line)
}

ASSERT :: proc(cond: bool, expr: string = #caller_expression(cond),  loc := #caller_location) {
    when !ODIN_DISABLE_ASSERT {
        // Parse the expression string into a bool, ignore any parse error
        if !cond {
            report_assertion_failure(expr, "", loc.file_path, i32(loc.line))
            debug_break()
        }
    }
    else {
        // does nothing
    }
}

ASSERT_MSG :: proc(cond: bool, message: string, expr: string = #caller_expression(cond), loc := #caller_location) {
    when !ODIN_DISABLE_ASSERT {
        if !cond {
            report_assertion_failure(expr, message, loc.file_path, i32(loc.line))
            debug_break()
        }
    } else {
        // does nothing
    }
}

ASSERT_DEBUG :: proc(cond: bool, expr: string = #caller_expression(cond), loc := #caller_location) {
    when !ODIN_DISABLE_ASSERT && ODIN_DEBUG {
        if !cond {
            report_assertion_failure(expr, "", loc.file_path, i32(loc.line))
            debug_break()
            }
    } else {
        // does nothing
    }
}    

