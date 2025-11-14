package memory

import strings "core:strings"
import fmt "core:fmt"
import mem "core:mem"
import types "../../types"
// import platform "../platform" // Commented out to break circular dependency
import runtime "base:runtime"
import logger "../logger"

when ODIN_DEBUG {
    memory_stats :: struct {
        updated: b8,
        total_allocated: u64,
        tagged_allocations: [types.memory_tag.MEMORY_TAG_MAX_TAGS]u64,
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
        stats.updated = false
        return fmt.sbprintf(&output_str_builder, "%s:\t\t\t%M", "Total Allocated", stats.total_allocated)
    }
} else {
    memory_stats :: struct {
        total_allocated: u64,
        tagged_allocations: [types.memory_tag.MEMORY_TAG_MAX_TAGS]u64,
    }
}

stats := memory_stats{}

initialize :: proc() {
    zero_memory(&stats, size_of(stats));
}

shutdown :: proc() {
    //does nothing yet
}

New :: proc($T: typeid, tag: types.memory_tag) -> ^T {
    ptr, all_err := new(T)
    if all_err != runtime.Allocator_Error.None {
        logger.FATAL("KNew failed to allocate memory for type %v", typeid_of(T))
        return nil
    }
    added: u64 = u64(size_of(T))
    stats.total_allocated += added
    stats.tagged_allocations[tag] += added
    when ODIN_DEBUG {
        stats.updated = true
    }
    return cast(^T)ptr
}

Allocate :: proc(size: u64, tag: types.memory_tag) -> rawptr {
    if tag == types.memory_tag.MEMORY_TAG_UNKNOWN {
        logger.WARN("Kallocate called with MEMORY_TAG_UNKNOWN. Re-class this allocation.")
    }

    stats.total_allocated += size
    stats.tagged_allocations[cast(int)tag] += size
    when ODIN_DEBUG {
        stats.updated = true
    }

    block, _ := mem.alloc(cast(int)size)
    zero_memory(block, size)
    return block
}

Free :: proc(block: rawptr, size: u64, tag: types.memory_tag) {
    if tag == types.memory_tag.MEMORY_TAG_UNKNOWN {
        logger.WARN("Kfree called with MEMORY_TAG_UNKNOWN. Re-class this deallocation.")
    }

    stats.total_allocated -= size
    stats.tagged_allocations[cast(int)tag] -= size
    when ODIN_DEBUG {
        stats.updated = true
    }

    mem.free_with_size(block, cast(int)size)
}

zero_memory :: proc(block: rawptr, size: u64) -> rawptr {
    return mem.zero(block, cast(int)size)
}

copy_memory :: proc(dest: rawptr, src: rawptr, size: u64) -> rawptr {
    return mem.copy(dest, src, cast(int)size)
}

set_memory :: proc(dest: rawptr, value: i32, size: u64) -> rawptr {
    return mem.set(dest, cast(byte)value, cast(int)size)
}