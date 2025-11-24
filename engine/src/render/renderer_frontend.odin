package render

import types "../types"
import backend "./backend"
import memory "../core/memory"
import logger "../core/logger"

state: ^types.renderer_backend

initialize :: proc(application_name: string, plat_state: ^types.platform_state) -> bool {
    state = cast(^types.renderer_backend)memory.Allocate(cast(u64)size_of(types.renderer_backend), .MEMORY_TAG_RENDERER)

    //TODO: make this configurable
    created := backend.create(types.renderer_backend_type.RENDERER_BACKEND_TYPE_VULKAN, plat_state, state)
    
    if !created {
        logger.FATAL("Failed to create renderer backend.")
        return false
    }logger.DEBUG("Renderer Backend Created!")

    state.frame_number = 0
    if !state.initialize(state, application_name, plat_state) {
        logger.FATAL("Renderer backend failed to initialize. Shutting down.")
        return false
    }

    return true
}

shutdown :: proc() {
    backend.destroy(state)
    memory.Free(state, cast(u64)size_of(types.renderer_backend), .MEMORY_TAG_RENDERER)
}

begin_frame :: proc(delta_time: f32) -> bool {
    return state.begin_frame(state, delta_time)
}

end_frame :: proc(delta_time: f32) -> bool {
    result: bool = state.end_frame(state, delta_time)
    state.frame_number += 1
    return result
}

on_resized :: proc(width: u16, height: u16) {
    // For now, we will just use a dummy implementation
}

draw_frame :: proc(packet: ^types.render_packet) -> bool {
    if begin_frame(packet.delta_time) {
        result: bool = end_frame(packet.delta_time)

        if !result {
            logger.ERROR("renderer_end_frame failed. Application shutting down.")
            return false
        }
    }

    return true
}