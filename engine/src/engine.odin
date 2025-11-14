#+private
package engine

import runtime "base:runtime"
import app "./core/application"
import types "./types"
import log "./core/logger"
import mem "./core/memory"
import clock "./core/clock"
import ass "./core/asserts"
import event "./core/event"
import inp "./core/input"
import engine_string "./core/string"
import darray "./containers/darray"

@(export)
KASSERT :: proc(cond: bool, expr: string = #caller_expression(cond), loc: runtime.Source_Code_Location){
    ass.ASSERT(cond, expr, loc)
}

@(export)
KASSERT_MSG :: proc(cond: bool, message: string, expr: string = #caller_expression(cond), loc: runtime.Source_Code_Location){
    ass.ASSERT_MSG(cond, message, expr, loc)
}

@(export)
KASSERT_DEBUG :: proc(cond: bool, expr: string = #caller_expression(cond), loc: runtime.Source_Code_Location){
    ass.ASSERT_DEBUG(cond, expr, loc)
}

// logging
@(export)
KFATAL :: proc(message: string, args: ..any){
    log.FATAL(message, ..args)
}

@(export)
KERROR :: proc(message: string, args: ..any){
    log.ERROR(message, ..args)
}

@(export)
KWARN :: proc(message: string, args: ..any){
    log.WARN(message, ..args)
}

@(export)
KINFO :: proc(message: string, args: ..any){
    log.INFO(message, ..args)
}

@(export)
KDEBUG :: proc(message: string, args: ..any){
    log.DEBUG(message, ..args)
}

@(export)
KTRACE :: proc(message: string, args: ..any){
    log.TRACE(message, ..args)
}

// application
@(export)
Kapplication_create :: proc(game_inst: rawptr) -> b8 {
    return app.create(cast(^types.game)game_inst)
}

@(export)
Kapplication_run :: proc() -> b8 {
    return app.run()
}
// memory management
@(export)
Kinitialize_memory :: proc(){
    mem.initialize()
}

@(export)
Kshutdown_memory :: proc(){
    mem.shutdown()
}

@(export)
Kallocate :: proc(size: u64, tag: types.memory_tag) -> rawptr {
    return mem.Allocate(size, tag)
}

@(export)
Kfree :: proc(ptr: rawptr, size: u64, tag: types.memory_tag){
    mem.Free(ptr, size, tag)
}

@(export)
Kzero_memory :: proc(ptr: rawptr, size: u64) -> rawptr {
    return mem.zero_memory(ptr, size)
}

@(export)
Kcopy_memory :: proc(dest: rawptr, src: rawptr, size: u64) -> rawptr {
    return mem.copy_memory(dest, src, size)
}

@(export)
Kset_memory :: proc(ptr: rawptr, value: i32, size: u64) -> rawptr {
    return mem.set_memory(ptr, value, size)
}

when ODIN_DEBUG {
    @(export)
    Kget_memory_usage_str :: proc() -> string {
        return mem.get_memory_usage_str()
    }
}
    
// strings
@(export)
Kstring_length :: proc(str: string) -> u64 {
    return engine_string.length(str)
}

@(export)
Kstring_duplicate :: proc(str: string) -> string {
    return engine_string.duplicate(str)
}

// event system
@(export)
Kevent_register :: proc(event_type: u16, handler: rawptr, callback: types.PFN_on_event) -> b8 {
    return event.register(event_type, handler, callback)
}

@(export)
Kevent_unregister :: proc(event_type: u16, handler: rawptr, callback: types.PFN_on_event) -> b8 {
    return event.unregister(event_type, handler, callback)
}

@(export)
Kevent_fire :: proc(event_type: u16, data: rawptr, e_context: types.event_context) -> b8 {
    return event.fire(event_type, data, e_context)
}

// input system
@(export)
Kis_key_down :: proc(key: types.keys) -> b8{
    return inp.is_key_down(key)
}
@(export)
Kis_key_up :: proc(key: types.keys) -> b8{
    return inp.is_key_up(key)
}
@(export)
Kwas_key_down :: proc(key: types.keys) -> b8{
    return inp.was_key_down(key)
}
@(export)
Kwas_key_up :: proc(key: types.keys) -> b8{
    return inp.was_key_up(key)
}
@(export)
Kis_button_down :: proc(button: types.buttons) -> b8{
    return inp.is_button_down(button)
}
@(export)
Kis_button_up :: proc(button: types.buttons) -> b8{
    return inp.is_button_up(button)
}
@(export)
Kwas_button_down :: proc(button: types.buttons) -> b8{
    return inp.was_button_down(button)
}
@(export)
Kwas_button_up :: proc(button: types.buttons) -> b8{
    return inp.was_button_up(button)
}
@(export)
Kget_mouse_position :: proc(x: ^i32, y: ^i32){
    inp.get_mouse_position(x,y)
}
@(export)
Kget_previous_mouse_position :: proc(x: ^i32, y: ^i32){
    inp.get_previous_mouse_position(x,y)
}

@(export)
Kdarray_make :: proc(type: typeid) -> rawptr {
    return darray.Make(type)
}

@(export)
Kdarray_reserve :: proc(array: rawptr, type: typeid, capacity: u64) -> bool {
    return darray.Reserve(array, type, capacity)
}

@(export)
Kdarray_delete :: proc(array: rawptr, type: typeid) {
    darray.Delete(array, type)
}

@(export)
Kdarray_push :: proc(array: rawptr, type: typeid, value: rawptr) -> bool {
    return darray.push(array, type, value)
}

@(export)
Kdarray_pop :: proc(array: rawptr, type: typeid, out_value: rawptr) -> bool {
    return darray.pop(array, type, out_value)
}

@(export)
Kdarray_insert_at :: proc(array: rawptr, type: typeid, index: u64, value: rawptr) -> bool {
    return darray.insert_at(array, type, index, value)
}

@(export)
Kdarray_pop_at :: proc(array: rawptr, type: typeid, index: u64, out_value: rawptr) -> bool {
    return darray.pop_at(array, type, index, out_value)
}

@(export)
Kdarray_clear :: proc(array: rawptr, type: typeid) {
    darray.Clear(array, type)
}

@(export)
Kdarray_resize :: proc(array: rawptr, type: typeid, new_length: u64) {
    darray.Resize(array, type, new_length)
}

@(export)
Kdarray_set_len :: proc(array: rawptr, type: typeid, new_len: u64) {
    darray.set_len(array, type, new_len)
}

// Version variables
@(export)
KAPI_VERSION : u64 = 1 << 48 | 0 << 32 | 0 << 16 | 0 // major | minor | patch | build
@(export)
KENGINE_VERSION : u64 = 0 << 48 | 0 << 32 | 0 << 16 | 1 // major | minor | patch | build