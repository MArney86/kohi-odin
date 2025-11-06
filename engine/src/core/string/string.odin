package engine_string

import strings "core:strings"
import types "../../types"
import mem "../memory"

@(export)
length :: proc(str: string) -> u64{
    return cast(u64)len(str)
}

@(export)
duplicate :: proc(str: string) -> string {
    str_clone := strings.clone(str)
    // Update memory stats
    size := length(str_clone)
    mem.stats.total_allocated += size
    mem.stats.tagged_allocations[cast(int)types.memory_tag.MEMORY_TAG_STRING] += size
    return str_clone
}