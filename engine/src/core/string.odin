package core

import strings "core:strings"
import types "../types"

@(export)
Kstring_length :: proc(str: string) -> u64{
    return cast(u64)len(str)
}

@(export)
Kstring_duplicate :: proc(str: string) -> string {
    str_clone := strings.clone(str)
    stats_memory.total_allocated += Kstring_length(str_clone)
    stats_memory.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_STRING] += Kstring_length(str_clone)
    return str_clone
}