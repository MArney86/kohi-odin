package types

import vk "vendor:vulkan/dynamic"

when ODIN_DEBUG {
    vulkan_context :: struct {
        instance: vk.Instance,
        allocator: ^vk.AllocationCallbacks,
        surface: vk.SurfaceKHR,
        debug_messenger: vk.DebugUtilsMessengerEXT,
        device: vulkan_device,

    }
} else {
    vulkan_context :: struct {
        instance: vk.Instance,
        allocator: ^vk.AllocationCallbacks,
        surface: vk.SurfaceKHR,
        device: vulkan_device,
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
}