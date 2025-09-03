package Kcore

import "core:fmt"
import "base:runtime"
import "core:c/libc"

// Enable WARN and INFO logging by default
@(private)
LOG_WARN_ENABLED :: TRUE
@(private)
LOG_INFO_ENABLED :: TRUE

when ODIN_DEBUG {
    @(private)
    LOG_DEBUG_ENABLED :: TRUE
    @(private)
    LOG_TRACE_ENABLED :: TRUE
} else {
    @(private)
    LOG_DEBUG_ENABLED :: FALSE
    @(private)
    LOG_TRACE_ENABLED :: FALSE
}

log_level :: enum {
    LOG_LEVEL_FATAL,
    LOG_LEVEL_ERROR,
    LOG_LEVEL_WARN,
    LOG_LEVEL_INFO,
    LOG_LEVEL_DEBUG,
    LOG_LEVEL_TRACE,
}

@(private)
initialize_logging :: proc() -> b8 {
    //TODO: create log file.
    return TRUE
}

@(private)
shutdown_logging :: proc() {
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
        platform_console_write_error(out_message, cast(u8)level)
    } else {
        platform_console_write(out_message, cast(u8)level)
    }
}

// Logs a fatal level message.
@(private)
KFATAL :: proc(message: string, args: ..any) {
    log_output(log_level.LOG_LEVEL_FATAL, message, ..args)
}

// Logs an error-level message
@(private)
KERROR :: proc(message: string, args: ..any) {
    log_output(log_level.LOG_LEVEL_ERROR, message, ..args)
}

// Logs a warning-level message
when LOG_WARN_ENABLED {
    @(private)
    KWARN :: proc(message: string, args: ..any) {
        log_output(log_level.LOG_LEVEL_WARN, message, ..args)
    }
} else {
    @(private)
    KWARN :: proc(message: string, args: ..any) {
        // Does nothing when LOG_WARN_ENABLED != true
    }
}

// Logs an info-level message
when LOG_INFO_ENABLED {
    @(private)
    KINFO :: proc(message: string, args: ..any) {
        log_output(log_level.LOG_LEVEL_INFO, message, ..args)
    }
} else {
    @(private)
    KINFO :: proc(message: string, args: ..any) {
        // Does nothing when LOG_INFO_ENABLED != true
    }
}

// Logs a debug-level message
when LOG_DEBUG_ENABLED {
    @(private)
    KDEBUG :: proc(message: string, args: ..any) {
        log_output(log_level.LOG_LEVEL_DEBUG, message, ..args)
    }
} else {
    @(private)
    KDEBUG :: proc(message: string, args: ..any) {
        // Does nothing when LOG_DEBUG_ENABLED != true
    }
}

// Logs a trace-level message
when LOG_TRACE_ENABLED {
    @(private)
    KTRACE :: proc(message: string, args: ..any) {
        log_output(log_level.LOG_LEVEL_TRACE, message, ..args)
    }
} else {
    @(private)
    KTRACE :: proc(message: string, args: ..any) {
        // Does nothing when LOG_TRACE_ENABLED != true
    }
}