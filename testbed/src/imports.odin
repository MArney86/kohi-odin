package testbed
/*
import types "../../engine/src/types"
import runtime "base:runtime"
import fmt "core:fmt"
import dynlib "core:dynlib"
import helpers "../../libs/helpers"
import SmArr "core:container/small_array"

KAPI_t :: struct {
    // asserts
    KASSERT : proc(string, runtime.Source_Code_Location),
    KASSERT_MSG : proc(string, string, runtime.Source_Code_Location),
    KASSERT_DEBUG : proc(string, runtime.Source_Code_Location),
    
    // logging
    KFATAL : proc(string, ..any),
    KERROR : proc(string, ..any),
    KWARN : proc(string, ..any),
    KINFO : proc(string, ..any),
    KDEBUG : proc(string, ..any),
    KTRACE : proc(string, ..any),

    // application
    Kapplication_create : proc(rawptr) -> bool,
    Kapplication_run : proc() -> bool,

    // memory management
    Kinitialize_memory : proc(),
    Kshutdown_memory : proc(),
    Kallocate : proc(u64, types.memory_tag) -> rawptr,
    Kfree : proc(rawptr, u64, types.memory_tag),
    Kzero_memory : proc(rawptr, u64) -> rawptr,
    Kcopy_memory : proc(rawptr, rawptr, u64) -> rawptr,
    Kset_memory : proc(rawptr, i32, u64) -> rawptr,
    
    // strings
    Kstring_length : proc(string) -> u64,
    Kstring16_length : proc(string16) -> u64,
    Kcstring_length : proc(cstring) -> u64,
    Kcstring16_length : proc(cstring16) -> u64,
    Kstring_duplicate : proc(string) -> string,
    Kcstring_duplicate : proc(cstring) -> string,
    Kstring16_duplicate : proc(string16) -> string16,
    Kcstring16_duplicate : proc(cstring16) -> string16,
    Kstring_equals : proc(string, string) -> bool,
    Kcstring_equals : proc(cstring, cstring) -> bool,
    Kstring16_equals : proc(string16, string16) -> bool,
    Kcstring16_equals : proc(cstring16, cstring16) -> bool,
    Kto_wstring : proc(string) -> string16,
    Kfrom_wstring : proc(string16) -> string,
    Kbytes_to_cstring : proc([]u8) -> cstring,

    // event system
    Kevent_register : proc(u16, rawptr, types.PFN_on_event) -> bool,
    Kevent_unregister : proc(u16, rawptr, types.PFN_on_event) -> bool,
    Kevent_fire : proc(u16, rawptr, types.event_context) -> bool,

    // input system
    Kis_key_down : proc(types.keys) -> bool,
    Kis_key_up : proc(types.keys) -> bool,
    Kwas_key_down : proc(types.keys) -> bool,
    Kwas_key_up : proc(types.keys) -> bool,
    Kis_button_down : proc(types.buttons) -> bool,
    Kis_button_up : proc(types.buttons) -> bool,
    Kwas_button_down : proc(types.buttons) -> bool,
    Kwas_button_up : proc(types.buttons) -> bool,
    Kget_mouse_position : proc(^i32, ^i32),
    Kget_previous_mouse_position : proc(^i32, ^i32),

    // dynamic array functions
    Kdarray_make : proc(typeid) -> rawptr,
    Kdarray_delete : proc(rawptr, typeid),
    Kdarray_reserve : proc(rawptr, typeid) -> bool,
    Kdarray_resize : proc(rawptr, typeid, u64),
    Kdarray_push : proc(rawptr, typeid, rawptr) -> bool,
    Kdarray_pop : proc(rawptr, typeid) -> rawptr,
    Kdarray_insert_at : proc(rawptr, typeid, u64, rawptr) -> bool,
    Kdarray_pop_at : proc(rawptr, typeid, u64) -> rawptr,
    Kdarray_clear : proc(rawptr, typeid),
    Kdarray_set_len : proc(rawptr, typeid, u64),

    // Version variables
    KAPI_VERSION : u64,
    KENGINE_VERSION : u64,
    
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

    // Load function pointers
    KAPI.KASSERT = cast(proc(string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT") or_else nil)

    KAPI.KASSERT_MSG = cast(proc(string, string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT_MSG") or_else nil)
    KAPI.KASSERT_DEBUG = cast(proc(string, runtime.Source_Code_Location))(dynlib.symbol_address(lib, "KASSERT_DEBUG") or_else nil)

    KAPI.KFATAL = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KFATAL") or_else nil)
    KAPI.KERROR = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KERROR") or_else nil)
    KAPI.KWARN = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KWARN") or_else nil)
    KAPI.KINFO = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KINFO") or_else nil)
    KAPI.KDEBUG = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KDEBUG") or_else nil)
    KAPI.KTRACE = cast(proc(string, ..any))(dynlib.symbol_address(lib, "KTRACE") or_else nil)
    KAPI.Kapplication_create = cast(proc(rawptr) -> bool)(dynlib.symbol_address(lib, "Kapplication_create") or_else nil)
    KAPI.Kapplication_run = cast(proc() -> bool)(dynlib.symbol_address(lib, "Kapplication_run") or_else nil)

    KAPI.Kinitialize_memory = cast(proc())(dynlib.symbol_address(lib, "Kinitialize_memory") or_else nil)
    KAPI.Kshutdown_memory = cast(proc())(dynlib.symbol_address(lib, "Kshutdown_memory") or_else nil)
    KAPI.Kallocate = cast(proc(u64, types.memory_tag) -> rawptr)(dynlib.symbol_address(lib, "Kallocate") or_else nil)
    KAPI.Kfree = cast(proc(rawptr, u64, types.memory_tag))(dynlib.symbol_address(lib, "Kfree") or_else nil)
    KAPI.Kzero_memory = cast(proc(rawptr, u64) -> rawptr)(dynlib.symbol_address(lib, "Kzero_memory") or_else nil)
    KAPI.Kcopy_memory = cast(proc(rawptr, rawptr, u64) -> rawptr)(dynlib.symbol_address(lib, "Kcopy_memory") or_else nil)
    KAPI.Kset_memory = cast(proc(rawptr, i32, u64) -> rawptr)(dynlib.symbol_address(lib, "Kset_memory") or_else nil)
    KAPI.Kget_memory_usage_str = cast(proc() -> string)(dynlib.symbol_address(lib, "Kget_memory_usage_str") or_else nil)

    KAPI.Kstring_length = cast(proc(string) -> u64)(dynlib.symbol_address(lib, "Kstring_length") or_else nil)
    KAPI.Kstring16_length = cast(proc(string16) -> u64)(dynlib.symbol_address(lib, "Kstring16_length") or_else nil)
    KAPI.Kcstring_length = cast(proc(cstring) -> u64)(dynlib.symbol_address(lib, "Kcstring_length") or_else nil)
    KAPI.Kcstring16_length = cast(proc(cstring16) -> u64)(dynlib.symbol_address(lib, "Kcstring16_length") or_else nil)
    KAPI.Kstring_duplicate = cast(proc(string) -> string)(dynlib.symbol_address(lib, "Kstring_duplicate") or_else nil)
    KAPI.Kcstring_duplicate = cast(proc(cstring) -> string)(dynlib.symbol_address(lib, "Kcstring_duplicate") or_else nil)
    KAPI.Kstring16_duplicate = cast(proc(string16) -> string16)(dynlib.symbol_address(lib, "Kstring16_duplicate") or_else nil)
    KAPI.Kcstring16_duplicate = cast(proc(cstring16) -> string16)(dynlib.symbol_address(lib, "Kcstring16_duplicate") or_else nil)
    KAPI.Kstring_equals = cast(proc(string, string) -> bool)(dynlib.symbol_address(lib, "Kstring_equals") or_else nil)
    KAPI.Kcstring_equals = cast(proc(cstring, cstring) -> bool)(dynlib.symbol_address(lib, "Kcstring_equals") or_else nil)
    KAPI.Kstring16_equals = cast(proc(string16, string16) -> bool)(dynlib.symbol_address(lib, "Kstring16_equals") or_else nil)
    KAPI.Kcstring16_equals = cast(proc(cstring16, cstring16) -> bool)(dynlib.symbol_address(lib, "Kcstring16_equals") or_else nil)
    KAPI.Kto_wstring = cast(proc(string) -> string16)(dynlib.symbol_address(lib, "Kto_wstring") or_else nil)
    KAPI.Kfrom_wstring = cast(proc(string16) -> string)(dynlib.symbol_address(lib, "Kfrom_wstring") or_else nil)
    KAPI.Kbytes_to_cstring = cast(proc([]u8) -> cstring)(dynlib.symbol_address(lib, "Kbytes_to_cstring") or_else nil)

    KAPI.Kevent_register = cast(proc(u16, rawptr, types.PFN_on_event) -> bool)(dynlib.symbol_address(lib, "Kevent_register") or_else nil)
    KAPI.Kevent_unregister = cast(proc(u16, rawptr, types.PFN_on_event) -> bool)(dynlib.symbol_address(lib, "Kevent_unregister") or_else nil)
    KAPI.Kevent_fire = cast(proc(u16, rawptr, types.event_context) -> bool)(dynlib.symbol_address(lib, "Kevent_fire") or_else nil)

    KAPI.Kis_key_down = cast(proc(types.keys) -> bool)(dynlib.symbol_address(lib, "Kis_key_down") or_else nil)
    KAPI.Kis_key_up = cast(proc(types.keys) -> bool)(dynlib.symbol_address(lib, "Kis_key_up") or_else nil)
    KAPI.Kwas_key_down = cast(proc(types.keys) -> bool)(dynlib.symbol_address(lib, "Kwas_key_down") or_else nil)
    KAPI.Kwas_key_up = cast(proc(types.keys) -> bool)(dynlib.symbol_address(lib, "Kwas_key_up") or_else nil)
    KAPI.Kis_button_down = cast(proc(types.buttons) -> bool)(dynlib.symbol_address(lib, "Kis_button_down") or_else nil)
    KAPI.Kis_button_up = cast(proc(types.buttons) -> bool)(dynlib.symbol_address(lib, "Kis_button_up") or_else nil)
    KAPI.Kwas_button_down = cast(proc(types.buttons) -> bool)(dynlib.symbol_address(lib, "Kwas_button_down") or_else nil)
    KAPI.Kwas_button_up = cast(proc(types.buttons) -> bool)(dynlib.symbol_address(lib, "Kwas_button_up") or_else nil)
    KAPI.Kget_mouse_position = cast(proc(^i32, ^i32))(dynlib.symbol_address(lib, "Kget_mouse_position") or_else nil)
    KAPI.Kget_previous_mouse_position = cast(proc(^i32, ^i32))(dynlib.symbol_address(lib, "Kget_previous_mouse_position") or_else nil)

    KAPI.Kdarray_make = cast(proc(typeid) -> rawptr)(dynlib.symbol_address(lib, "Kdarray_make") or_else nil)
    KAPI.Kdarray_delete = cast(proc(rawptr, typeid))(dynlib.symbol_address(lib, "Kdarray_delete") or_else nil)
    KAPI.Kdarray_reserve = cast(proc(rawptr, typeid) -> bool)(dynlib.symbol_address(lib, "Kdarray_reserve") or_else nil)
    KAPI.Kdarray_resize = cast(proc(rawptr, typeid, u64))(dynlib.symbol_address(lib, "Kdarray_resize") or_else nil)
    KAPI.Kdarray_push = cast(proc(rawptr, typeid, rawptr) -> bool)(dynlib.symbol_address(lib, "Kdarray_push") or_else nil)
    KAPI.Kdarray_pop = cast(proc(rawptr, typeid) -> rawptr)(dynlib.symbol_address(lib, "Kdarray_pop") or_else nil)
    KAPI.Kdarray_insert_at = cast(proc(rawptr, typeid, u64, rawptr) -> bool)(dynlib.symbol_address(lib, "Kdarray_insert_at") or_else nil)
    KAPI.Kdarray_pop_at = cast(proc(rawptr, typeid, u64) -> rawptr)(dynlib.symbol_address(lib, "Kdarray_pop_at") or_else nil)
    KAPI.Kdarray_clear = cast(proc(rawptr, typeid))(dynlib.symbol_address(lib, "Kdarray_clear") or_else nil)
    KAPI.Kdarray_set_len = cast(proc(rawptr, typeid, u64))(dynlib.symbol_address(lib, "Kdarray_set_len") or_else nil)

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
    if KAPI.Kallocate == nil || 
       KAPI.Kfree == nil || 
       KAPI.Kcopy_memory == nil ||
       KAPI.KDEBUG == nil || 
       KAPI.KINFO == nil || 
       KAPI.KFATAL == nil ||
       KAPI.Kapplication_create == nil || 
       KAPI.Kapplication_run == nil ||
       KAPI.Kinitialize_memory == nil || 
       KAPI.Kshutdown_memory == nil ||
       KAPI.KASSERT == nil || 
       KAPI.KASSERT_MSG == nil || 
       KAPI.KASSERT_DEBUG == nil ||
       KAPI.KERROR == nil || 
       KAPI.KWARN == nil || 
       KAPI.KTRACE == nil ||
       KAPI.Kzero_memory == nil || 
       KAPI.Kset_memory == nil || 
       KAPI.Kget_memory_usage_str == nil ||
       KAPI.Kstring_length == nil || 
       KAPI.Kstring16_length == nil ||
       KAPI.Kcstring_length == nil ||
       KAPI.Kcstring16_length == nil ||
       KAPI.Kstring_duplicate == nil ||
       KAPI.Kcstring_duplicate == nil ||
       KAPI.Kstring16_duplicate == nil ||
       KAPI.Kcstring16_duplicate == nil ||
       KAPI.Kstring_equals == nil ||
       KAPI.Kcstring_equals == nil ||
       KAPI.Kstring16_equals == nil ||
       KAPI.Kcstring16_equals == nil ||
       KAPI.Kto_wstring == nil ||
       KAPI.Kfrom_wstring == nil ||
       KAPI.Kbytes_to_cstring == nil ||
       KAPI.Kevent_register == nil || 
       KAPI.Kevent_unregister == nil ||
       KAPI.Kevent_fire == nil ||
       KAPI.Kis_key_down == nil ||
       KAPI.Kis_key_up == nil ||
       KAPI.Kwas_key_down == nil ||
       KAPI.Kwas_key_up == nil ||
       KAPI.Kis_button_down == nil ||
       KAPI.Kis_button_up == nil ||
       KAPI.Kwas_button_down == nil ||
       KAPI.Kwas_button_up == nil ||
       KAPI.Kget_mouse_position == nil ||
       KAPI.Kget_previous_mouse_position == nil ||
       KAPI.Kdarray_make == nil ||
       KAPI.Kdarray_delete == nil ||
       KAPI.Kdarray_reserve == nil ||
       KAPI.Kdarray_resize == nil ||
       KAPI.Kdarray_push == nil ||
       KAPI.Kdarray_pop == nil ||
       KAPI.Kdarray_insert_at == nil ||
       KAPI.Kdarray_pop_at == nil ||
       KAPI.Kdarray_clear == nil ||
       KAPI.Kdarray_set_len == nil ||
       KAPI.KAPI_VERSION == 0 ||
       KAPI.KENGINE_VERSION == 0 {
        dynlib.unload_library(lib)
        fmt.eprintf("One or more required function pointers are null in the loaded library %s\n", dll_name)
        nil_list : [59]string
        index: = 0
        if KAPI.Kallocate == nil {
           nil_list[index] = "Kallocate"
           index += 1
        }
        if KAPI.Kfree == nil {
            nil_list[index] = "Kfree"
            index += 1
        }
        if KAPI.Kcopy_memory == nil {
            nil_list[index] = "Kcopy_memory"
            index += 1
        }
        if KAPI.Kzero_memory == nil {
            nil_list[index] = "Kzero_memory"
            index += 1
        }
        if KAPI.Kset_memory == nil {
            nil_list[index] = "Kset_memory"
            index += 1
        }
        if KAPI.Kget_memory_usage_str == nil {
            nil_list[index] = "Kget_memory_usage_str"
            index += 1
        }
        if KAPI.KDEBUG == nil {
            nil_list[index] = "KDEBUG"
            index += 1
        }
        if KAPI.KINFO == nil {
            nil_list[index] = "KINFO"
            index += 1
        }
        if KAPI.KFATAL == nil {
            nil_list[index] = "KFATAL"
            index += 1
        }
        if KAPI.KERROR == nil {
            nil_list[index] = "KERROR"
            index += 1
        }
        if KAPI.KWARN == nil {
            nil_list[index] = "KWARN"
            index += 1
        }
        if KAPI.KTRACE == nil {
            nil_list[index] = "KTRACE"
            index += 1
        }
        if KAPI.KASSERT == nil {
            nil_list[index] = "KASSERT"
            index += 1
        }
        if KAPI.KASSERT_MSG == nil {
            nil_list[index] = "KASSERT_MSG"
            index += 1
        }
        if KAPI.KASSERT_DEBUG == nil {
            nil_list[index] = "KASSERT_DEBUG"
            index += 1
        }
        if KAPI.Kapplication_create == nil {
            nil_list[index] = "Kapplication_create"
            index += 1
        }
        if KAPI.Kapplication_run == nil {
            nil_list[index] = "Kapplication_run"
            index += 1
        }
        if KAPI.Kinitialize_memory == nil {
            nil_list[index] = "Kinitialize_memory"
            index += 1
        }
        if KAPI.Kshutdown_memory == nil {
            nil_list[index] = "Kshutdown_memory"
            index += 1
        }
        if KAPI.Kstring_length == nil {
            nil_list[index] = "Kstring_length"
            index += 1
        }
        if KAPI.Kstring16_length == nil {
            nil_list[index] = "Kstring16_length"
            index += 1
        }
        if KAPI.Kcstring_length == nil {
            nil_list[index] = "Kcstring_length"
            index += 1
        }
        if KAPI.Kcstring16_length == nil {
            nil_list[index] = "Kcstring16_length"
            index += 1
        }
        if KAPI.Kstring_duplicate == nil {
            nil_list[index] = "Kstring_duplicate"
            index += 1
        }
        if KAPI.Kcstring_duplicate == nil {
            nil_list[index] = "Kcstring_duplicate"
            index += 1
        }
        if KAPI.Kstring16_duplicate == nil {
            nil_list[index] = "Kstring16_duplicate"
            index += 1
        }
        if KAPI.Kcstring16_duplicate == nil {
            nil_list[index] = "Kcstring16_duplicate"
            index += 1
        }
        if KAPI.Kstring_equals == nil {
            nil_list[index] = "Kstring_equals"
            index += 1
        }
        if KAPI.Kcstring_equals == nil {
            nil_list[index] = "Kcstring_equals"
            index += 1
        }
        if KAPI.Kstring16_equals == nil {
            nil_list[index] = "Kstring16_equals"
            index += 1
        }
        if KAPI.Kcstring16_equals == nil {
            nil_list[index] = "Kcstring16_equals"
            index += 1
        }
        if KAPI.Kto_wstring == nil {
            nil_list[index] = "Kto_wstring"
            index += 1
        }
        if KAPI.Kfrom_wstring == nil {
            nil_list[index] = "Kfrom_wstring"
            index += 1
        }
        if KAPI.Kbytes_to_cstring == nil {
            nil_list[index] = "Kbytes_to_cstring"
            index += 1
        }
        if KAPI.Kevent_register == nil {
            nil_list[index] = "Kevent_register"
            index += 1
        }
        if KAPI.Kevent_unregister == nil {
            nil_list[index] = "Kevent_unregister"
            index += 1
        }
        if KAPI.Kevent_fire == nil {
            nil_list[index] = "Kevent_fire"
            index += 1
        }
        if KAPI.Kis_key_down == nil {
            nil_list[index] = "Kis_key_down"
            index += 1
        }
        if KAPI.Kis_key_up == nil {
            nil_list[index] = "Kis_key_up"
            index += 1
        }
        if KAPI.Kwas_key_down == nil {
            nil_list[index] = "Kwas_key_down"
            index += 1
        }
        if KAPI.Kwas_key_up == nil {
            nil_list[index] = "Kwas_key_up"
            index += 1
        }
        if KAPI.Kis_button_down == nil {
            nil_list[index] = "Kis_button_down"
            index += 1
        }
        if KAPI.Kis_button_up == nil {
            nil_list[index] = "Kis_button_up"
            index += 1
        }
        if KAPI.Kwas_button_down == nil {
            nil_list[index] = "Kwas_button_down"
            index += 1
        }
        if KAPI.Kwas_button_up == nil {
            nil_list[index] = "Kwas_button_up"
            index += 1
        }
        if KAPI.Kget_mouse_position == nil {
            nil_list[index] = "Kget_mouse_position"
            index += 1
        }
        if KAPI.Kget_previous_mouse_position == nil {
            nil_list[index] = "Kget_previous_mouse_position"
            index += 1
        }
        if KAPI.Kdarray_make == nil {
            nil_list[index] = "Kdarray_make"
            index += 1
        }
        if KAPI.Kdarray_delete == nil {
            nil_list[index] = "Kdarray_delete"
            index += 1
        }
        if KAPI.Kdarray_reserve == nil {
            nil_list[index] = "Kdarray_reserve"
            index += 1
        }
        if KAPI.Kdarray_resize == nil {
            nil_list[index] = "Kdarray_resize"
            index += 1
        }
        if KAPI.Kdarray_push == nil {
            nil_list[index] = "Kdarray_push"
            index += 1
        }
        if KAPI.Kdarray_pop == nil {
            nil_list[index] = "Kdarray_pop"
            index += 1
        }
        if KAPI.Kdarray_insert_at == nil {
            nil_list[index] = "Kdarray_insert_at"
            index += 1
        }
        if KAPI.Kdarray_pop_at == nil {
            nil_list[index] = "Kdarray_pop_at"
            index += 1
        }
        if KAPI.Kdarray_clear == nil {
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

    KAPI.KAPI_lib = lib
    return true
}

unload_kohi_api :: proc() {
    KAPI.KASSERT = nil
    KAPI.KASSERT_MSG = nil
    KAPI.KASSERT_DEBUG = nil
    KAPI.KFATAL = nil
    KAPI.KERROR = nil
    KAPI.KDEBUG = nil
    KAPI.KINFO = nil
    KAPI.KWARN = nil
    KAPI.KTRACE = nil
    KAPI.Kapplication_create = nil
    KAPI.Kapplication_run = nil
    KAPI.Kinitialize_memory = nil
    KAPI.Kshutdown_memory = nil
    KAPI.Kallocate = nil
    KAPI.Kfree = nil
    KAPI.Kcopy_memory = nil
    KAPI.Kzero_memory = nil
    KAPI.Kset_memory = nil
    KAPI.Kget_memory_usage_str = nil
    KAPI.Kstring_length = nil
    KAPI.Kstring16_length = nil
    KAPI.Kcstring_length = nil
    KAPI.Kcstring16_length = nil
    KAPI.Kstring_duplicate = nil
    KAPI.Kcstring_duplicate = nil
    KAPI.Kstring16_duplicate = nil
    KAPI.Kcstring16_duplicate = nil
    KAPI.Kstring_equals = nil
    KAPI.Kcstring_equals = nil
    KAPI.Kstring16_equals = nil
    KAPI.Kcstring16_equals = nil
    KAPI.Kto_wstring = nil
    KAPI.Kfrom_wstring = nil
    KAPI.Kbytes_to_cstring = nil
    KAPI.Kevent_register = nil
    KAPI.Kevent_unregister = nil
    KAPI.Kevent_fire = nil
    KAPI.Kis_key_down = nil
    KAPI.Kis_key_up = nil
    KAPI.Kwas_key_down = nil
    KAPI.Kwas_key_up = nil
    KAPI.Kis_button_down = nil
    KAPI.Kis_button_up = nil
    KAPI.Kwas_button_down = nil
    KAPI.Kwas_button_up = nil
    KAPI.Kget_mouse_position = nil
    KAPI.Kget_previous_mouse_position = nil
    KAPI.Kdarray_make = nil
    KAPI.Kdarray_delete = nil
    KAPI.Kdarray_resize = nil
    KAPI.Kdarray_reserve = nil
    KAPI.Kdarray_push = nil
    KAPI.Kdarray_pop = nil
    KAPI.Kdarray_insert_at = nil
    KAPI.Kdarray_pop_at = nil
    KAPI.Kdarray_clear = nil
    KAPI.Kdarray_set_len = nil
    KAPI.KAPI_VERSION = 0
    KAPI.KENGINE_VERSION = 0

    if KAPI.KAPI_lib != nil {
        dynlib.unload_library(KAPI.KAPI_lib)
        KAPI.KAPI_lib = nil
    }
}
*/