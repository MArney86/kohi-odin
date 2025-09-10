package Testbed

import types "../../engine/src/types"
import strings "core:strings"

// Platform-specific import for the engine library
when ODIN_OS == .Windows {
    foreign import Engine "../../bin/engine.lib"
} else when ODIN_OS == .Linux {
    foreign import Engine "../../bin/libengine.so"
} else {
    #panic("Unsupported platform")
}

foreign Engine {
    /* Application Layer */
    KAPI_application_create :: proc "c" (game_inst: rawptr) -> b8 ---
    KAPI_application_run :: proc "c" () -> b8 ---

    /* Memory Management */
    KAPI_allocate :: proc "c" (size: u64, tag: types.memory_tag) -> rawptr ---
    KAPI_free :: proc "c" (block: rawptr, size: u64, tag: types.memory_tag) ---
    KAPI_initialize_memory :: proc "c" () ---
    KAPI_shutdown_memory :: proc "c" () ---

    /* Logger functions */
    KAPI_FATAL :: proc "c" (msg: cstring) ---
    KAPI_INFO :: proc "c" (msg: cstring) ---
    KAPI_DEBUG :: proc "c" (msg: cstring) ---
}

application_create :: proc(game_inst: ^types.game) -> b8 {
    return KAPI_application_create(cast(rawptr)game_inst)
}

application_run :: proc() -> b8 {
    return KAPI_application_run()
}

initialize_memory :: proc() {
    KAPI_initialize_memory()
}

shutdown_memory :: proc() {
    KAPI_shutdown_memory()
}

Kallocate :: proc(size: u64, tag: types.memory_tag) -> rawptr {
    return KAPI_allocate(size, tag)
}

Kfree :: proc(block: rawptr, size: u64, tag: types.memory_tag) {
    KAPI_free(block, size, tag)
}

KDEBUG :: proc(msg: string) {
    conv_msg:= strings.clone_to_cstring(msg,context.temp_allocator)
    KAPI_DEBUG(conv_msg)
}

KINFO :: proc(msg: string) {
    conv_msg:= strings.clone_to_cstring(msg,context.temp_allocator)
    KAPI_INFO(conv_msg)
}

KFATAL :: proc(msg: string) {
    conv_msg:= strings.clone_to_cstring(msg,context.temp_allocator)
    KAPI_FATAL(conv_msg)
}