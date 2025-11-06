package darray

import fmt "core:fmt"
import types "../../types"
import mem "core:mem"
import memory "../../core/memory"
import logger "../../core/logger"
import math "core:math"
import runtime "base:runtime"

DEFAULT_DARRAY_CAPACITY :: 8
DARRAY_RESIZE_FACTOR :: 16


@(private="file")
_darray_make :: proc($T: typeid) -> [dynamic]T {
    array, err :=  make([dynamic]T,0,DEFAULT_DARRAY_CAPACITY)
    if err != runtime.Allocator_Error.None {
        logger.ERROR("DArray make failed: Unable to create array of type %v", typeid_of(T))
        logger.ERROR("Allocator error: %v", fmt.enum_value_to_string(err))
        return nil
    }
    memory.stats.total_allocated += (DEFAULT_DARRAY_CAPACITY * size_of(T)) + size_of([dynamic]T)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += (DEFAULT_DARRAY_CAPACITY * size_of(T)) + size_of([dynamic]T)
    return array
}

@(private="file")
_darray_reserve :: proc(array: ^[dynamic]$T) -> (ok: bool) {
    new_capacity: u64 = cast(u64)cap(array) + DARRAY_RESIZE_FACTOR
    err := reserve(&array, new_capacity)
    if err != Allocator_error.None {
        logger.ERROR("DArray reserve failed: Unable to reserve array of type %v", typeid_of(T))
        logger.ERROR("Allocator error: %v", fmt.enum_value_to_string(err))
        return false
    }
    memory.stats.total_allocated += DARRAY_RESIZE_FACTOR * size_of(T)
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += DARRAY_RESIZE_FACTOR * size_of(T)
    return true
}

@(private="file")
_darray_push :: proc(array: ^[dynamic]$T, value: T) ->  bool {
    start_len := len(array)
    start_cap := cap(array)
    err := append(array, value)
    if err != 0 {
        logger.ERROR("DArray push failed: Unable to append to array of type %v", typeid_of(T))
        err_val, _ := fmt.enum_value_to_string(err)
        logger.ERROR("Allocator error: %v", err_val)
        return false
    }

    if cap(array) > start_cap {
        // Capacity increased, update stats
        memory.stats.total_allocated += cast(u64)((cap(array) - start_cap) * size_of(T))
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)((cap(array) - start_cap) * size_of(T))
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)(size_of(T))
    } else {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)(size_of(T))
    }

    return true
}

@(private="file")
_darray_pop :: proc(array: ^[dynamic]$T) -> T {
    if len(array) == 0 {
        logger.ERROR("DArray pop failed: Array is empty")
        return T{}
    }
    ret_val := pop(array)
    return ret_val
}

@(private="file")
_darray_pop_at :: proc(array: ^[dynamic]$T, index: u64) -> T {
    if len(array) == 0 {
        logger.ERROR("DArray pop_at failed: Array is empty")
        return T{}
    }
    if (index >= cast(u64)len(array)) {
        logger.ERROR("DArray pop_at failed: Index (%d) out of bounds (length: %d)", index, len(array))
        return T{}
    }
    temp := array[index]
    ordered_remove(array, index)

    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= size_of(T)
    return temp
}

@(private="file")
_darray_insert_at :: proc(array: ^[dynamic]$T, index: u64, value: T) -> bool {
    start_cap := cap(array)
    if index >= len(array) {
        logger.ERROR("Index out of bounds of this array. Index: %d, Length: %d", index, len(array))
        return false
    }

    ok, err := inject_at(&array, index, value)
    if !ok {
        logger.ERROR("DArray insert_at failed: Unable to insert into array of type %v", typeid_of(T))
        err_val, _ := fmt.enum_value_to_string(err)
        logger.ERROR("Allocator error: %v", err_val)
        return ok
    }

    if cap(array) > start_cap {
        // Capacity increased, update stats
        memory.stats.total_allocated += (cap(array) - start_cap) * size_of(T)
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += (cap(array) - start_cap) * size_of(T)
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += size_of(T)
    } else {
        memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += size_of(T)
    }
    return ok
}

@(private="file")
_delete_DArray :: proc(array: ^[dynamic]$T) {
    array := array
    size: u64 = u64(cap(array) * size_of(T))
    used: u64 = u64(len(array) * size_of(T))
    if array == nil {
        return
    }
    err := delete(array^)
    if err != runtime.Allocator_Error.None {
        logger.FATAL("Kdelete failed to free DArray of type %v", typeid_of(T))
        return
    }
    memory.stats.total_allocated -= size
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] -= size
    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= used

}

Make :: proc($T: typeid) -> [dynamic]T {
    return _darray_make(T)
}

Reserve :: proc(array: ^[dynamic]$T) -> bool {
    return _darray_reserve(array)
}

destroy :: proc(array: ^[dynamic]$T) {
    _delete_DArray(array)
}

push :: proc(array: ^[dynamic]$T, value: T) -> bool {
    return _darray_push(array, value)
}

pop :: proc(array: ^[dynamic]$T) -> T {
    return _darray_pop(array)
}

insert_at :: proc(array: ^[dynamic]$T, index: u64, value: T) -> bool {
    return _darray_insert_at(array, index, value)
}

pop_at :: proc(array: ^[dynamic]$T, index: u64) -> T {
    return _darray_pop_at(array, index)
}

clear :: proc(array: ^[dynamic]$T) {
    orig_len := len(array)
    if orig_len == 0 {
        return
    }
    clear(array)

    memory.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= cast(u64)(orig_len * size_of(T))
}