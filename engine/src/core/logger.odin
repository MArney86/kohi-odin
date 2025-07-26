package Kcore

import Kdef "../defines"
import "core:fmt"
import "base:runtime"
import "core:c/libc"

// Boolean constants
TRUE :: true
FALSE :: false

// Logging configuration
LOG_WARN_ENABLED  :: TRUE
LOG_INFO_ENABLED  :: TRUE

when ODIN_DEBUG {
    LOG_DEBUG_ENABLED :: TRUE
    LOG_TRACE_ENABLED :: TRUE
} else {
    LOG_DEBUG_ENABLED :: FALSE
    LOG_TRACE_ENABLED :: FALSE
}

log_level :: enum {
    LOG_LEVEL_FATAL = 0,
    LOG_LEVEL_ERROR = 1,
    LOG_LEVEL_WARN  = 2,
    LOG_LEVEL_INFO  = 3,
    LOG_LEVEL_DEBUG = 4,
    LOG_LEVEL_TRACE = 5,
}

initialize_logging :: proc() -> b8 {
    //TODO: create log file.
    return TRUE
}

shutdown_logging :: proc() {
    //TODO: cleanup logging/write queued entries.
}

// Internal logging function
log_output :: proc(level: log_level, message: string, args: ..any) {
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
    fmt.print(out_message)
}

// Logs a fatal level message.
KFATAL :: proc(message: string, args: ..any) {
    log_output(log_level.LOG_LEVEL_FATAL, message, ..args)
}

// Logs an error-level message
KERROR :: proc(message: string, args: ..any) {
    log_output(log_level.LOG_LEVEL_ERROR, message, ..args)
}

// Logs a warning-level message
when LOG_WARN_ENABLED {
    KWARN :: proc(message: string, args: ..any) {
        log_output(log_level.LOG_LEVEL_WARN, message, ..args)
    }
} else {
    KWARN :: proc(message: string, args: ..any) {
        // Does nothing when LOG_WARN_ENABLED != true
    }
}

// Logs an info-level message
when LOG_INFO_ENABLED {
    KINFO :: proc(message: string, args: ..any) {
        log_output(log_level.LOG_LEVEL_INFO, message, ..args)
    }
} else {
    KINFO :: proc(message: string, args: ..any) {
        // Does nothing when LOG_INFO_ENABLED != true
    }
}

// Logs a debug-level message
when LOG_DEBUG_ENABLED {
    KDEBUG :: proc(message: string, args: ..any) {
        log_output(log_level.LOG_LEVEL_DEBUG, message, ..args)
    }
} else {
    KDEBUG :: proc(message: string, args: ..any) {
        // Does nothing when LOG_DEBUG_ENABLED != true
    }
}

// Logs a trace-level message
when LOG_TRACE_ENABLED {
    KTRACE :: proc(message: string, args: ..any) {
        log_output(log_level.LOG_LEVEL_TRACE, message, ..args)
    }
} else {
    KTRACE :: proc(message: string, args: ..any) {
        // Does nothing when LOG_TRACE_ENABLED != true
    }
}