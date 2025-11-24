package darray

import "core:log"
import fmt "core:fmt"
import types "../../types"
import mem "core:mem"
import memory "../../core/memory"
import logger "../../core/logger"
import runtime "base:runtime"

DEFAULT_DARRAY_CAPACITY :: 8
LG_ELEM_DARRAY_DEFAULT_CAPACITY :: 3  // log2(8) = 3
DEFAULT_DARRAY_RESIZE_FACTOR :: 16
LG_ELEM_DARRAY_RESIZE_FACTOR :: 4  // log2(16) = 4

Make :: proc(type: typeid) -> rawptr {
    ti := type_info_of(type)
    elem_size := ti.size
    align := ti.align
    lg_elem: bool = false

    if elem_size > 65 {
        lg_elem = true
    }
    
    array := runtime.Raw_Dynamic_Array{
        data = nil,
        len = 0,
        cap = lg_elem ? LG_ELEM_DARRAY_DEFAULT_CAPACITY : DEFAULT_DARRAY_CAPACITY,
        allocator = context.allocator,
    }
    
    // Allocate memory for data of the array at default capacity
    data : rawptr
    err : mem.Allocator_Error
    data, err = mem.alloc((lg_elem ? LG_ELEM_DARRAY_DEFAULT_CAPACITY : DEFAULT_DARRAY_CAPACITY) * elem_size, align)
    if err != .None {
        logger.ERROR("DArray make failed: Unable to allocate array memory of type %v", type)
        logger.ERROR("Allocator error: %v", fmt.enum_value_to_string(err))
        return nil
    }
    array.data = data
    
    // Allocate wrapper for the array
    wrapper : rawptr
    wrapper, err = mem.alloc(size_of(mem.Raw_Dynamic_Array), align_of(mem.Raw_Dynamic_Array))
    if err != .None {
        logger.ERROR("DArray make failed: Unable to allocate array wrapper of type %v", type)
        logger.ERROR("Allocator error: %v", fmt.enum_value_to_string(err))  
        if array.data != nil {
            _ = mem.free(array.data)
        }
        return nil
    }
    
    result := cast(^mem.Raw_Dynamic_Array)wrapper
    result^ = array

    memory.stats.total_allocated += cast(u64)(cast(int)(lg_elem ? LG_ELEM_DARRAY_DEFAULT_CAPACITY : DEFAULT_DARRAY_CAPACITY) * elem_size + size_of(runtime.Raw_Dynamic_Array))
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)(cast(int)(lg_elem ? LG_ELEM_DARRAY_DEFAULT_CAPACITY : DEFAULT_DARRAY_CAPACITY) * elem_size + size_of(runtime.Raw_Dynamic_Array))
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)size_of(runtime.Raw_Dynamic_Array)
    when ODIN_DEBUG {
        memory.stats.updated = true
    }

    return wrapper
}


Reserve :: proc(array: rawptr, type: typeid, capacity: u64) -> bool {
    array := array
    ti := type_info_of(type)
    elem_size := ti.size
    align := ti.align
    lg_elem : bool = false
    if elem_size > 65 {
        lg_elem = true
    }
    raw : ^runtime.Raw_Dynamic_Array
    if array == nil {
        err: mem.Allocator_Error
        data: rawptr
        raw, err = new(runtime.Raw_Dynamic_Array)
        if err != .None {
            logger.ERROR("DArray reserve failed: Unable to allocate Raw_Dynamic_Array for type %v", type)
            logger.ERROR("Allocator error: %v", fmt.enum_value_to_string(err))
            return false
        }
        raw^ = runtime.Raw_Dynamic_Array{
            data = nil,
            len = 0,
            cap = cast(int)capacity,
            allocator = context.allocator,
        }

        data, err = mem.alloc(cast(int)capacity * elem_size, align)
        if err != .None {
            logger.ERROR("DArray reserve failed: Unable to allocate array data of capacity %d %v(s)", capacity, type)
            return false
        }
        raw.data = data
        array = cast(rawptr)raw
        memory.stats.total_allocated += cast(u64)(cast(int)capacity * elem_size + size_of(runtime.Raw_Dynamic_Array))
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)(cast(int)capacity * elem_size + size_of(runtime.Raw_Dynamic_Array))
        when ODIN_DEBUG {
            memory.stats.updated = true
        }
        return true
    } else {
        raw = cast(^runtime.Raw_Dynamic_Array)array
        new_cap: int
        if cast(u64)raw.cap >= capacity {
            logger.DEBUG("DArray reserve: Current capacity (%d) is already sufficient for requested capacity (%d). No action taken.", raw.cap, capacity)
            return true
        }
        
        if capacity != 0 && capacity > u64(raw.len) {
            new_cap = cast(int)capacity
        } else {
            logger.ERROR("DArray reserve failed: Requested capacity (%d) must be greater than current length (%d) and non-zero", capacity, raw.len)
            logger.ERROR("Please use Resize() to shrink arrays or clear() to reset.")
            return false
        }

        cap_diff := new_cap - raw.cap
        if cap_diff % (lg_elem ? LG_ELEM_DARRAY_RESIZE_FACTOR : DEFAULT_DARRAY_RESIZE_FACTOR) != 0 {
            new_cap += (lg_elem ? LG_ELEM_DARRAY_RESIZE_FACTOR : DEFAULT_DARRAY_RESIZE_FACTOR) - (cap_diff % (lg_elem ? LG_ELEM_DARRAY_RESIZE_FACTOR : DEFAULT_DARRAY_RESIZE_FACTOR))
            logger.DEBUG("DArray reserve: Adjusted requested capacity to %d to align with resize factor.", new_cap)
        }

        new_data, err := mem.alloc(cast(int)(new_cap * elem_size), align)
        if err != .None {
            logger.ERROR("DArray reserve failed: Unable to reserve new array.data of size %d Bytes", cast(int)(new_cap * elem_size))
            logger.ERROR("Allocator error: %v", fmt.enum_value_to_string(err))
            return false
        }

        memory.stats.total_allocated += cast(u64)((new_cap - raw.cap) * elem_size)
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)((new_cap - raw.cap) * elem_size)
        when ODIN_DEBUG {
            memory.stats.updated = true
        }

        raw.data = new_data
        raw.cap = new_cap
        logger.DEBUG("DArray reserve: Successfully reserved capacity of %d.", new_cap)
        return true
    }
}

push :: proc(array: rawptr, type: typeid, value: rawptr) ->  bool {
    if array == nil || value == nil {
        logger.ERROR("DArray push failed: Array or value is nil")
        when ODIN_DEBUG {
            if array == nil {
                logger.DEBUG("DArray push failed: Array ptr is nil")
            }
            if value == nil {
                logger.DEBUG("DArray push failed: Value ptr is nil")
            }
        }
        return false
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    lg_elem: bool = false
    if elem_size > 65 {
        lg_elem = true
    }
    
    raw := cast(^mem.Raw_Dynamic_Array)array
    
    // Check if we need to grow
    if raw.len >= raw.cap {
        new_cap := raw.cap + (lg_elem ? LG_ELEM_DARRAY_RESIZE_FACTOR : DEFAULT_DARRAY_RESIZE_FACTOR)
        if !Reserve(array, type, cast(u64)new_cap) {
            logger.ERROR("DArray push failed: Unable to reserve additional capacity")
            return false
        }
    }
    
    // Copy the element
    dest := mem.ptr_offset(cast(^u8)raw.data, raw.len * elem_size)
    mem.copy_non_overlapping(dest, value, elem_size)
    raw.len += 1

    memory.stats.total_allocated += cast(u64)(elem_size)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)elem_size
    return true
}

pop :: proc(array: rawptr, type: typeid, out_value: rawptr) -> bool {

    if array == nil || out_value == nil {
        logger.ERROR("DArray pop failed: Array or out_value is nil")
        when ODIN_DEBUG {
            if array == nil {
                logger.DEBUG("DArray pop failed: Array ptr is nil")
            }
            if out_value == nil {
                logger.DEBUG("DArray pop failed: Value ptr is nil")
            }
        }
        return false
    }
    
    ti := type_info_of(type)
    elem_size := ti.size

    raw := cast(^mem.Raw_Dynamic_Array)array
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

pop_at :: proc(array: rawptr, type: typeid, index: u64, out_value: rawptr) -> bool {
    if array == nil || out_value == nil {
        return false
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    
    raw := cast(^mem.Raw_Dynamic_Array)array
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

insert_at :: proc(array: rawptr, type: typeid, index: u64, value: rawptr) -> bool {

    if array == nil || value == nil {
        logger.ERROR("DArray insert_at failed: Array or value is nil")
        when ODIN_DEBUG {
            if array == nil {
                logger.DEBUG("DArray push failed: Array ptr is nil")
            }
            if value == nil {
                logger.DEBUG("DArray push failed: Value ptr is nil")
            }
        }
        return false
    }
    
    ti := type_info_of(type)
    elem_size := ti.size
    align := ti.align
    lg_elem: bool = false
    if elem_size > 65 {
        lg_elem = true
    }

    raw := cast(^mem.Raw_Dynamic_Array)array
    if cast(int)index > raw.len {
        logger.ERROR("Index out of bounds of this array. Index: %d, Length: %d", index, raw.len)
        return false
    }
    
    // Check if we need to grow
    if raw.len >= raw.cap {
        new_cap := raw.cap + (lg_elem ? LG_ELEM_DARRAY_RESIZE_FACTOR : DEFAULT_DARRAY_RESIZE_FACTOR)
        if !Reserve(array, type, cast(u64)new_cap) {
            logger.ERROR("DArray insert_at failed: Unable to reserve additional capacity")
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
Delete :: proc(array: rawptr, type: typeid) {
    if array == nil {
        return
    }
    
    ti := type_info_of(type)
    element_size := ti.size
    
    raw := cast(^runtime.Raw_Dynamic_Array)array
    size := cast(u64)(raw.cap * element_size)
    used := cast(u64)(raw.len * element_size)
    
    if raw.data != nil {
        err := mem.free(raw.data)
        if err != .None {
            logger.FATAL("Kdelete failed to free DArray data of type %v", type)
            return
        }
    }
    free_err := mem.free(array)
    if free_err != .None {
        logger.FATAL("Kdelete failed to free DArray of type %v", type)
        return
    }
    
    memory.stats.total_allocated -= size + size_of(runtime.Raw_Dynamic_Array)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] -= size + cast(u64)size_of(runtime.Raw_Dynamic_Array)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= used + cast(u64)size_of(runtime.Raw_Dynamic_Array)
    when ODIN_DEBUG {
        memory.stats.updated = true
    }
}

Clear :: proc(array: rawptr, type: typeid) {
    ti := type_info_of(type)
    elem_size := ti.size

    raw := cast(^runtime.Raw_Dynamic_Array)array
    orig_len := raw.len
    if orig_len == 0 {
        return
    }
    raw.len = 0
    mem.zero(raw.data, cast(int)(orig_len * elem_size))

    memory.stats.tagged_allocations[types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)(orig_len * elem_size)
}

Resize :: proc(array: rawptr, type: typeid, new_size: u64 = 0) {
    ti := type_info_of(type)
    elem_size := ti.size

    raw := cast(^runtime.Raw_Dynamic_Array)array
    actual_size := new_size
    if actual_size == 0 {
        actual_size = cast(u64)raw.len
    }
    
    new_len : u64
    new_cap := cast(u64)actual_size

    if raw.len > cast(int)actual_size {
        new_len = cast(u64)actual_size
    } else {
        new_len = cast(u64)raw.len
    }

    new_data, err := mem.alloc(cast(int)(new_cap * cast(u64)elem_size), ti.align)
    if err != .None {
        logger.ERROR("DArray resize failed: Unable to allocate new array data of size %d Bytes", actual_size * cast(u64)elem_size)
        logger.ERROR("Allocator error: %v", fmt.enum_value_to_string(err))
        return
    }
    copy_size := cast(int)new_len * elem_size
    mem.copy_non_overlapping(new_data, raw.data, copy_size)

    if cast(int)new_cap - raw.cap >= 0 {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += (new_cap - cast(u64)raw.cap) * cast(u64)elem_size
        memory.stats.total_allocated += (new_cap - cast(u64)raw.cap) * cast(u64)elem_size
    } else {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] -= (cast(u64)raw.cap - new_cap) * cast(u64)elem_size
        if new_len < cast(u64)raw.len {
            memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= (cast(u64)raw.len - new_len) * cast(u64)elem_size
        }
        memory.stats.total_allocated -= (cast(u64)raw.cap - new_cap) * cast(u64)elem_size
    }
    raw.data = new_data
    raw.cap = cast(int)new_cap
    raw.len = cast(int)new_len
}

set_len :: proc(array: rawptr, type: typeid, new_len: u64) {
    ti := type_info_of(type)
    elem_size := ti.size

    raw := cast(^runtime.Raw_Dynamic_Array)array
    if cast(int)new_len > raw.cap {
        logger.ERROR("DArray set_len failed: New length (%d) exceeds capacity (%d)", new_len, raw.cap)
        return
    }

    if cast(int)new_len < raw.len {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= (cast(u64)(raw.len - cast(int)new_len)) * cast(u64)elem_size
    } else {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += (cast(u64)(cast(int)new_len - raw.len)) * cast(u64)elem_size
    }
    raw.len = cast(int)new_len
}