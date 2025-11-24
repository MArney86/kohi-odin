package darray

i_make :: proc($T: typeid) -> [dynamic]T {
    output := cast(^[dynamic]T)Make(typeid_of(T))
    return output^
}

i_reserve :: proc(array: ^[dynamic]$T, capacity: u64) -> bool {
    return Reserve(array, typeid_of(T), capacity)
}

i_delete :: proc(array: ^[dynamic]$T) {
    Delete(array, typeid_of(T))
}

i_push :: proc(array: ^[dynamic]$T, value: T) -> bool {
    val := value
    return push(cast(rawptr)array, typeid_of(T), &val)
}

i_pop :: proc(array: ^[dynamic]$T) -> T {
    out: T
    if pop(cast(rawptr)array, typeid_of(T), cast(rawptr)&out) {
        return out
    } else {
        return T{}
    }
}

i_set_len :: proc(array: ^[dynamic]$T, length: u64) -> bool {
    return set_len(cast(rawptr)array, typeid_of(T), length)
}

i_clear :: proc(array: ^[dynamic]$T) {
    Clear(cast(rawptr)array, typeid_of(T))
}

i_resize :: proc(array: ^[dynamic]$T, new_length: u64) {
    Resize(cast(rawptr)array, typeid_of(T), new_length)
}

i_insert_at :: proc(array: ^[dynamic]$T, index: u64, value: T) -> bool {
    val := value
    return insert_at(cast(rawptr)array, typeid_of(T), index, &val)
}

i_pop_at :: proc(array: ^[dynamic]$T, index: u64) -> T {
    out: T
    if pop_at(cast(rawptr)array, typeid_of(T), index, cast(rawptr)&out) {
        return out
    } else {
        return T{}
    }
}