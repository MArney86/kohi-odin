package Engine

import runtime "base:runtime"

// Boolean types
INT :: b32
CHAR :: b8

// Boolean constants
TRUE :: true
FALSE :: false

import Kcore "./core"
import Types "./types"

// Exports for externally accessible game engine functionalities

//Assertions - accessible when KASSERTIONS_ENABLED is true
when Kcore.KASSERTIONS_ENABLED {
    @(export)
    KASSERT :: proc "c" (expr: cstring, loc:= #caller_location) {
        context = runtime.default_context()
        Kcore.KASSERT(string(expr), loc)
    }

    @(export)
    KASSERT_MSG :: proc "c" (expr: cstring, message: cstring, loc:= #caller_location) {
        context = runtime.default_context()
        Kcore.KASSERT_MSG(string(expr), string(message), loc)
    }

    @(export)
    KASSERT_DEBUG :: proc "c" (expr: cstring, loc:= #caller_location) {
        context = runtime.default_context()
        Kcore.KASSERT_DEBUG(string(expr), loc)
    }
}

// KAPI exports for logging
@(export)
KFATAL :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_FATAL, string(msg))
}

@(export)
KERROR :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_ERROR, string(msg))
}

@(export)
KWARN :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_WARN, string(msg))
}

@(export)
KINFO :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_INFO, string(msg))
}

@(export)
KDEBUG :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_DEBUG, string(msg))
}

@(export)
KTRACE :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_TRACE, string(msg))
}

// Application Layer exports
@(export)
application_create :: proc "c" (game_inst: rawptr) -> b8 {
    context = runtime.default_context()
    game := cast(^Types.game)game_inst
    return Kcore.application_create(game)
}

@(export)
application_run :: proc "c" () -> b8 {
    context = runtime.default_context()
    return Kcore.application_run()
}

// Temporary platform memory allocation functions
@(export)
platform_allocate :: proc "c" (size: u64, aligned: b8) -> rawptr {
    context = runtime.default_context()
    return Kcore.platform_allocate(size, aligned)
}

@(export)
platform_free :: proc "c" (block: rawptr, aligned: b8) {
    context = runtime.default_context()
    Kcore.platform_free(block, aligned)
} 