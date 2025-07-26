package Kcore

import Kdef "../defines"
//temporary import for KAPI
import "core:fmt"
import "base:runtime"

// Logging configuration
LOG_WARN_ENABLED  :: true
LOG_INFO_ENABLED  :: true

when ODIN_DEBUG {
    LOG_DEBUG_ENABLED :: true
    LOG_TRACE_ENABLED :: true
} else {
    LOG_DEBUG_ENABLED :: false
    LOG_TRACE_ENABLED :: false
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
    return Kdef.TRUE
}

shutdown_logging :: proc() {
    //TODO: cleanup logging/write queued entries.
}

log_output :: proc(level: log_level, message: string, args: ..any) {
    level_strings := [6]string{
        "[FATAL]: ",
        "[ERROR]: ", 
        "[WARN]:  ", 
        "[INFO]:  ", 
        "[DEBUG]: ", 
        "[TRACE]: ",
    }
    
    //is_error := level < log_level.LOG_LEVEL_WARN
    
    // Format the message with arguments
    formatted_message := ""
    if len(args) > 0 {
        formatted_message = fmt.tprintf(message, ..args)
    } else {
        formatted_message = message
    }
    
    // Create the final output message
    out_message := fmt.tprintf("%s%s\n", level_strings[level], formatted_message)
    
    //TODO: platform-specific output
    fmt.print(out_message)
}

// KAPI exported version of log_output
when Kdef.KEXPORT {
    @(export, link_name="log_output")
    log_output_kapi :: proc "c" (level: i32, message: cstring) {
        context = runtime.default_context()
        log_output(log_level(level), string(message))
    }
}

// Logs a fatal level message.
when Kdef.KEXPORT {
    @(export, link_name="KFATAL")
    KFATAL_kapi :: proc "c" (message: cstring) {
        context = runtime.default_context()
        log_output(log_level.LOG_LEVEL_FATAL, string(message))
    }
}

// Logs an error-level message
when Kdef.KEXPORT {
    @(export, link_name="KERROR")
    KERROR_kapi :: proc "c" (message: cstring) {
        context = runtime.default_context()
        log_output(log_level.LOG_LEVEL_ERROR, string(message))
    }
}

when LOG_WARN_ENABLED {
    // Logs a warning-level message
    when Kdef.KEXPORT {
        @(export, link_name="KWARN")
        KWARN_kapi :: proc "c" (message: cstring) {
            context = runtime.default_context()
            log_output(log_level.LOG_LEVEL_WARN, string(message))
        }
    }
} else {
    // Does nothing when LOG_WARN_ENABLED != true
    when Kdef.KEXPORT {
        @(export, link_name="KWARN")
        KWARN_kapi :: proc "c" (message: cstring) {
            // No-op
        }
    }
}

when LOG_INFO_ENABLED {
    // Logs an info-level message
    when Kdef.KEXPORT {
        @(export, link_name="KINFO")
        KINFO_kapi :: proc "c" (message: cstring) {
            context = runtime.default_context()
            log_output(log_level.LOG_LEVEL_INFO, string(message))
        }
    }
} else {
    // Does nothing when LOG_INFO_ENABLED != true
    when Kdef.KEXPORT {
        @(export, link_name="KINFO")
        KINFO_kapi :: proc "c" (message: cstring) {
            // No-op
        }
    }
}

when LOG_DEBUG_ENABLED {
    // Logs a debug-level message
    when Kdef.KEXPORT {
        @(export, link_name="KDEBUG")
        KDEBUG_kapi :: proc "c" (message: cstring) {
            context = runtime.default_context()
            log_output(log_level.LOG_LEVEL_DEBUG, string(message))
        }
    }
} else {
    // Does nothing when LOG_DEBUG_ENABLED != true
    when Kdef.KEXPORT {
        @(export, link_name="KDEBUG")
        KDEBUG_kapi :: proc "c" (message: cstring) {
            // No-op
        }
    }
}

when LOG_TRACE_ENABLED {
    // Logs a trace-level message
    when Kdef.KEXPORT {
        @(export, link_name="KTRACE")
        KTRACE_kapi :: proc "c" (message: cstring) {
            context = runtime.default_context()
            log_output(log_level.LOG_LEVEL_TRACE, string(message))
        }
    }
} else {
    // Does nothing when LOG_TRACE_ENABLED != true
    when Kdef.KEXPORT {
        @(export, link_name="KTRACE")
        KTRACE_kapi :: proc "c" (message: cstring) {
            // No-op
        }
    }
}