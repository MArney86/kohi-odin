package Engine

import runtime "base:runtime"
import strings "core:strings"
import types "./types"

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
    KAPI_ASSERT :: proc "c" (expr: cstring, loc:= #caller_location) {
        context = runtime.default_context()
        Kcore.KASSERT(string(expr), loc)
    }

    @(export)
    KAPI_ASSERT_MSG :: proc "c" (expr: cstring, message: cstring, loc:= #caller_location) {
        context = runtime.default_context()
        Kcore.KASSERT_MSG(string(expr), string(message), loc)
    }

    @(export)
    KAPI_ASSERT_DEBUG :: proc "c" (expr: cstring, loc:= #caller_location) {
        context = runtime.default_context()
        Kcore.KASSERT_DEBUG(string(expr), loc)
    }
}

// KAPI exports for logging
@(export)
KAPI_FATAL :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_FATAL, string(msg))
}

@(export)
KAPI_ERROR :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_ERROR, string(msg))
}

@(export)
KAPI_WARN :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_WARN, string(msg))
}

@(export)
KAPI_INFO :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_INFO, string(msg))
}

@(export)
KAPI_DEBUG :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_DEBUG, string(msg))
}

@(export)
KAPI_TRACE :: proc "c" (msg: cstring) {
    context = runtime.default_context()
    Kcore.log_output(Kcore.log_level.LOG_LEVEL_TRACE, string(msg))
}

// Application Layer exports
@(export)
KAPI_application_create :: proc "c" (game_inst: rawptr) -> b8 {
    context = runtime.default_context()
    game := cast(^Types.game)game_inst
    return Kcore.application_create(game)
}

@(export)
KAPI_application_run :: proc "c" () -> b8 {
    context = runtime.default_context()
    return Kcore.application_run()
}

// Memory Management 
@(export)
KAPI_initialize_memory :: proc "c" () {
    context = runtime.default_context()
    Kcore.initialize_memory()
}

@(export)
KAPI_shutdown_memory :: proc "c" () {
    context = runtime.default_context()
    Kcore.shutdown_memory()
}

@(export)
KAPI_allocate :: proc "c" (size: u64, tag: types.memory_tag) -> rawptr {
    context = runtime.default_context()
    return Kcore.Kallocate(size, tag)
}

@(export)
KAPI_free :: proc "c" (block: rawptr, size: u64, tag: types.memory_tag) {
    context = runtime.default_context()
    Kcore.Kfree(block, size, tag)
}

@(export)
KAPI_zero_memory :: proc "c" (block: rawptr, size: u64) -> rawptr {
    context = runtime.default_context()
    return Kcore.Kzero_memory(block, size)
}

@(export)
KAPI_copy_memory :: proc "c" (dest: rawptr, src: rawptr, size: u64) -> rawptr {
    context = runtime.default_context()
    return Kcore.Kcopy_memory(dest, src, size)
}

@(export)
KAPI_set_memory :: proc "c" (dest: rawptr, value: i32, size: u64) -> rawptr {
    context = runtime.default_context()
    return Kcore.Kset_memory(dest, value, size)
}

@(export)
KAPI_get_memory_usage_str :: proc "c" () -> cstring {
    context = runtime.default_context()
    mem_str, err:= strings.clone_to_cstring(Kcore.get_memory_usage_str())
    if err != nil {
        return cstring("Error retrieving memory usage string")
    }
    return mem_str
}