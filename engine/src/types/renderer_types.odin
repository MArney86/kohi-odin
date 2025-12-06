package types
import vk "vendor:vulkan/dynamic"

renderer_backend_type :: enum{
    RENDERER_BACKEND_TYPE_VULKAN,
    RENDERER_BACKEND_TYPE_OPENGL,
    RENDERER_BACKEND_TYPE_DIRECTX,
}

renderer_initialize_func :: proc(^renderer_backend, string, ^platform_state) -> bool
renderer_shutdown_func :: proc(^renderer_backend)
renderer_resized_func :: proc(^renderer_backend, u16, u16)
renderer_begin_frame_func :: proc(^renderer_backend, f32) -> bool
renderer_end_frame_func :: proc(^renderer_backend, f32) -> bool


renderer_backend :: struct {
    plat_state: ^platform_state,
    frame_number: u64,
    initialize: renderer_initialize_func,
    shutdown: renderer_shutdown_func,
    resized: renderer_resized_func,
    begin_frame: renderer_begin_frame_func,
    end_frame: renderer_end_frame_func,
}

static_mesh_data :: struct {
    // for future use
}

render_packet :: struct {
    delta_time: f32,
}

