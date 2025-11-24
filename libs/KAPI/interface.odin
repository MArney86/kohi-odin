package Kohi_API

import "core:c"
import runtime "base:runtime"
import types "../../engine/src/types"

//assertions
ASSERT :: proc(condition: bool, message: string = #caller_expression(condition), loc: runtime.Source_Code_Location = #caller_location) {
    KAPI.core.asserts.ASSERT(condition, message, loc)
}

ASSERT_MSG :: proc(condition: bool, message: string, expr: string = #caller_expression(condition), loc: runtime.Source_Code_Location = #caller_location) {
    KAPI.core.asserts.ASSERT_MSG(condition, message, expr, loc)
}

ASSERT_DEBUG :: proc(condition: bool, message: string = #caller_expression(condition), loc: runtime.Source_Code_Location = #caller_location) {
    KAPI.core.asserts.ASSERT_DEBUG(condition, message, loc)
}

// logging
FATAL :: proc(message: string, args: ..any) {
    KAPI.core.log.FATAL(message, ..args)
}

ERROR :: proc(message: string, args: ..any) {
    KAPI.core.log.ERROR(message, ..args)
}

WARN :: proc(message: string, args: ..any) {
    KAPI.core.log.WARN(message, ..args)
}

INFO :: proc(message: string, args: ..any) {
    KAPI.core.log.INFO(message, ..args)
}

DEBUG :: proc(message: string, args: ..any) {
    KAPI.core.log.DEBUG(message, ..args)
}

TRACE :: proc(message: string, args: ..any) {
    KAPI.core.log.TRACE(message, ..args)
}

// application layer
application_create :: proc(game_instance: rawptr) -> bool {
    return KAPI.core.app.application_create(cast(^game)game_instance)
}
application_run :: proc() -> bool {
    return KAPI.core.app.application_run()
}

// memory management
initialize_memory :: proc() {
    KAPI.core.mem.initialize_memory()
}

shutdown_memory :: proc() {
    KAPI.core.mem.shutdown_memory()
}

allocate :: proc(size: u64, tag: memory_tag) -> rawptr {
    return KAPI.core.mem.allocate(size, tag)
}

free :: proc(ptr: rawptr, size: u64, tag: memory_tag) {
    KAPI.core.mem.free(ptr, size, tag)
}

zero :: proc(ptr: rawptr, size: u64) -> rawptr {
    return KAPI.core.mem.zero_memory(ptr, size)
}

copy :: proc(dest: rawptr, src: rawptr, size: u64) -> rawptr {
    return KAPI.core.mem.copy_memory(dest, src, size)
}

set :: proc(dest: rawptr, value: i32, size: u64) -> rawptr {
    return KAPI.core.mem.set_memory(dest, value, size)
}

when ODIN_DEBUG {
    get_memory_usage_str :: proc() -> string {
        return KAPI.core.mem.get_memory_usage_str()
    }
}

// strings
string_length :: proc(str: string) -> u64 {
    return KAPI.core.str.string_length(str)
}
cstring_length :: proc(cstr: cstring) -> u64 {
    return KAPI.core.str.cstring_length(cstr)
}
string16_length :: proc(str: string16) -> u64 {
    return KAPI.core.str.string16_length(str)
}
cstring16_length :: proc(cstr: cstring16) -> u64 {
    return KAPI.core.str.cstring16_length(cstr)
}
string_copy :: proc(a: string) -> string {
    return KAPI.core.str.string_duplicate(a)
}
cstring_copy :: proc(a: cstring) -> cstring {
    return KAPI.core.str.cstring_duplicate(a)
}
string16_copy :: proc(a: string16) -> string16 {
    return KAPI.core.str.string16_duplicate(a)
}
cstring16_copy :: proc(a: cstring16) -> cstring16 {
    return KAPI.core.str.cstring16_duplicate(a)
}
string_equals :: proc(str_a: string, str_b: string) -> bool {
    return KAPI.core.str.string_equal(str_a, str_b)
}
cstring_equals :: proc(cstr_a: cstring, cstr_b: cstring) -> bool {
    return KAPI.core.str.cstring_equal(cstr_a, cstr_b)
}
string16_equals :: proc(str_a: string16, str_b: string16) -> bool {
    return KAPI.core.str.string16_equal(str_a, str_b)
}
cstring16_equals :: proc(cstr_a: cstring16, cstr_b: cstring16) -> bool {
    return KAPI.core.str.cstring16_equal(cstr_a, cstr_b)
}
to_wstring :: proc(str: string) -> cstring16 {
    return KAPI.core.str.to_wstring(str)
}
from_wstring :: proc(wstr: cstring16) -> string {
    return KAPI.core.str.from_wstring(wstr)
}
bytes_to_cstring :: proc(bytes: []u8) -> cstring {
    return KAPI.core.str.bytes_to_cstring(bytes)
}
strs_len :: proc{
    string_length,
    cstring_length,
    string16_length,
    cstring16_length,
}
strs_copy :: proc{
    string_copy,
    cstring_copy,
    string16_copy,
    cstring16_copy,
}
strs_equals :: proc{
    string_equals,
    cstring_equals,
    string16_equals,
    cstring16_equals,
}

// events
event_register :: proc(event_type: u16, handler: rawptr, callback: PFN_on_event) -> bool {
    return KAPI.core.event.event_register(event_type, handler, callback)
}
event_unregister :: proc(event_type: u16, handler: rawptr, callback: PFN_on_event) -> bool {
    return KAPI.core.event.event_unregister(event_type, handler, callback)
}
event_fire :: proc(event_type: u16, data: rawptr, e_context: event_context) -> bool {
    return KAPI.core.event.event_fire(event_type, data, e_context)
}

// input
is_key_down :: proc(key_code: keys) -> bool {
    return KAPI.core.input.is_key_down(key_code)
}
is_key_up :: proc(key_code: keys) -> bool {
    return KAPI.core.input.is_key_up(key_code)
}
was_key_down :: proc(key_code: keys) -> bool {
    return KAPI.core.input.was_key_down(key_code)
}
was_key_up :: proc(key_code: keys) -> bool {
    return KAPI.core.input.was_key_up(key_code)
}
is_button_down :: proc(button: buttons) -> bool {
    return KAPI.core.input.is_button_down(button)
}
is_button_up :: proc(button: buttons) -> bool {
    return KAPI.core.input.is_button_up(button)
}
was_button_down :: proc(button: buttons) -> bool {
    return KAPI.core.input.was_button_down(button)
}
was_button_up :: proc(button: buttons) -> bool {
    return KAPI.core.input.was_button_up(button)
}
get_mouse_position :: proc(x: ^i32, y: ^i32) {
    KAPI.core.input.get_mouse_position(x, y)
}
get_previous_mouse_position :: proc(x: ^i32, y: ^i32) {
    KAPI.core.input.get_previous_mouse_position(x, y)
}

// dynamic array container
darray_make :: proc($T: typeid) -> [dynamic]T {
    output := cast(^[dynamic]T)KAPI.containers.darray.make(typeid_of(T))
    return output^
}

darray_reserve :: proc(array: ^[dynamic]$T, capacity: u64) -> bool {
    return KAPI.containers.darray.reserve(array, typeid_of(T), capacity)
}

darray_delete :: proc(array: ^[dynamic]$T) {
    KAPI.containers.darray.delete(array, typeid_of(T))
}

darray_push :: proc(array: ^[dynamic]$T, value: T) -> bool {
    val := value
    return KAPI.containers.darray.push(cast(rawptr)array, typeid_of(T), &val)
}

darray_pop :: proc(array: ^[dynamic]$T) -> T {
    out: T
    if KAPI.containers.darray.pop(cast(rawptr)array, typeid_of(T), cast(rawptr)&out) {
        return out
    } else {
        return T{}
    }
}

darray_set_len :: proc(array: ^[dynamic]$T, length: u64) -> bool {
    return KAPI.containers.darray.set_len(cast(rawptr)array, typeid_of(T), length)
}

darray_clear :: proc(array: ^[dynamic]$T) {
    KAPI.containers.darray.clear(cast(rawptr)array, typeid_of(T))
}

darray_resize :: proc(array: ^[dynamic]$T, new_length: u64) {
    KAPI.containers.darray.resize(cast(rawptr)array, typeid_of(T), new_length)
}

darray_insert_at :: proc(array: ^[dynamic]$T, index: u64, value: T) -> bool {
    val := value
    return KAPI.containers.darray.insert_at(cast(rawptr)array, typeid_of(T), index, &val)
}

darray_pop_at :: proc(array: ^[dynamic]$T, index: u64) -> T {
    out: T
    if KAPI.containers.darray.pop_at(cast(rawptr)array, typeid_of(T), index, cast(rawptr)&out) {
        return out
    } else {
        return T{}
    }
}

initialize_kohi_api :: proc() -> bool {
    return load_kohi_api()
}

shutdown_kohi_api :: proc() {
    shutdown()
}
