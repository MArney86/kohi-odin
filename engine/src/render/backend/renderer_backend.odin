package backend

import types "../../types"
import vulkan_backend "./vulkan"

create :: proc(type: types.renderer_backend_type, plat_state: ^types.platform_state, out_backend: ^types.renderer_backend) -> bool {
    out_backend.plat_state = plat_state

    if type == .RENDERER_BACKEND_TYPE_VULKAN {
        out_backend.initialize = vulkan_backend.initialize
        out_backend.shutdown = vulkan_backend.shutdown
        out_backend.resized = vulkan_backend.on_resized
        out_backend.begin_frame = vulkan_backend.begin_frame
        out_backend.end_frame = vulkan_backend.end_frame

        return true
    }

    return false
}

destroy :: proc(backend: ^types.renderer_backend) {
    // Call the backend's shutdown procedure before clearing function pointers
    if backend.shutdown != nil {
        backend.shutdown(backend)
    }
    
    backend.initialize = nil
    backend.shutdown = nil
    backend.resized = nil
    backend.begin_frame = nil
    backend.end_frame = nil
}

set_framebuffer_size :: proc(width: u32, height: u32) {
    vulkan_backend.set_framebuffer_size(width, height)
}