package types

import "core:image"
import vk "vendor:vulkan/dynamic"

find_memory_index_proc :: proc(u32, u32) -> i32

when ODIN_DEBUG {
    vulkan_context :: struct {
        framebuffer_width: u32,
        framebuffer_height: u32,
        instance: vk.Instance,
        allocator: ^vk.AllocationCallbacks,
        surface: vk.SurfaceKHR,
        debug_messenger: vk.DebugUtilsMessengerEXT,
        device: vulkan_device,
        swapchain: vulkan_swapchain,
        image_index: u32,
        current_frame: u32,
        recreating_swapchain: bool,
        find_memory_index: find_memory_index_proc,
    }
} else {
    vulkan_context :: struct {
        framebuffer_width: u32,
        framebuffer_height: u32,
        instance: vk.Instance,
        allocator: ^vk.AllocationCallbacks,
        surface: vk.SurfaceKHR,
        device: vulkan_device,
        swapchain: vulkan_swapchain,
        image_index: u32,
        current_frame: u32,
        recreating_swapchain: bool,
        find_memory_index: find_memory_index_proc,
    }
}

vulkan_swapchain_support_info :: struct {
    capabilities: vk.SurfaceCapabilitiesKHR,
    format_count: u32,
    formats: ^[dynamic]vk.SurfaceFormatKHR,
    present_mode_count: u32,
    present_modes: ^[dynamic]vk.PresentModeKHR,
}

vulkan_device :: struct {
    physical_device: vk.PhysicalDevice,
    logical_device: vk.Device,
    swapchain_support: vulkan_swapchain_support_info,
    graphics_queue_index: i32,
    present_queue_index: i32,
    transfer_queue_index: i32,

    properties: vk.PhysicalDeviceProperties,
    features: vk.PhysicalDeviceFeatures,
    memory: vk.PhysicalDeviceMemoryProperties,

    graphics_queue: vk.Queue,
    present_queue: vk.Queue,
    transfer_queue: vk.Queue,

    depth_format: vk.Format
}

vulkan_swapchain :: struct {
    image_format: vk.SurfaceFormatKHR,
    max_frames_in_flight: u8,
    handle: vk.SwapchainKHR,
    image_count: u32,
    images: [^]vk.Image,
    views: [^]vk.ImageView,
    depth_attachment: vulkan_image,
}

vulkan_image :: struct {
    handle: vk.Image,
    memory: vk.DeviceMemory,
    view: vk.ImageView,
    width: u32,
    height: u32,
}