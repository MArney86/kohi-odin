package logger

import "core:fmt"
import "base:runtime"
import "core:c/libc"
import console "../console"

// Enable WARN and INFO logging by default

LOG_WARN_ENABLED :: true
LOG_INFO_ENABLED :: true

when ODIN_DEBUG {
    LOG_DEBUG_ENABLED :: true
    LOG_TRACE_ENABLED :: true
} else {
    LOG_DEBUG_ENABLED :: false
    LOG_TRACE_ENABLED :: false
}

log_level :: enum {
    LOG_LEVEL_FATAL,
    LOG_LEVEL_ERROR,
    LOG_LEVEL_WARN,
    LOG_LEVEL_INFO,
    LOG_LEVEL_DEBUG,
    LOG_LEVEL_TRACE,
}

initialize :: proc() -> bool {
    //TODO: create log file.
    return true
}

shutdown :: proc() {
    //TODO: cleanup logging/write queued entries.
}

// Internal logging function
log_output :: proc(level: log_level, message: string, args: ..any) {
    is_error: b8 = level < log_level.LOG_LEVEL_WARN;

    level_strings := [6]string{
        "[FATAL]: ",
        "[ERROR]: ", 
        "[WARN]:  ", 
        "[INFO]:  ", 
        "[DEBUG]: ", 
        "[TRACE]: ",
    }
    
    // Format the message with arguments
    formatted_message := ""
    if len(args) > 0 {
        formatted_message = fmt.tprintf(message, ..args)
    } else {
        formatted_message = message
    }
    
    // Create the final output message
    out_message := fmt.tprintf("%s%s\n", level_strings[level], formatted_message)
    
    if is_error {
        console.write_error(out_message, cast(u8)level)
    } else {
        console.write(out_message, cast(u8)level)
    }
}

// Logs a fatal level message.
FATAL :: proc(message: string, args: ..any) {
    log_output(log_level.LOG_LEVEL_FATAL, message, ..args)
}

// Logs an error-level message
ERROR :: proc(message: string, args: ..any) {
    log_output(log_level.LOG_LEVEL_ERROR, message, ..args)
}

// Logs a warning-level message
WARN :: proc(message: string, args: ..any) {
    when LOG_WARN_ENABLED {
        log_output(log_level.LOG_LEVEL_WARN, message, ..args)
    } else {
    // Does nothing when LOG_WARN_ENABLED != true
    }
}

// Logs an info-level message
INFO :: proc(message: string, args: ..any) {
    when LOG_INFO_ENABLED {
        log_output(log_level.LOG_LEVEL_INFO, message, ..args)
    } else {
    // Does nothing when LOG_INFO_ENABLED != true
    }
}

// Logs a debug-level message
DEBUG :: proc(message: string, args: ..any) {
    when LOG_DEBUG_ENABLED {
        log_output(log_level.LOG_LEVEL_DEBUG, message, ..args)
    } else {
    // Does nothing when LOG_DEBUG_ENABLED != true
    }
}

// Logs a trace-level message
TRACE :: proc(message: string, args: ..any) {
    when LOG_TRACE_ENABLED {
        log_output(log_level.LOG_LEVEL_TRACE, message, ..args)
    } else {
    // Does nothing when LOG_TRACE_ENABLED != true
    }
}