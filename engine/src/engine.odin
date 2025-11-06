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

@(export)
KASSERT :: proc(expression: string, loc: runtime.Source_Code_Location){
    ass.ASSERT(expression, loc)
}

@(export)
KASSERT_MSG :: proc(expression: string, message: string, loc: runtime.Source_Code_Location){
    ass.ASSERT_MSG(expression, message, loc)
}

@(export)
KASSERT_DEBUG :: proc(expression: string, loc: runtime.Source_Code_Location){
    ass.ASSERT_DEBUG(expression, loc)
}

// logging
@(export)
KFATAL :: proc(message: string, args: ..any){
    log.FATAL(message, args)
}

@(export)
KERROR :: proc(message: string, args: ..any){
    log.ERROR(message, args)
}

@(export)
KWARN :: proc(message: string, args: ..any){
    log.WARN(message, args)
}

@(export)
KINFO :: proc(message: string, args: ..any){
    log.INFO(message, args)
}

@(export)
KDEBUG :: proc(message: string, args: ..any){
    log.DEBUG(message, args)
}

@(export)
KTRACE :: proc(message: string, args: ..any){
    log.TRACE(message, args)
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

@(export)
Kget_memory_usage_str :: proc() -> string {
    return mem.get_memory_usage_str()
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

    // Version variables
@(export)
KAPI_VERSION : u64 = 1 << 48 | 0 << 32 | 0 << 16 | 0 // major | minor | patch | build
@(export)
KENGINE_VERSION : u64 = 0 << 48 | 0 << 32 | 0 << 16 | 1 // major | minor | patch | build