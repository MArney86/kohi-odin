package testbed

import types "../../engine/src/types"
import runtime "base:runtime"
import fmt "core:fmt"
import dynlib "core:dynlib"
import helpers "../../libs/helpers"

KASSERT : proc(string, runtime.Source_Code_Location)
KASSERT_MSG : proc(string, string, runtime.Source_Code_Location)
KASSERT_DEBUG : proc(string, runtime.Source_Code_Location)
KFATAL : proc(string)
KERROR : proc(string)
KWARN : proc(string)
KINFO : proc(string)
KDEBUG : proc(string)
KTRACE : proc(string)

application_create : proc(rawptr) -> b8
application_run : proc() -> b8
initialize_memory : proc()
shutdown_memory : proc()
Kallocate : proc(u64, types.memory_tag) -> rawptr
Kfree : proc(rawptr, u64, types.memory_tag)
Kzero_memory : proc(rawptr, u64) -> rawptr
Kcopy_memory : proc(rawptr, rawptr, u64) -> rawptr
Kset_memory : proc(rawptr, i32, u64) -> rawptr
get_memory_usage_str : proc() -> string

// Version variables (these should remain as pointers)
KAPI_VERSION : u8
KAPI_SUBVERSION : u8
KAPI_REVISION : u16
KAPI_lib : dynlib.Library

load_kohi_api :: proc() -> bool {
    dll_name := fmt.tprintf("libengine-core.%v", dynlib.LIBRARY_FILE_EXTENSION)
    
    lib, lib_ok := dynlib.load_library(dll_name)
    if !lib_ok {
        fmt.eprintf("Failed to load library: %s\n", dll_name)
        return false
    }

    // Load function pointers - remove the ^proc cast
    KASSERT = cast(proc(string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT") or_else nil)
    KASSERT_MSG = cast(proc(string, string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT_MSG") or_else nil)
    KASSERT_DEBUG = cast(proc(string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT_DEBUG") or_else nil)
    KFATAL = cast(proc(string))(dynlib.symbol_address(lib, "KFATAL") or_else nil)
    KERROR = cast(proc(string))(dynlib.symbol_address(lib, "KERROR") or_else nil)
    KWARN = cast(proc(string))(dynlib.symbol_address(lib, "KWARN") or_else nil)
    KINFO = cast(proc(string))(dynlib.symbol_address(lib, "KINFO") or_else nil)
    KDEBUG = cast(proc(string))(dynlib.symbol_address(lib, "KDEBUG") or_else nil)
    KTRACE = cast(proc(string))(dynlib.symbol_address(lib, "KTRACE") or_else nil)
    
    application_create = cast(proc(rawptr) -> b8)(dynlib.symbol_address(lib, "application_create") or_else nil)
    application_run = cast(proc() -> b8)(dynlib.symbol_address(lib, "application_run") or_else nil)
    initialize_memory = cast(proc())(dynlib.symbol_address(lib, "initialize_memory") or_else nil)
    shutdown_memory = cast(proc())(dynlib.symbol_address(lib, "shutdown_memory") or_else nil)
    Kallocate = cast(proc(u64, types.memory_tag) -> rawptr)(dynlib.symbol_address(lib, "Kallocate") or_else nil)
    Kfree = cast(proc(rawptr, u64, types.memory_tag))(dynlib.symbol_address(lib, "Kfree") or_else nil)
    Kzero_memory = cast(proc(rawptr, u64) -> rawptr)(dynlib.symbol_address(lib, "Kzero_memory") or_else nil)
    Kcopy_memory = cast(proc(rawptr, rawptr, u64) -> rawptr)(dynlib.symbol_address(lib, "Kcopy_memory") or_else nil)
    Kset_memory = cast(proc(rawptr, i32, u64) -> rawptr)(dynlib.symbol_address(lib, "Kset_memory") or_else nil)
    get_memory_usage_str = cast(proc() -> string)(dynlib.symbol_address(lib, "get_memory_usage_str") or_else nil)
    
    // Load version variables
    temp8 := cast(^u8)(dynlib.symbol_address(lib, "KAPI_VERSION") or_else nil)
    if temp8 != nil {
        KAPI_VERSION = temp8^
    } else {
        dynlib.unload_library(lib)
        fmt.eprintf("Error Loading libengine-core, could not load KAPI_VERSION symbol!\n")
        return false
    }
    KAPI_VERSION = temp8^
    temp8 = cast(^u8)(dynlib.symbol_address(lib, "KAPI_SUBVERSION") or_else nil)
    if temp8 != nil {
        KAPI_SUBVERSION = temp8^
    } else {
        dynlib.unload_library(lib)
        fmt.eprintf("Error Loading libengine-core, could not load KAPI_SUBVERSION symbol!\n")
        return false
    }
    temp16 := cast(^u16)(dynlib.symbol_address(lib, "KAPI_REVISION") or_else nil)
    if temp16 != nil {
        KAPI_REVISION = temp16^
    } else {
        dynlib.unload_library(lib)
        fmt.eprintf("Error Loading libengine-core, could not load KAPI_REVISION symbol!\n")
        return false
    }

    // Fix version check (dereference the pointers)
   if KAPI_VERSION == 0 && KAPI_SUBVERSION == 0 && KAPI_REVISION == 0 {
        dynlib.unload_library(lib)
        fmt.eprintf("Error Loading libengine-core, version information is all zero!\n")
        return false
    }

    // Check if functions loaded successfully
    if Kallocate == nil || Kfree == nil || Kcopy_memory == nil ||
       KDEBUG == nil || KINFO == nil || KFATAL == nil ||
       application_create == nil || application_run == nil ||
       initialize_memory == nil || shutdown_memory == nil ||
       KASSERT == nil || KASSERT_MSG == nil || KASSERT_DEBUG == nil ||
       KERROR == nil || KWARN == nil || KTRACE == nil ||
       Kzero_memory == nil || Kset_memory == nil || get_memory_usage_str == nil {
        dynlib.unload_library(lib)
        fmt.eprintf("One or more required function pointers are null in the loaded library %s\n", dll_name)
        return false
    }

    KAPI_lib = lib
    return true
}

unload_kohi_api :: proc() {
    if KAPI_lib != nil {
        dynlib.unload_library(KAPI_lib)
    }
}