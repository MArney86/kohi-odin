package types

import vk "../../../libs/vulkan_lib"

when ODIN_DEBUG {
    vulkan_context :: struct {
        instance: vk.Instance,
        allocator: ^vk.AllocationCallbacks,
        debug_messenger: vk.DebugUtilsMessengerEXT,
    }
} else {
    vulkan_context :: struct {
        instance: vk.Instance,
        allocator: ^vk.AllocationCallbacks,
    }
}