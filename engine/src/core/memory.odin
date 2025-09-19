package core

import strings "core:strings"
import fmt "core:fmt"
import types "../types"

memory_stats :: struct {
    total_allocated: u64,
    tagged_allocations: [types.memory_tag.MEMORY_TAG_MAX_TAGS]u64,
}

@(private) stats := memory_stats{}

@(export)
initialize_memory :: proc() {
    platform_zero_memory(&stats, size_of(stats));
}

@(export)
shutdown_memory :: proc() {
    //does nothing yet
}

@(export)
Kallocate :: proc(size: u64, tag: types.memory_tag) -> rawptr {
    if tag == types.memory_tag.MEMORY_TAG_UNKNOWN {
        KWARN("Kallocate called with MEMORY_TAG_UNKNOWN. Re-class this allocation.")
    }

    stats.total_allocated += size
    stats.tagged_allocations[cast(int)tag] += size

    block: rawptr = platform_allocate(size, FALSE)
    platform_zero_memory(block, size)
    return block
}

@(export)
Kfree :: proc(block: rawptr, size: u64, tag: types.memory_tag) {
    if tag == types.memory_tag.MEMORY_TAG_UNKNOWN {
        KWARN("Kfree called with MEMORY_TAG_UNKNOWN. Re-class this deallocation.")
    }

    stats.total_allocated -= size
    stats.tagged_allocations[cast(int)tag] -= size

    platform_free(block, FALSE)
}

@(export)
Kzero_memory :: proc(block: rawptr, size: u64) -> rawptr {
    return platform_zero_memory(block, size)
}

@(export)
Kcopy_memory :: proc(dest: rawptr, src: rawptr, size: u64) -> rawptr {
    return platform_copy_memory(dest, src, size)
}

@(export)
Kset_memory :: proc(dest: rawptr, value: i32, size: u64) -> rawptr {
    return platform_set_memory(dest, value, size)
}

@(export)
get_memory_usage_str :: proc () -> string {
    output_str_builder: strings.Builder
    strings.builder_init(&output_str_builder, context.temp_allocator)
    _ = strings.write_string(&output_str_builder, "System memory use (tagged):\n")

    for i: int = 0; i < int(types.memory_tag.MEMORY_TAG_MAX_TAGS); i += 1 {
        if enum_val, ok:= fmt.enum_value_to_string(cast(types.memory_tag)i); ok {
            mem_val:= u64(stats.tagged_allocations[i])
            if len(enum_val) < 21 {
                _ = strings.write_string(&output_str_builder, fmt.tprintfln("\t %s: \t\t%M", enum_val, mem_val))
            } else {
                _ = strings.write_string(&output_str_builder, fmt.tprintfln("\t %s: \t%M", enum_val, mem_val))
            }
        }
    }
    return fmt.sbprintf(&output_str_builder, "%s:\t\t\t%M", "Total Allocated", stats.total_allocated)
}