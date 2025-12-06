#+private
package Kohi_API

import runtime "base:runtime"
import fmt "core:fmt"
import dynlib "core:dynlib"

when ODIN_DEBUG {
    KAPI_t :: struct {
        is_initialized : bool,
        core: struct {
            asserts : struct {
                // asserts
                ASSERT : proc(bool, string, runtime.Source_Code_Location),
                ASSERT_MSG : proc(bool, string, string, runtime.Source_Code_Location),
                ASSERT_DEBUG : proc(bool, string, runtime.Source_Code_Location),
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
                application_create : proc(rawptr) -> bool,
                application_run : proc() -> bool,
            },
            mem : struct {
                // memory management
                initialize_memory : proc(),
                shutdown_memory : proc(),
                allocate : proc(u64, memory_tag) -> rawptr,
                free : proc(rawptr, u64, memory_tag),
                zero_memory : proc(rawptr, u64) -> rawptr,
                copy_memory : proc(rawptr, rawptr, u64) -> rawptr,
                set_memory : proc(rawptr, i32, u64) -> rawptr,
                get_memory_usage_str : proc() -> string,
            },
            str : struct {
                // strings
                string_length : proc(string) -> u64,
                string16_length : proc(string16) -> u64,
                cstring_length : proc(cstring) -> u64,
                cstring16_length : proc(cstring16) -> u64,
                string_duplicate : proc(string) -> string,
                cstring_duplicate : proc(cstring) -> cstring,
                string16_duplicate : proc(string16) -> string16,
                cstring16_duplicate : proc(cstring16) -> cstring16,
                string_equal : proc(string, string) -> bool,
                cstring_equal : proc(cstring, cstring) -> bool,
                string16_equal : proc(string16, string16) -> bool,
                cstring16_equal : proc(cstring16, cstring16) -> bool,
                to_wstring : proc(string) -> cstring16,
                from_wstring : proc(cstring16) -> string,
                bytes_to_cstring : proc([]u8) -> cstring,
            },
            event : struct {
                // event system
                event_register : proc(u16, rawptr, PFN_on_event) -> bool,
                event_unregister : proc(u16, rawptr, PFN_on_event) -> bool,
                event_fire : proc(u16, rawptr, event_context) -> bool,
            },
            input : struct {
                // input system
                is_key_down : proc(keys) -> bool,
                is_key_up : proc(keys) -> bool,
                was_key_down : proc(keys) -> bool,
                was_key_up : proc(keys) -> bool,
                is_button_down : proc(buttons) -> bool,
                is_button_up : proc(buttons) -> bool,
                was_button_down : proc(buttons) -> bool,
                was_button_up : proc(buttons) -> bool,
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
                pop : proc(rawptr, typeid, rawptr) -> bool,
                insert_at : proc(rawptr, typeid, u64, rawptr) -> bool,
                pop_at : proc(rawptr, typeid, u64, rawptr) -> bool,
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
} else {
    KAPI_t :: struct {
        // Placeholder for release builds
        is_initialized : bool,
        core: struct {
            asserts : struct {
                // asserts
                ASSERT : proc(bool, string, runtime.Source_Code_Location),
                ASSERT_MSG : proc(bool, string, string, runtime.Source_Code_Location),
                ASSERT_DEBUG : proc(bool, string, runtime.Source_Code_Location),
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
                application_create : proc(rawptr) -> bool,
                application_run : proc() -> bool,
            },
            mem : struct {
                // memory management
                initialize_memory : proc(),
                shutdown_memory : proc(),
                allocate : proc(u64, memory_tag) -> rawptr,
                free : proc(rawptr, u64, memory_tag),
                zero_memory : proc(rawptr, u64) -> rawptr,
                copy_memory : proc(rawptr, rawptr, u64) -> rawptr,
                set_memory : proc(rawptr, i32, u64) -> rawptr,
            },
            str : struct {
                // strings
                string_length : proc(string) -> u64,
                string16_length : proc(string16) -> u64,
                cstring_length : proc(cstring) -> u64,
                cstring16_length : proc(cstring16) -> u64,
                string_duplicate : proc(string) -> string,
                cstring_duplicate : proc(cstring) -> cstring,
                string16_duplicate : proc(string16) -> string16,
                cstring16_duplicate : proc(cstring16) -> cstring16,
                string_equal : proc(string, string) -> bool,
                cstring_equal : proc(cstring, cstring) -> bool,
                string16_equal : proc(string16, string16) -> bool,
                cstring16_equal : proc(cstring16, cstring16) -> bool,
                to_wstring : proc(string) -> cstring16,
                from_wstring : proc(cstring16) -> string,
                bytes_to_cstring : proc([]u8) -> cstring,
            },
            event : struct {
                // event system
                event_register : proc(u16, rawptr, PFN_on_event) -> bool,
                event_unregister : proc(u16, rawptr, PFN_on_event) -> bool,
                event_fire : proc(u16, rawptr, event_context) -> bool,
            },
            input : struct {
                // input system
                is_key_down : proc(keys) -> bool,
                is_key_up : proc(keys) -> bool,
                was_key_down : proc(keys) -> bool,
                was_key_up : proc(keys) -> bool,
                is_button_down : proc(buttons) -> bool,
                is_button_up : proc(buttons) -> bool,
                was_button_down : proc(buttons) -> bool,
                was_button_up : proc(buttons) -> bool,
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
                pop : proc(rawptr, typeid, rawptr) -> bool,
                insert_at : proc(rawptr, typeid, u64, rawptr) -> bool,
                pop_at : proc(rawptr, typeid, u64, rawptr) -> bool,
                clear : proc(rawptr, typeid),
                set_len : proc(rawptr, typeid, u64),
            },
        },

        // Version variables
        API_VERSION : u64,
        ENGINE_VERSION : u64,
        
        // Library handle
        KAPI_lib : dynlib.Library,
    }
}
KAPI : KAPI_t

load_kohi_api :: proc() -> bool {
    if KAPI.is_initialized && KAPI.KAPI_lib != nil {
        return true
    }

    dll_name := fmt.tprintf("kohi_engine.%v", dynlib.LIBRARY_FILE_EXTENSION)
    
    lib, lib_ok := dynlib.load_library(dll_name)
    if !lib_ok {
        fmt.eprintf("Failed to load library: %s\n", dll_name)
        return false
    }
    KAPI.is_initialized = false

    // Load function pointers
    KAPI.core.asserts.ASSERT = cast(proc(bool, string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT") or_else nil)
    KAPI.core.asserts.ASSERT_MSG = cast(proc(bool, string, string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT_MSG") or_else nil)
    KAPI.core.asserts.ASSERT_DEBUG = cast(proc(bool, string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT_DEBUG") or_else nil)

    KAPI.core.log.FATAL = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KFATAL") or_else nil)
    KAPI.core.log.ERROR = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KERROR") or_else nil)
    KAPI.core.log.WARN = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KWARN") or_else nil)
    KAPI.core.log.INFO = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KINFO") or_else nil)
    KAPI.core.log.DEBUG = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KDEBUG") or_else nil)
    KAPI.core.log.TRACE = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KTRACE") or_else nil)

    KAPI.core.app.application_create = cast(proc(rawptr) -> bool)(dynlib.symbol_address(lib, "Kapplication_create") or_else nil)
    KAPI.core.app.application_run = cast(proc() -> bool)(dynlib.symbol_address(lib, "Kapplication_run") or_else nil)

    KAPI.core.mem.initialize_memory = cast(proc())(dynlib.symbol_address(lib, "Kinitialize_memory") or_else nil)
    KAPI.core.mem.shutdown_memory = cast(proc())(dynlib.symbol_address(lib, "Kshutdown_memory") or_else nil)
    KAPI.core.mem.allocate = cast(proc(u64, memory_tag) -> rawptr)(dynlib.symbol_address(lib, "Kallocate") or_else nil)
    KAPI.core.mem.free = cast(proc(rawptr, u64, memory_tag))(dynlib.symbol_address(lib, "Kfree") or_else nil)
    KAPI.core.mem.zero_memory = cast(proc(rawptr, u64) -> rawptr)(dynlib.symbol_address(lib, "Kzero_memory") or_else nil)
    KAPI.core.mem.copy_memory = cast(proc(rawptr, rawptr, u64) -> rawptr)(dynlib.symbol_address(lib, "Kcopy_memory") or_else nil)
    KAPI.core.mem.set_memory = cast(proc(rawptr, i32, u64) -> rawptr)(dynlib.symbol_address(lib, "Kset_memory") or_else nil)
    when ODIN_DEBUG {
        KAPI.core.mem.get_memory_usage_str = cast(proc() -> string)(dynlib.symbol_address(lib, "Kget_memory_usage_str") or_else nil)
    }
    
    KAPI.core.str.string_length = cast(proc(string) -> u64)(dynlib.symbol_address(lib, "Kstring_length") or_else nil)
    KAPI.core.str.cstring_length = cast(proc(cstring) -> u64)(dynlib.symbol_address(lib, "Kcstring_length") or_else nil)
    KAPI.core.str.string16_length = cast(proc(string16) -> u64)(dynlib.symbol_address(lib, "Kstring16_length") or_else nil)
    KAPI.core.str.cstring16_length = cast(proc(cstring16) -> u64)(dynlib.symbol_address(lib, "Kcstring16_length") or_else nil)
    KAPI.core.str.string_duplicate = cast(proc(string) -> string)(dynlib.symbol_address(lib, "Kstring_duplicate") or_else nil)
    KAPI.core.str.cstring_duplicate = cast(proc(cstring) -> cstring)(dynlib.symbol_address(lib, "Kcstring_duplicate") or_else nil)
    KAPI.core.str.string16_duplicate = cast(proc(string16) -> string16)(dynlib.symbol_address(lib, "Kstring16_duplicate") or_else nil)
    KAPI.core.str.cstring16_duplicate = cast(proc(cstring16) -> cstring16)(dynlib.symbol_address(lib, "Kcstring16_duplicate") or_else nil)
    KAPI.core.str.string_equal = cast(proc(string, string) -> bool)(dynlib.symbol_address(lib, "Kstring_equal") or_else nil)
    KAPI.core.str.cstring_equal = cast(proc(cstring, cstring) -> bool)(dynlib.symbol_address(lib, "Kcstring_equal") or_else nil)
    KAPI.core.str.string16_equal = cast(proc(string16, string16) -> bool)(dynlib.symbol_address(lib, "Kstring16_equal") or_else nil)
    KAPI.core.str.cstring16_equal = cast(proc(cstring16, cstring16) -> bool)(dynlib.symbol_address(lib, "Kcstring16_equal") or_else nil)
    KAPI.core.str.to_wstring = cast(proc(string) -> cstring16)(dynlib.symbol_address(lib, "Kto_wstring") or_else nil)
    KAPI.core.str.from_wstring = cast(proc(cstring16) -> string)(dynlib.symbol_address(lib, "Kfrom_wstring") or_else nil)
    KAPI.core.str.bytes_to_cstring = cast(proc([]u8) -> cstring)(dynlib.symbol_address(lib, "Kbytes_to_cstring") or_else nil)

    KAPI.core.event.event_register = cast(proc(u16, rawptr, PFN_on_event) -> bool)(dynlib.symbol_address(lib, "Kevent_register") or_else nil)
    KAPI.core.event.event_unregister = cast(proc(u16, rawptr, PFN_on_event) -> bool)(dynlib.symbol_address(lib, "Kevent_unregister") or_else nil)
    KAPI.core.event.event_fire = cast(proc(u16, rawptr, event_context) -> bool)(dynlib.symbol_address(lib, "Kevent_fire") or_else nil)

    KAPI.core.input.is_key_down = cast(proc(keys) -> bool)(dynlib.symbol_address(lib, "Kis_key_down") or_else nil)
    KAPI.core.input.is_key_up = cast(proc(keys) -> bool)(dynlib.symbol_address(lib, "Kis_key_up") or_else nil)
    KAPI.core.input.was_key_down = cast(proc(keys) -> bool)(dynlib.symbol_address(lib, "Kwas_key_down") or_else nil)
    KAPI.core.input.was_key_up = cast(proc(keys) -> bool)(dynlib.symbol_address(lib, "Kwas_key_up") or_else nil)
    KAPI.core.input.is_button_down = cast(proc(buttons) -> bool)(dynlib.symbol_address(lib, "Kis_button_down") or_else nil)
    KAPI.core.input.is_button_up = cast(proc(buttons) -> bool)(dynlib.symbol_address(lib, "Kis_button_up") or_else nil)
    KAPI.core.input.was_button_down = cast(proc(buttons) -> bool)(dynlib.symbol_address(lib, "Kwas_button_down") or_else nil)
    KAPI.core.input.was_button_up = cast(proc(buttons) -> bool)(dynlib.symbol_address(lib, "Kwas_button_up") or_else nil)
    KAPI.core.input.get_mouse_position = cast(proc(^i32, ^i32))(dynlib.symbol_address(lib, "Kget_mouse_position") or_else nil)
    KAPI.core.input.get_previous_mouse_position = cast(proc(^i32, ^i32))(dynlib.symbol_address(lib, "Kget_previous_mouse_position") or_else nil)

    KAPI.containers.darray.make = cast(proc(typeid) -> rawptr)(dynlib.symbol_address(lib, "Kdarray_make") or_else nil)
    KAPI.containers.darray.delete = cast(proc(rawptr, typeid))(dynlib.symbol_address(lib, "Kdarray_delete") or_else nil)
    KAPI.containers.darray.resize = cast(proc(rawptr, typeid, u64))(dynlib.symbol_address(lib, "Kdarray_resize") or_else nil)
    KAPI.containers.darray.reserve = cast(proc(rawptr, typeid, u64) -> bool)(dynlib.symbol_address(lib, "Kdarray_reserve") or_else nil)
    KAPI.containers.darray.push = cast(proc(rawptr, typeid, rawptr) -> bool)(dynlib.symbol_address(lib, "Kdarray_push") or_else nil)
    KAPI.containers.darray.pop = cast(proc(rawptr, typeid, rawptr) -> bool)(dynlib.symbol_address(lib, "Kdarray_pop") or_else nil)
    KAPI.containers.darray.insert_at = cast(proc(rawptr, typeid, u64, rawptr) -> bool)(dynlib.symbol_address(lib, "Kdarray_insert_at") or_else nil)
    KAPI.containers.darray.pop_at = cast(proc(rawptr, typeid, u64, rawptr) -> bool)(dynlib.symbol_address(lib, "Kdarray_pop_at") or_else nil)
    KAPI.containers.darray.clear = cast(proc(rawptr, typeid))(dynlib.symbol_address(lib, "Kdarray_clear") or_else nil)
    KAPI.containers.darray.set_len = cast(proc(rawptr, typeid, u64))(dynlib.symbol_address(lib, "Kdarray_set_len") or_else nil)
    // Load version variables
    temp_ver := cast(^u64)(dynlib.symbol_address(lib, "KAPI_VERSION") or_else nil)
    if temp_ver != nil {
        KAPI.API_VERSION = temp_ver^
    } else {
        dynlib.unload_library(lib)
        fmt.eprintf("Error Loading kohi_engine, could not load KAPI_VERSION symbol!\n")
        return false
    }

    temp_ver = cast(^u64)(dynlib.symbol_address(lib, "KENGINE_VERSION") or_else nil)
    if temp_ver != nil {
        KAPI.ENGINE_VERSION = temp_ver^
    } else {
        dynlib.unload_library(lib)
        fmt.eprintf("Error Loading kohi_engine, could not load KENGINE_VERSION symbol!\n")
        return false
    }

    // Check if functions loaded successfully
    if KAPI.core.mem.allocate == nil {
        append(nil_list, "Kallocate")
    }
    if KAPI.core.mem.free == nil {
        append(nil_list, "Kfree")
    }
    if KAPI.core.mem.copy_memory == nil {
        append(nil_list, "Kcopy_memory")
    }
    if KAPI.core.mem.zero_memory == nil {
        append(nil_list, "Kzero_memory")
    }
    if KAPI.core.mem.set_memory == nil {
        append(nil_list, "Kset_memory")
    }
    if KAPI.core.mem.get_memory_usage_str == nil {
        append(nil_list, "Kget_memory_usage_str")
    }
    if KAPI.core.log.DEBUG == nil {
        append(nil_list, "KDEBUG")
    }
    if KAPI.core.log.INFO == nil {
        append(nil_list, "KINFO")
    }
    if KAPI.core.log.FATAL == nil {
        append(nil_list, "KFATAL")
    }
    if KAPI.core.log.ERROR == nil {
        append(nil_list, "KERROR")
    }
    if KAPI.core.log.WARN == nil {
        append(nil_list, "KWARN")
    }
    if KAPI.core.log.TRACE == nil {
        append(nil_list, "KTRACE")
    }
    if KAPI.core.asserts.ASSERT == nil {
        append(nil_list, "KASSERT")
    }
    if KAPI.core.asserts.ASSERT_MSG == nil {
        append(nil_list, "KASSERT_MSG")
    }
    if KAPI.core.asserts.ASSERT_DEBUG == nil {
        append(nil_list, "KASSERT_DEBUG")
    }
    if KAPI.core.app.application_create == nil {
        append(nil_list, "Kapplication_create")
    }
    if KAPI.core.app.application_run == nil {
        append(nil_list, "Kapplication_run")
    }
    if KAPI.core.mem.initialize_memory == nil {
        append(nil_list, "Kinitialize_memory")
    }
    if KAPI.core.mem.shutdown_memory == nil {
        append(nil_list, "Kshutdown_memory")
    }
    if KAPI.core.str.string_length == nil {
        append(nil_list, "Kstring_length")
    }
    if KAPI.core.str.cstring_length == nil {
        append(nil_list, "Kcstring_length")
    }
    if KAPI.core.str.string16_length == nil {
        append(nil_list, "Kstring16_length")
    }
    if KAPI.core.str.cstring16_length == nil {
        append(nil_list, "Kcstring16_length")
    }
    if KAPI.core.str.string_duplicate == nil {
        append(nil_list, "Kstring_duplicate")
    }
    if KAPI.core.str.cstring_duplicate == nil {
        append(nil_list, "Kcstring_duplicate")
    }
    if KAPI.core.str.string16_duplicate == nil {
        append(nil_list, "Kstring16_duplicate")
    }
    if KAPI.core.str.cstring16_duplicate == nil {
        append(nil_list, "Kcstring16_duplicate")
    }
    if KAPI.core.str.string_equal == nil {
        append(nil_list, "Kstring_equal")
    }
    if KAPI.core.str.cstring_equal == nil {
        append(nil_list, "Kcstring_equal")
    }
    if KAPI.core.str.string16_equal == nil {
        append(nil_list, "Kstring16_equal")
    }
    if KAPI.core.str.cstring16_equal == nil {
        append(nil_list, "Kcstring16_equal")
    }
    if KAPI.core.str.to_wstring == nil {
        append(nil_list, "Kto_wstring")
    }
    if KAPI.core.str.from_wstring == nil {
        append(nil_list, "Kfrom_wstring")
    }
    if KAPI.core.str.bytes_to_cstring == nil {
        append(nil_list, "Kbytes_to_cstring")
    }
    if KAPI.core.event.event_register == nil {
        append(nil_list, "Kevent_register")
    }
    if KAPI.core.event.event_unregister == nil {
        append(nil_list, "Kevent_unregister")
    }
    if KAPI.core.event.event_fire == nil {
        append(nil_list, "Kevent_fire")
    }
    if KAPI.core.input.is_key_down == nil {
        append(nil_list, "Kis_key_down")
    }
    if KAPI.core.input.is_key_up == nil {
        append(nil_list, "Kis_key_up")
    }
    if KAPI.core.input.was_key_down == nil {
        append(nil_list, "Kwas_key_down")
    }
    if KAPI.core.input.was_key_up == nil {
        append(nil_list, "Kwas_key_up")
    }
    if KAPI.core.input.is_button_down == nil {
        append(nil_list, "Kis_button_down")
    }
    if KAPI.core.input.is_button_up == nil {
        append(nil_list, "Kis_button_up")
    }
    if KAPI.core.input.was_button_down == nil {
        append(nil_list, "Kwas_button_down")
    }
    if KAPI.core.input.was_button_up == nil {
        append(nil_list, "Kwas_button_up")
    }
    if KAPI.core.input.get_mouse_position == nil {
        append(nil_list, "Kget_mouse_position")
    }
    if KAPI.core.input.get_previous_mouse_position == nil {
        append(nil_list, "Kget_previous_mouse_position")
    }
    if KAPI.containers.darray.make == nil {
        append(nil_list, "Kdarray_make")
    }
    if KAPI.containers.darray.delete == nil {
        append(nil_list, "Kdarray_delete")
    }
    if KAPI.containers.darray.reserve == nil {
        append(nil_list, "Kdarray_reserve")
    }
    if KAPI.containers.darray.resize == nil {
        append(nil_list, "Kdarray_resize")
    }
    if KAPI.containers.darray.push == nil {
        append(nil_list, "Kdarray_push")
    }
    if KAPI.containers.darray.pop == nil {
        append(nil_list, "Kdarray_pop")
    }
    if KAPI.containers.darray.insert_at == nil {
        append(nil_list, "Kdarray_insert_at")
    }
    if KAPI.containers.darray.pop_at == nil {
        append(nil_list, "Kdarray_pop_at")
    }
    if KAPI.containers.darray.clear == nil {
        append(nil_list, "Kdarray_clear")
    }
    if KAPI.containers.darray.set_len == nil {
        append(nil_list, "Kdarray_set_len")
    }
    if KAPI.API_VERSION == 0 {
        append(nil_list, "KAPI_VERSION")
    }
    if KAPI.ENGINE_VERSION == 0 {
        append(nil_list, "KENGINE_VERSION")
    }
    if len(nil_list) != 0 {
        dynlib.unload_library(lib)
        fmt.eprintf("%d Null function pointers: %v\n", len(nil_list), nil_list)
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
    KAPI.core.mem.initialize_memory = nil
    KAPI.core.mem.shutdown_memory = nil
    KAPI.core.mem.allocate = nil
    KAPI.core.mem.free = nil
    KAPI.core.mem.copy_memory = nil
    KAPI.core.mem.zero_memory = nil
    KAPI.core.mem.set_memory = nil
    KAPI.core.mem.get_memory_usage_str = nil
    KAPI.core.str.string_length = nil
    KAPI.core.str.cstring_length = nil
    KAPI.core.str.string16_length = nil
    KAPI.core.str.cstring16_length = nil
    KAPI.core.str.string_duplicate = nil
    KAPI.core.str.cstring_duplicate = nil
    KAPI.core.str.string16_duplicate = nil
    KAPI.core.str.cstring16_duplicate = nil
    KAPI.core.str.string_equal = nil
    KAPI.core.str.cstring_equal = nil
    KAPI.core.str.string16_equal = nil
    KAPI.core.str.cstring16_equal = nil
    KAPI.core.str.to_wstring = nil
    KAPI.core.str.from_wstring = nil
    KAPI.core.str.bytes_to_cstring = nil
    KAPI.core.event.event_register = nil
    KAPI.core.event.event_unregister = nil
    KAPI.core.event.event_fire = nil
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
    KAPI.containers.darray.set_len = nil
    KAPI.API_VERSION = 0
    KAPI.ENGINE_VERSION = 0

    if KAPI.KAPI_lib != nil {
        dynlib.unload_library(KAPI.KAPI_lib)
        KAPI.KAPI_lib = nil
    }
    KAPI.is_initialized = false
}