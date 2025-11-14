#+private
package testbed

import types "../../engine/src/types"
import runtime "base:runtime"
import fmt "core:fmt"
import dynlib "core:dynlib"
import helpers "../../libs/helpers"

KAPI_t :: struct {
    is_initialized : bool,
    core: struct {
        asserts : struct {
            // asserts
            ASSERT : proc(string, runtime.Source_Code_Location),
            ASSERT_MSG : proc(string, string, runtime.Source_Code_Location),
            ASSERT_DEBUG : proc(string, runtime.Source_Code_Location),
        },

        log : struct{
            // logging
            FATAL : proc(string, ..any),
            ERROR : proc(string, ..any),
            WARN : proc(string, ..any),
            INFO : proc(string, ..any),
            DEBUG : proc(string, ..any),
            TRACE : proc(string, ..any),
        },
        app : struct {
            // application
            application_create : proc(rawptr) -> b8,
            application_run : proc() -> b8,
        },
        mem : struct {
            // memory management
            initialize_memory : proc(),
            shutdown_memory : proc(),
            allocate : proc(u64, types.memory_tag) -> rawptr,
            free : proc(rawptr, u64, types.memory_tag),
            zero_memory : proc(rawptr, u64) -> rawptr,
            copy_memory : proc(rawptr, rawptr, u64) -> rawptr,
            set_memory : proc(rawptr, i32, u64) -> rawptr,
            get_memory_usage_str : proc() -> string,
        },
        str : struct {
            // strings
            string_length : proc(string) -> u64,
            string_duplicate : proc(string) -> string,
        },
        event : struct {
            // event system
            event_register : proc(u16, rawptr, types.PFN_on_event) -> b8,
            event_unregister : proc(u16, rawptr, types.PFN_on_event) -> b8,
            event_fire : proc(u16, rawptr, types.event_context) -> b8,
        },
        input : struct {
            // input system
            is_key_down : proc(types.keys) -> b8,
            is_key_up : proc(types.keys) -> b8,
            was_key_down : proc(types.keys) -> b8,
            was_key_up : proc(types.keys) -> b8,
            is_button_down : proc(types.buttons) -> b8,
            is_button_up : proc(types.buttons) -> b8,
            was_button_down : proc(types.buttons) -> b8,
            was_button_up : proc(types.buttons) -> b8,
            get_mouse_position : proc(^i32, ^i32),
            get_previous_mouse_position : proc(^i32, ^i32),
        },
    },
    containers: struct {
        // dynamic array
        darray : struct {
            make : proc(typeid) -> rawptr,
            delete : proc(rawptr, typeid),
            reserve : proc(rawptr, typeid, u64) -> bool,
            resize : proc(rawptr, typeid, u64),
            push : proc(rawptr, typeid, rawptr) -> bool,
            pop : proc(rawptr, typeid) -> rawptr,
            insert_at : proc(rawptr, typeid, u64, rawptr) -> bool,
            pop_at : proc(rawptr, typeid, u64) -> rawptr,
            clear : proc(rawptr, typeid),
            set_len : proc(rawptr, typeid, u64),
        }
    },

    // Version variables
    API_VERSION : u64,
    ENGINE_VERSION : u64,
    
    // Library handle
    KAPI_lib : dynlib.Library,
}

KAPI : KAPI_t

load_kohi_api :: proc() -> bool {
    dll_name := fmt.tprintf("kohi_engine.%v", dynlib.LIBRARY_FILE_EXTENSION)
    
    lib, lib_ok := dynlib.load_library(dll_name)
    if !lib_ok {
        fmt.eprintf("Failed to load library: %s\n", dll_name)
        return false
    }
    KAPI.is_initialized = false

    // Load function pointers
    KAPI.core.asserts.ASSERT = cast(proc(string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT") or_else nil)
    KAPI.core.asserts.ASSERT_MSG = cast(proc(string, string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT_MSG") or_else nil)
    KAPI.core.asserts.ASSERT_DEBUG = cast(proc(string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT_DEBUG") or_else nil)

    KAPI.core.log.FATAL = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KFATAL") or_else nil)
    KAPI.core.log.ERROR = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KERROR") or_else nil)
    KAPI.core.log.WARN = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KWARN") or_else nil)
    KAPI.core.log.INFO = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KINFO") or_else nil)
    KAPI.core.log.DEBUG = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KDEBUG") or_else nil)
    KAPI.core.log.TRACE = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KTRACE") or_else nil)
    
    KAPI.core.app.application_create = cast(proc(rawptr) -> b8)(dynlib.symbol_address(lib, "Kapplication_create") or_else nil)
    KAPI.core.app.application_run = cast(proc() -> b8)(dynlib.symbol_address(lib, "Kapplication_run") or_else nil)

    KAPI.core.mem.initialize_memory = cast(proc())(dynlib.symbol_address(lib, "Kinitialize_memory") or_else nil)
    KAPI.core.mem.shutdown_memory = cast(proc())(dynlib.symbol_address(lib, "Kshutdown_memory") or_else nil)
    KAPI.core.mem.allocate = cast(proc(u64, types.memory_tag) -> rawptr)(dynlib.symbol_address(lib, "Kallocate") or_else nil)
    KAPI.core.mem.free = cast(proc(rawptr, u64, types.memory_tag))(dynlib.symbol_address(lib, "Kfree") or_else nil)
    KAPI.core.mem.zero_memory = cast(proc(rawptr, u64) -> rawptr)(dynlib.symbol_address(lib, "Kzero_memory") or_else nil)
    KAPI.core.mem.copy_memory = cast(proc(rawptr, rawptr, u64) -> rawptr)(dynlib.symbol_address(lib, "Kcopy_memory") or_else nil)
    KAPI.core.mem.set_memory = cast(proc(rawptr, i32, u64) -> rawptr)(dynlib.symbol_address(lib, "Kset_memory") or_else nil)
    KAPI.core.mem.get_memory_usage_str = cast(proc() -> string)(dynlib.symbol_address(lib, "Kget_memory_usage_str") or_else nil)

    KAPI.core.str.string_length = cast(proc(string) -> u64)(dynlib.symbol_address(lib, "Kstring_length") or_else nil)
    KAPI.core.str.string_duplicate = cast(proc(string) -> string)(dynlib.symbol_address(lib, "Kstring_duplicate") or_else nil)

    KAPI.core.event.event_register = cast(proc(u16, rawptr, types.PFN_on_event) -> b8)(dynlib.symbol_address(lib, "Kevent_register") or_else nil)
    KAPI.core.event.event_unregister = cast(proc(u16, rawptr, types.PFN_on_event) -> b8)(dynlib.symbol_address(lib, "Kevent_unregister") or_else nil)
    KAPI.core.event.event_fire = cast(proc(u16, rawptr, types.event_context) -> b8)(dynlib.symbol_address(lib, "Kevent_fire") or_else nil)

    KAPI.core.input.is_key_down = cast(proc(types.keys) -> b8)(dynlib.symbol_address(lib, "Kis_key_down") or_else nil)
    KAPI.core.input.is_key_up = cast(proc(types.keys) -> b8)(dynlib.symbol_address(lib, "Kis_key_up") or_else nil)
    KAPI.core.input.was_key_down = cast(proc(types.keys) -> b8)(dynlib.symbol_address(lib, "Kwas_key_down") or_else nil)
    KAPI.core.input.was_key_up = cast(proc(types.keys) -> b8)(dynlib.symbol_address(lib, "Kwas_key_up") or_else nil)
    KAPI.core.input.is_button_down = cast(proc(types.buttons) -> b8)(dynlib.symbol_address(lib, "Kis_button_down") or_else nil)
    KAPI.core.input.is_button_up = cast(proc(types.buttons) -> b8)(dynlib.symbol_address(lib, "Kis_button_up") or_else nil)
    KAPI.core.input.was_button_down = cast(proc(types.buttons) -> b8)(dynlib.symbol_address(lib, "Kwas_button_down") or_else nil)
    KAPI.core.input.was_button_up = cast(proc(types.buttons) -> b8)(dynlib.symbol_address(lib, "Kwas_button_up") or_else nil)
    KAPI.core.input.get_mouse_position = cast(proc(^i32, ^i32))(dynlib.symbol_address(lib, "Kget_mouse_position") or_else nil)
    KAPI.core.input.get_previous_mouse_position = cast(proc(^i32, ^i32))(dynlib.symbol_address(lib, "Kget_previous_mouse_position") or_else nil)

    KAPI.containers.darray.make = cast(proc(typeid) -> rawptr)(dynlib.symbol_address(lib, "DArray_make") or_else nil)
    KAPI.containers.darray.delete = cast(proc(rawptr, typeid))(dynlib.symbol_address(lib, "DArray_delete") or_else nil)
    KAPI.containers.darray.resize = cast(proc(rawptr, typeid, u64) -> bool)(dynlib.symbol_address(lib, "DArray_resize") or_else nil)
    KAPI.containers.darray.reserve = cast(proc(rawptr, typeid, u64) -> bool)(dynlib.symbol_address(lib, "DArray_reserve") or_else nil)
    KAPI.containers.darray.push = cast(proc(rawptr, typeid, rawptr) -> bool)(dynlib.symbol_address(lib, "DArray_push") or_else nil)
    KAPI.containers.darray.pop = cast(proc(rawptr, typeid) -> rawptr)(dynlib.symbol_address(lib, "DArray_pop") or_else nil)
    KAPI.containers.darray.insert_at = cast(proc(rawptr, typeid, u64, rawptr) -> bool)(dynlib.symbol_address(lib, "DArray_insert_at") or_else nil)
    KAPI.containers.darray.pop_at = cast(proc(rawptr, typeid, u64) -> rawptr)(dynlib.symbol_address(lib, "DArray_pop_at") or_else nil)
    KAPI.containers.darray.clear = cast(proc(rawptr, typeid))(dynlib.symbol_address(lib, "DArray_clear") or_else nil)
    KAPI.containers.darray.set_len = cast(proc(rawptr, typeid, u64))(dynlib.symbol_address(lib, "DArray_set_len") or_else nil)
    // Load version variables
    temp_ver := cast(^u64)(dynlib.symbol_address(lib, "KAPI_VERSION") or_else nil)
    if temp_ver != nil {
        KAPI.KAPI_VERSION = temp_ver^
    } else {
        dynlib.unload_library(lib)
        fmt.eprintf("Error Loading kohi_engine, could not load KAPI_VERSION symbol!\n")
        return false
    }

    temp_ver = cast(^u64)(dynlib.symbol_address(lib, "KENGINE_VERSION") or_else nil)
    if temp_ver != nil {
        KAPI.KENGINE_VERSION = temp_ver^
    } else {
        dynlib.unload_library(lib)
        fmt.eprintf("Error Loading kohi_engine, could not load KENGINE_VERSION symbol!\n")
        return false
    }

    // Check if functions loaded successfully
    if KAPI.core.mem.allocate == nil || 
       KAPI.core.mem.free == nil || 
       KAPI.core.mem.copy_memory == nil ||
       KAPI.core.log.DEBUG == nil || 
       KAPI.core.log.INFO == nil || 
       KAPI.core.log.FATAL == nil ||
       KAPI.core.app.application_create == nil || 
       KAPI.core.app.application_run == nil ||
       KAPI.core.mem.initialize_memory == nil || 
       KAPI.core.mem.shutdown_memory == nil ||
       KAPI.core.asserts.ASSERTKASSERT == nil || 
       KAPI.core.asserts.ASSERT_MSG == nil || 
       KAPI.core.asserts.ASSERT_DEBUG == nil ||
       KAPI.core.log.ERROR == nil || 
       KAPI.core.log.WARN == nil || 
       KAPI.core.log.TRACE == nil ||
       KAPI.core.mem.zero_memory == nil || 
       KAPI.core.mem.set_memory == nil ||
       KAPI.core.mem.get_memory_usage_str == nil ||
       KAPI.core.str.length == nil || 
       KAPI.core.str.duplicate == nil ||
       KAPI.core.event.register == nil || 
       KAPI.core.event.unregister == nil ||
       KAPI.core.event.fire == nil ||
       KAPI.core.input.is_key_down == nil ||
       KAPI.core.input.is_key_up == nil ||
       KAPI.core.input.was_key_down == nil ||
       KAPI.core.input.was_key_up == nil ||
       KAPI.core.input.is_button_down == nil ||
       KAPI.core.input.is_button_up == nil ||
       KAPI.core.input.was_button_down == nil ||
       KAPI.core.input.was_button_up == nil ||
       KAPI.core.input.get_mouse_position == nil ||
       KAPI.core.input.get_previous_mouse_position == nil ||
       KAPI.containers.darray.make == nil ||
       KAPI.containers.darray.delete == nil ||
       KAPI.containers.darray.reserve == nil ||
       KAPI.containers.darray.resize == nil ||
       KAPI.containers.darray.push == nil ||
       KAPI.containers.darray.pop == nil ||
       KAPI.containers.darray.insert_at == nil ||
       KAPI.containers.darray.pop_at == nil ||
       KAPI.containers.darray.clear == nil ||
       KAPI.Kdarray_set_len == nil ||
       KAPI.KAPI_VERSION == 0 ||
       KAPI.KENGINE_VERSION == 0 {
        dynlib.unload_library(lib)
        fmt.eprintf("One or more required function pointers are null in the loaded library %s\n", dll_name)
        nil_list : [46]string
        index: = 0
        if KAPI.core.mem.allocate == nil {
           nil_list[index] = "Kallocate"
           index += 1
        }
        if KAPI.core.mem.free == nil {
            nil_list[index] = "Kfree"
            index += 1
        }
        if KAPI.core.mem.copy_memory == nil {
            nil_list[index] = "Kcopy_memory"
            index += 1
        }
        if KAPI.core.mem.zero_memory == nil {
            nil_list[index] = "Kzero_memory"
            index += 1
        }
        if KAPI.core.mem.set_memory == nil {
            nil_list[index] = "Kset_memory"
            index += 1
        }
        if KAPI.core.mem.get_memory_usage_str == nil {
            nil_list[index] = "Kget_memory_usage_str"
            index += 1
        }
        if KAPI.core.log.DEBUG == nil {
            nil_list[index] = "KDEBUG"
            index += 1
        }
        if KAPI.core.log.INFO == nil {
            nil_list[index] = "KINFO"
            index += 1
        }
        if KAPI.core.log.FATAL == nil {
            nil_list[index] = "KFATAL"
            index += 1
        }
        if KAPI.core.log.ERROR == nil {
            nil_list[index] = "KERROR"
            index += 1
        }
        if KAPI.core.log.WARN == nil {
            nil_list[index] = "KWARN"
            index += 1
        }
        if KAPI.core.log.TRACE == nil {
            nil_list[index] = "KTRACE"
            index += 1
        }
        if KAPI.core.asserts.ASSERT == nil {
            nil_list[index] = "KASSERT"
            index += 1
        }
        if KAPI.core.asserts.ASSERT_MSG == nil {
            nil_list[index] = "KASSERT_MSG"
            index += 1
        }
        if KAPI.core.asserts.ASSERT_DEBUG == nil {
            nil_list[index] = "KASSERT_DEBUG"
            index += 1
        }
        if KAPI.core.app.application_create == nil {
            nil_list[index] = "Kapplication_create"
            index += 1
        }
        if KAPI.core.app.application_run == nil {
            nil_list[index] = "Kapplication_run"
            index += 1
        }
        if KAPI.core.mem.initialize_memory == nil {
            nil_list[index] = "Kinitialize_memory"
            index += 1
        }
        if KAPI.core.mem.shutdown_memory == nil {
            nil_list[index] = "Kshutdown_memory"
            index += 1
        }
        if KAPI.core.str.length == nil {
            nil_list[index] = "Kstring_length"
            index += 1
        }
        if KAPI.core.str.duplicate == nil {
            nil_list[index] = "Kstring_duplicate"
            index += 1
        }
        if KAPI.core.event.register == nil {
            nil_list[index] = "Kevent_register"
            index += 1
        }
        if KAPI.core.event.unregister == nil {
            nil_list[index] = "Kevent_unregister"
            index += 1
        }
        if KAPI.core.event.fire == nil {
            nil_list[index] = "Kevent_fire"
            index += 1
        }
        if KAPI.core.input.is_key_down == nil {
            nil_list[index] = "Kis_key_down"
            index += 1
        }
        if KAPI.core.input.is_key_up == nil {
            nil_list[index] = "Kis_key_up"
            index += 1
        }
        if KAPI.core.input.was_key_down == nil {
            nil_list[index] = "Kwas_key_down"
            index += 1
        }
        if KAPI.core.input.was_key_up == nil {
            nil_list[index] = "Kwas_key_up"
            index += 1
        }
        if KAPI.core.input.is_button_down == nil {
            nil_list[index] = "Kis_button_down"
            index += 1
        }
        if KAPI.core.input.is_button_up == nil {
            nil_list[index] = "Kis_button_up"
            index += 1
        }
        if KAPI.core.input.was_button_down == nil {
            nil_list[index] = "Kwas_button_down"
            index += 1
        }
        if KAPI.core.input.was_button_up == nil {
            nil_list[index] = "Kwas_button_up"
            index += 1
        }
        if KAPI.core.input.get_mouse_position == nil {
            nil_list[index] = "Kget_mouse_position"
            index += 1
        }
        if KAPI.core.input.get_previous_mouse_position == nil {
            nil_list[index] = "Kget_previous_mouse_position"
            index += 1
        }
        if KAPI.containers.darray.make == nil {
            nil_list[index] = "Kdarray_make"
            index += 1  
        }
        if KAPI.containers.darray.delete == nil {
            nil_list[index] = "Kdarray_delete"
            index += 1  
        }
        if KAPI.containers.darray.reserve == nil {
            nil_list[index] = "Kdarray_reserve"
            index += 1  
        }
        if KAPI.containers.darray.resize == nil {
            nil_list[index] = "Kdarray_resize"
            index += 1  
        }
        if KAPI.containers.darray.push == nil {
            nil_list[index] = "Kdarray_push"
            index += 1  
        }
        if KAPI.containers.darray.pop == nil {
            nil_list[index] = "Kdarray_pop"
            index += 1  
        }
        if KAPI.containers.darray.insert_at == nil {
            nil_list[index] = "Kdarray_insert_at"
            index += 1  
        }
        if KAPI.containers.darray.pop_at == nil {
            nil_list[index] = "Kdarray_pop_at"
            index += 1  
        }
        if KAPI.containers.darray.clear == nil {
            nil_list[index] = "Kdarray_clear"
            index += 1  
        }
        if KAPI.Kdarray_set_len == nil {
            nil_list[index] = "Kdarray_set_len"
            index += 1  
        }
        if KAPI.KAPI_VERSION == 0 {
            nil_list[index] = "KAPI_VERSION"
            index += 1
        }
        if KAPI.KENGINE_VERSION == 0 {
            nil_list[index] = "KENGINE_VERSION"
            index += 1
        }

        fmt.eprintf("Null function pointers: %v\n", nil_list)
        return false
    }

    KAPI.is_initialized = true
    KAPI.KAPI_lib = lib
    return true
}

shutdown :: proc() {
    KAPI.core.asserts.ASSERT = nil
    KAPI.core.asserts.ASSERT_MSG = nil
    KAPI.core.asserts.ASSERT_DEBUG = nil
    KAPI.core.log.FATAL = nil
    KAPI.core.log.ERROR = nil
    KAPI.core.log.DEBUG = nil
    KAPI.core.log.INFO = nil
    KAPI.core.log.WARN = nil
    KAPI.core.log.TRACE = nil
    KAPI.core.app.application_create = nil
    KAPI.core.app.application_run = nil
    KAPI.core.memory.initialize = nil
    KAPI.core.memory.shutdown = nil
    KAPI.core.memory.allocate = nil
    KAPI.core.memory.free = nil
    KAPI.core.memory.copy = nil
    KAPI.core.memory.zero = nil
    KAPI.core.memory.set = nil
    KAPI.core.memory.get_usage_str = nil
    KAPI.core.str.length = nil
    KAPI.core.str.duplicate = nil
    KAPI.core.event.register = nil
    KAPI.core.event.unregister = nil
    KAPI.core.event.fire = nil
    KAPI.core.input.is_key_down = nil
    KAPI.core.input.is_key_up = nil
    KAPI.core.input.was_key_down = nil
    KAPI.core.input.was_key_up = nil
    KAPI.core.input.is_button_down = nil
    KAPI.core.input.is_button_up = nil
    KAPI.core.input.was_button_down = nil
    KAPI.core.input.was_button_up = nil
    KAPI.core.input.get_mouse_position = nil
    KAPI.core.input.get_previous_mouse_position = nil
    KAPI.containers.darray.make = nil
    KAPI.containers.darray.delete = nil
    KAPI.containers.darray.reserve = nil
    KAPI.containers.darray.resize = nil
    KAPI.containers.darray.push = nil
    KAPI.containers.darray.pop = nil
    KAPI.containers.darray.insert_at = nil
    KAPI.containers.darray.pop_at = nil
    KAPI.containers.darray.clear = nil
    KAPI.Kdarray_set_len = nil
    KAPI.KAPI_VERSION = 0
    KAPI.KENGINE_VERSION = 0

    if KAPI.KAPI_lib != nil {
        dynlib.unload_library(KAPI.KAPI_lib)
        KAPI.KAPI_lib = nil
    }
    KAPI.is_initialized = false
}