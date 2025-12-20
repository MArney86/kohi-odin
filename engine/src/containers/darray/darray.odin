package darray

import fmt "core:fmt"
import types "../../types"
import mem "core:mem"
import memory "../../core/memory"
import logger "../../core/logger"
import runtime "base:runtime"
import builtin "base:builtin"

// Simplified darray - wrapper around Odin's built-in [dynamic]T

// Generic version - preferred
make :: proc{make_generic, make_typeid}
reserve :: proc{reserve_generic, reserve_typeid}
push :: proc{push_generic, push_typeid}
pop :: proc{pop_generic, pop_typeid}
pop_at :: proc{pop_at_generic, pop_at_typeid}
insert_at :: proc{insert_at_generic, insert_at_typeid}
delete :: proc{delete_generic, delete_typeid}
clear :: proc{clear_generic, clear_typeid}
resize :: proc{resize_generic, resize_typeid}
set_len :: proc{set_len_generic, set_len_typeid}

// Generic procedures (new style)
make_generic :: proc($T: typeid) -> ^[dynamic]T {
    array := new([dynamic]T)
    if array == nil {
        logger.ERROR("DArray make failed: Unable to allocate dynamic array of type %v", typeid_of(T))
        return nil
    }
    
    memory.stats.total_allocated += cast(u64)size_of([dynamic]T)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)size_of([dynamic]T)
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return array
}

reserve_generic :: proc(array: ^[dynamic]$T, capacity: u64) -> bool {
    if array == nil {
        logger.ERROR("DArray reserve failed: Array is nil")
        return false
    }
    
    if cast(u64)cap(array^) >= capacity {
        logger.DEBUG("DArray reserve: Current capacity (%d) is already sufficient for requested capacity (%d). No action taken.", cap(array^), capacity)
        return true
    }
    
    old_cap := cap(array^)
    builtin_reserve :: builtin.reserve
    err := builtin_reserve(array, cast(int)capacity)
    if err != nil {
        logger.ERROR("DArray reserve failed: Unable to reserve capacity %d", capacity)
        logger.ERROR("Allocator error: %v", err)
        return false
    }
    
    new_cap := cap(array^)
    elem_size := size_of(T)
    memory.stats.total_allocated += cast(u64)((new_cap - old_cap) * elem_size)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)((new_cap - old_cap) * elem_size)
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    logger.DEBUG("DArray reserve: Successfully reserved capacity of %d.", new_cap)
    return true
}

push_generic :: proc(array: ^[dynamic]$T, value: T) -> bool {
    if array == nil {
        logger.ERROR("DArray push failed: Array is nil")
        return false
    }
    
    append(array, value)
    
    elem_size := size_of(T)
    memory.stats.total_allocated += cast(u64)elem_size
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)elem_size
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return true
}

pop_generic :: proc(array: ^[dynamic]$T) -> (T, bool) {
    if array == nil {
        logger.ERROR("DArray pop failed: Array is nil")
        return {}, false
    }
    
    if len(array^) == 0 {
        logger.ERROR("DArray pop failed: Array is empty")
        return {}, false
    }
    
    builtin_pop :: builtin.pop
    value := builtin_pop(array)
    
    elem_size := size_of(T)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)elem_size
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return value, true
}

pop_at_generic :: proc(array: ^[dynamic]$T, index: u64) -> (T, bool) {
    if array == nil {
        logger.ERROR("DArray pop_at failed: Array is nil")
        return {}, false
    }
    
    if len(array^) == 0 {
        logger.ERROR("DArray pop_at failed: Array is empty")
        return {}, false
    }
    
    if cast(int)index >= len(array^) {
        logger.ERROR("DArray pop_at failed: Index (%d) out of bounds (length: %d)", index, len(array^))
        return {}, false
    }
    
    value := ordered_remove(array, cast(int)index)
    
    elem_size := size_of(T)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)elem_size
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return value, true
}

insert_at_generic :: proc(array: ^[dynamic]$T, index: u64, value: T) -> bool {
    if array == nil {
        logger.ERROR("DArray insert_at failed: Array is nil")
        return false
    }
    
    if cast(int)index > len(array^) {
        logger.ERROR("Index out of bounds of this array. Index: %d, Length: %d", index, len(array^))
        return false
    }
    
    inject_at(array, cast(int)index, value)
    
    elem_size := size_of(T)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)elem_size
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return true
}

delete_generic :: proc(array: ^[dynamic]$T) {
    if array == nil {
        return
    }
    
    element_size := size_of(T)
    size := cast(u64)(cap(array^) * element_size)
    used := cast(u64)(len(array^) * element_size)
    
    builtin_delete :: builtin.delete
    builtin_delete(array^)
    free(array)
    
    memory.stats.total_allocated -= size + size_of([dynamic]T)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] -= size + cast(u64)size_of([dynamic]T)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= used
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
}

clear_generic :: proc(array: ^[dynamic]$T) {
    if array == nil {
        return
    }
    
    elem_size := size_of(T)
    orig_len := len(array^)
    if orig_len == 0 {
        return
    }
    
    builtin_clear :: builtin.clear
    builtin_clear(array)
    
    memory.stats.tagged_allocations[types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)(orig_len * elem_size)
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
}

resize_generic :: proc(array: ^[dynamic]$T, new_size: u64) {
    if array == nil {
        return
    }
    
    elem_size := size_of(T)
    old_len := len(array^)
    old_cap := cap(array^)
    
    builtin_resize :: builtin.resize
    builtin_resize(array, cast(int)new_size)
    
    new_len := len(array^)
    new_cap := cap(array^)
    
    if new_cap > old_cap {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)((new_cap - old_cap) * elem_size)
        memory.stats.total_allocated += cast(u64)((new_cap - old_cap) * elem_size)
    } else if new_cap < old_cap {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] -= cast(u64)((old_cap - new_cap) * elem_size)
        memory.stats.total_allocated -= cast(u64)((old_cap - new_cap) * elem_size)
    }
    
    if new_len > old_len {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)((new_len - old_len) * elem_size)
    } else if new_len < old_len {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)((old_len - new_len) * elem_size)
    }
    
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
}

set_len_generic :: proc(array: ^[dynamic]$T, new_len: u64) {
    if array == nil {
        return
    }
    
    elem_size := size_of(T)
    old_len := len(array^)
    
    if cast(int)new_len > cap(array^) {
        logger.ERROR("DArray set_len failed: New length (%d) exceeds capacity (%d)", new_len, cap(array^))
        return
    }
    
    // Manually set length using raw dynamic array
    raw := cast(^runtime.Raw_Dynamic_Array)array
    raw.len = cast(int)new_len
    
    if new_len > cast(u64)old_len {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)((cast(int)new_len - old_len) * elem_size)
    } else {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)((old_len - cast(int)new_len) * elem_size)
    }
    
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
}

// Typeid-based procedures (backwards compatibility)
make_typeid :: proc(type: typeid) -> rawptr {
    ti := type_info_of(type)
    
    // Create using runtime Raw_Dynamic_Array
    array := new(runtime.Raw_Dynamic_Array)
    if array == nil {
        logger.ERROR("DArray make failed: Unable to allocate dynamic array of type %v", type)
        return nil
    }
    
    array^ = runtime.Raw_Dynamic_Array{
        data = nil,
        len = 0,
        cap = 0,
        allocator = context.allocator,
    }
    
    memory.stats.total_allocated += cast(u64)size_of([dynamic]u8)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)size_of([dynamic]u8)
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return array
}

reserve_typeid :: proc(array: rawptr, type: typeid, capacity: u64) -> bool {
    if array == nil {
        logger.ERROR("DArray reserve failed: Array is nil")
        return false
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    
    if cast(u64)raw.cap >= capacity {
        logger.DEBUG("DArray reserve: Current capacity (%d) is already sufficient for requested capacity (%d). No action taken.", raw.cap, capacity)
        return true
    }
    
    old_cap := raw.cap
    new_cap := cast(int)capacity
    
    new_data, err := mem.alloc(new_cap * elem_size, ti.align)
    if err != .None {
        logger.ERROR("DArray reserve failed: Unable to allocate %d bytes", new_cap * elem_size)
        return false
    }
    
    // Copy existing data
    if raw.data != nil && raw.len > 0 {
        mem.copy_non_overlapping(new_data, raw.data, raw.len * elem_size)
        mem.free(raw.data)
    }
    
    raw.data = new_data
    raw.cap = new_cap
    
    memory.stats.total_allocated += cast(u64)((new_cap - old_cap) * elem_size)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)((new_cap - old_cap) * elem_size)
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    logger.DEBUG("DArray reserve: Successfully reserved capacity of %d.", new_cap)
    return true
}

push_typeid :: proc(array: rawptr, type: typeid, value: rawptr) -> bool {
    if array == nil || value == nil {
        logger.ERROR("DArray push failed: Array or value is nil")
        return false
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    
    // Auto-grow if needed
    if raw.len >= raw.cap {
        new_cap := raw.cap == 0 ? 8 : raw.cap * 2
        if !reserve_typeid(array, type, cast(u64)new_cap) {
            return false
        }
    }
    
    // Copy element
    dest := mem.ptr_offset(cast(^u8)raw.data, raw.len * elem_size)
    mem.copy_non_overlapping(dest, value, elem_size)
    raw.len += 1
    
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)elem_size
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return true
}

pop_typeid :: proc(array: rawptr, type: typeid, out_value: rawptr) -> bool {
    if array == nil || out_value == nil {
        logger.ERROR("DArray pop failed: Array or out_value is nil")
        return false
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    if raw.len == 0 {
        logger.ERROR("DArray pop failed: Array is empty")
        return false
    }
    
    raw.len -= 1
    src := mem.ptr_offset(cast(^u8)raw.data, raw.len * elem_size)
    mem.copy(out_value, src, elem_size)
    
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)elem_size
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return true
}

pop_at_typeid :: proc(array: rawptr, type: typeid, index: u64, out_value: rawptr) -> bool {
    if array == nil || out_value == nil {
        return false
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    if raw.len == 0 {
        logger.ERROR("DArray pop_at failed: Array is empty")
        return false
    }
    if cast(int)index >= raw.len {
        logger.ERROR("DArray pop_at failed: Index (%d) out of bounds (length: %d)", index, raw.len)
        return false
    }
    
    // Copy out the element
    src := mem.ptr_offset(cast(^u8)raw.data, cast(int)index * elem_size)
    mem.copy(out_value, src, elem_size)
    
    // Shift elements after index
    if cast(int)index < raw.len - 1 {
        dest := mem.ptr_offset(cast(^u8)raw.data, cast(int)index * elem_size)
        src = mem.ptr_offset(cast(^u8)raw.data, (cast(int)index + 1) * elem_size)
        mem.copy(dest, src, (raw.len - cast(int)index - 1) * elem_size)
    }
    
    raw.len -= 1
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)elem_size
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return true
}

insert_at_typeid :: proc(array: rawptr, type: typeid, index: u64, value: rawptr) -> bool {
    if array == nil || value == nil {
        logger.ERROR("DArray insert_at failed: Array or value is nil")
        return false
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    if cast(int)index > raw.len {
        logger.ERROR("Index out of bounds of this array. Index: %d, Length: %d", index, raw.len)
        return false
    }
    
    // Auto-grow if needed
    if raw.len >= raw.cap {
        new_cap := raw.cap == 0 ? 8 : raw.cap * 2
        if !reserve_typeid(array, type, cast(u64)new_cap) {
            return false
        }
    }
    
    // Shift elements after index
    if cast(int)index < raw.len {
        src := mem.ptr_offset(cast(^u8)raw.data, cast(int)index * elem_size)
        dest := mem.ptr_offset(cast(^u8)raw.data, (cast(int)index + 1) * elem_size)
        mem.copy(dest, src, (raw.len - cast(int)index) * elem_size)
    }
    
    // Insert the element
    dest := mem.ptr_offset(cast(^u8)raw.data, cast(int)index * elem_size)
    mem.copy(dest, value, elem_size)
    raw.len += 1
    
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)elem_size
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
    
    return true
}

delete_typeid :: proc(array: rawptr, type: typeid) {
    if array == nil {
        return
    }
    
    ti := type_info_of(type)
    element_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    size := cast(u64)(raw.cap * element_size)
    used := cast(u64)(raw.len * element_size)
    
    if raw.data != nil {
        mem.free(raw.data)
    }
    free(array)
    
    memory.stats.total_allocated -= size + size_of(runtime.Raw_Dynamic_Array)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] -= size + cast(u64)size_of(runtime.Raw_Dynamic_Array)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= used
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
}

clear_typeid :: proc(array: rawptr, type: typeid) {
    if array == nil {
        return
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    orig_len := raw.len
    if orig_len == 0 {
        return
    }
    
    raw.len = 0
    mem.zero(raw.data, orig_len * elem_size)
    
    memory.stats.tagged_allocations[types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)(orig_len * elem_size)
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
}

resize_typeid :: proc(array: rawptr, type: typeid, new_size: u64) {
    if array == nil {
        return
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    old_len := raw.len
    old_cap := raw.cap
    
    new_cap := cast(int)new_size
    new_len := min(old_len, new_cap)
    
    if new_cap == old_cap {
        raw.len = new_len
        return
    }
    
    new_data, err := mem.alloc(new_cap * elem_size, ti.align)
    if err != .None {
        logger.ERROR("DArray resize failed: Unable to allocate %d bytes", new_cap * elem_size)
        return
    }
    
    if raw.data != nil && new_len > 0 {
        mem.copy_non_overlapping(new_data, raw.data, new_len * elem_size)
        mem.free(raw.data)
    }
    
    raw.data = new_data
    raw.cap = new_cap
    raw.len = new_len
    
    if new_cap > old_cap {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)((new_cap - old_cap) * elem_size)
        memory.stats.total_allocated += cast(u64)((new_cap - old_cap) * elem_size)
    } else {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] -= cast(u64)((old_cap - new_cap) * elem_size)
        memory.stats.total_allocated -= cast(u64)((old_cap - new_cap) * elem_size)
    }
    
    if new_len > old_len {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)((new_len - old_len) * elem_size)
    } else if new_len < old_len {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)((old_len - new_len) * elem_size)
    }
    
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
}

set_len_typeid :: proc(array: rawptr, type: typeid, new_len: u64) {
    if array == nil {
        return
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    old_len := raw.len
    
    if cast(int)new_len > raw.cap {
        logger.ERROR("DArray set_len failed: New length (%d) exceeds capacity (%d)", new_len, raw.cap)
        return
    }
    
    raw.len = cast(int)new_len
    
    if new_len > cast(u64)old_len {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)((cast(int)new_len - old_len) * elem_size)
    } else {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)((old_len - cast(int)new_len) * elem_size)
    }
    
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
}