package core

import fmt "core:fmt"
import types "../types"
import math "core:math"
import runtime "base:runtime"

DEFAULT_DARRAY_CAPACITY :: 8
DARRAY_RESIZE_FACTOR :: 16


@(private="file")
_darray_make :: proc($T: typeid) -> [dynamic]T {
    array, err :=  make([dynamic]T,0,DEFAULT_DARRAY_CAPACITY)
    if err != runtime.Allocator_Error.None {
        KERROR("DArray make failed: Unable to create array of type %v", typeid_of(T))
        KERROR("Allocator error: %v", fmt.enum_value_to_string(err))
        return nil
    }
    stats_memory.total_allocated += (DEFAULT_DARRAY_CAPACITY * size_of(T)) + size_of([dynamic]T)
    stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += (DEFAULT_DARRAY_CAPACITY * size_of(T)) + size_of([dynamic]T)
    return array
}

@(private="file")
_darray_reserve :: proc(array: ^[dynamic]$T) -> (ok: bool) {
    new_capacity: u64 = cast(u64)cap(array) + DARRAY_RESIZE_FACTOR
    err := reserve(&array, new_capacity)
    if err != Allocator_error.None {
        KERROR("DArray reserve failed: Unable to reserve array of type %v", typeid_of(T))
        KERROR("Allocator error: %v", err.enum_value_to_string())
        return FALSE
    }
    stats_memory.total_allocated += DARRAY_RESIZE_FACTOR * size_of(T)
    stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += DARRAY_RESIZE_FACTOR * size_of(T)
    return TRUE
}

@(private="file")
_darray_push :: proc(array: ^[dynamic]$T, value: T) ->  bool {
    start_len := len(array)
    start_cap := cap(array)
    err := append(array, value)
    if err != 0 {
        KERROR("DArray push failed: Unable to append to array of type %v", typeid_of(T))
        err_val, _ := fmt.enum_value_to_string(err)
        KERROR("Allocator error: %v", err_val)
        return FALSE
    }

    if cap(array) > start_cap {
        // Capacity increased, update stats
        stats_memory.total_allocated += cast(u64)((cap(array) - start_cap) * size_of(T))
        stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += cast(u64)((cap(array) - start_cap) * size_of(T))
        stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)(size_of(T))
    } else {
        stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += cast(u64)(size_of(T))
    }

    return TRUE
}

@(private="file")
_darray_pop :: proc(array: ^[dynamic]$T) -> T {
    if len(array) == 0 {
        KERROR("DArray pop failed: Array is empty")
        return T{}
    }
    ret_val := pop(array)
    return ret_val
}

@(private="file")
_darray_pop_at :: proc(array: ^[dynamic]$T, index: u64) -> T {
    if len(array) == 0 {
        KERROR("DArray pop_at failed: Array is empty")
        return T{}
    }
    if (index >= cast(u64)len(array)) {
        KERROR("DArray pop_at failed: Index (%d) out of bounds (length: %d)", index, len(array))
        return T{}
    }
    temp := array[index]
    ordered_remove(array, index)

    stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= size_of(T)
    return temp
}

@(private="file")
_darray_insert_at :: proc(array: ^[dynamic]$T, index: u64, value: T) -> bool {
    start_cap := cap(array)
    if index >= len(array) {
        KERROR("Index out of bounds of this array. Index: %d, Length: %d", index, len(array))
        return FALSE
    }

    ok, err := inject_at(&array, index, value)
    if !ok {
        KERROR("DArray insert_at failed: Unable to insert into array of type %v", typeid_of(T))
        err_val, _ := fmt.enum_value_to_string(err)
        KERROR("Allocator error: %v", err_val)
        return ok
    }

    if cap(array) > start_cap {
        // Capacity increased, update stats
        stats_memory.total_allocated += (cap(array) - start_cap) * size_of(T)
        stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY] += (cap(array) - start_cap) * size_of(T)
        stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += size_of(T)
    } else {
        stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] += size_of(T)
    }
    return ok
}

@(export)
Kdarray_make :: proc($T: typeid) -> [dynamic]T {
    return _darray_make(T)
}

@(export)
Kdarray_reserve :: proc(array: ^[dynamic]$T) -> bool {
    return _darray_reserve(&array)
}

@(export)
Kdarray_destroy :: proc(array: ^[dynamic]$T) {
    Kdelete(&array)
}

@(export)
Kdarray_push :: proc(array: ^[dynamic]$T, value: T) -> bool {
    return _darray_push(array, value)
}

@(export)
Kdarray_pop :: proc(array: ^[dynamic]$T) -> T {
    return _darray_pop(array)
}

@(export)
Kdarray_insert_at :: proc(array: ^[dynamic]$T, index: u64, value: T) -> bool {
    return _darray_insert_at(array, index, value)
}

@(export)
Kdarray_pop_at :: proc(array: ^[dynamic]$T, index: u64) -> T {
    return _darray_pop_at(array, index)
}

@(export)
Kdarray_clear :: proc(array: ^[dynamic]$T) {
    orig_len := len(array)
    if orig_len == 0 {
        return
    }
    clear(array)

    stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_DARRAY_USED] -= (u64(orig_len) * size_of(T))
}